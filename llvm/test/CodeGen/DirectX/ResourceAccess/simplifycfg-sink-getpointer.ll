; RUN: opt -passes='simplifycfg<sink-common-insts>' -S %s \
; RUN:   | opt -S -dxil-resource-type -dxil-resource-access \
; RUN:     -mtriple=dxil-pc-shadermodel6.3-library | FileCheck %s

; SimplifyCFG's common-code sinking is free to sink the resource accesses out
; of their branches, selecting between resource handles:
;   %bufA.bufB = select i1 %cmp, target(...) %bufA, target(...) %bufB
; Ensure that dxil-resource-access legalizes this by switching on which
; resource is accessed.
;
; NOTE: The following IR corresponds to the (post-inlining) lowering of:
;
;   RWStructuredBuffer<float> bufA : register(u0);
;   RWStructuredBuffer<float> bufB : register(u1);
;   RWStructuredBuffer<float> output : register(u2);
;
;   cbuffer Constants : register(b0) {
;       uint condition;
;   };
;
;   [numthreads(64, 1, 1)]
;   void main(uint tid : SV_DispatchThreadID) {
;       if (condition == 0) {
;           output[tid] = bufA[tid];
;       } else {
;           output[tid] = bufB[tid];
;       }
;   }

; CHECK-LABEL: define void @main(
; CHECK:         %[[OUT:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
; CHECK:         %[[CMP:.*]] = icmp eq i32 %cond, 0
; CHECK-NEXT:    %[[SEL:.*]] = select i1 %[[CMP]], i32 1, i32 0
; CHECK-NEXT:    switch i32 %[[SEL]], label %[[CASEA:.*]] [
; CHECK-NEXT:      i32 0, label %[[CASEB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CASEB]]:
; CHECK-NEXT:    %[[HB:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
; CHECK-NEXT:    %[[LB:.*]] = call { float, i1 } @llvm.dx.resource.load.rawbuffer.f32.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %[[HB]], i32 %tid, i32 0)
; CHECK-NEXT:    %[[VB:.*]] = extractvalue { float, i1 } %[[LB]], 0
; CHECK-NEXT:    br label %[[END:.*]]
; CHECK:       [[CASEA]]:
; CHECK-NEXT:    %[[HA:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
; CHECK-NEXT:    %[[LA:.*]] = call { float, i1 } @llvm.dx.resource.load.rawbuffer.f32.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %[[HA]], i32 %tid, i32 0)
; CHECK-NEXT:    %[[VA:.*]] = extractvalue { float, i1 } %[[LA]], 0
; CHECK-NEXT:    br label %[[END]]
; CHECK:       [[END]]:
; CHECK-NEXT:    %[[V:.*]] = phi float [ %[[VB]], %[[CASEB]] ], [ %[[VA]], %[[CASEA]] ]
; CHECK-NEXT:    call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_f32_1_0t.f32(target("dx.RawBuffer", float, 1, 0) %[[OUT]], i32 %tid, i32 0, float %[[V]])
; CHECK-NEXT:    ret void

@condition = external hidden addrspace(2) global i32, align 4
@.str = private unnamed_addr constant [5 x i8] c"bufA\00", align 1
@.str.2 = private unnamed_addr constant [5 x i8] c"bufB\00", align 1
@.str.4 = private unnamed_addr constant [7 x i8] c"output\00", align 1

define void @main() local_unnamed_addr {
entry:
  %bufA = tail call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
  %bufB = tail call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
  %output = tail call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
  %tid = tail call i32 @llvm.dx.thread.id(i32 0)
  %cond = load i32, ptr addrspace(2) @condition, align 4
  %cmp = icmp eq i32 %cond, 0
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %pA = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t.i32(target("dx.RawBuffer", float, 1, 0) %bufA, i32 %tid)
  %vA = load float, ptr %pA, align 4
  %pO1 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t.i32(target("dx.RawBuffer", float, 1, 0) %output, i32 %tid)
  store float %vA, ptr %pO1, align 4
  br label %if.end

if.else:                                          ; preds = %entry
  %pB = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t.i32(target("dx.RawBuffer", float, 1, 0) %bufB, i32 %tid)
  %vB = load float, ptr %pB, align 4
  %pO2 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t.i32(target("dx.RawBuffer", float, 1, 0) %output, i32 %tid)
  store float %vB, ptr %pO2, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  ret void
}
