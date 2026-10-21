; RUN: opt -S -dxil-resource-access -mtriple=dxil--shadermodel6.3-library %s | FileCheck %s

; Regression test for llvm/llvm-project#224422. A select of resource pointers
; is legalized by switching on which resource is accessed, without pointer
; lowering encountering the select.

; CHECK-LABEL: define float @pointer_select(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %[[IDX:.*]] = select i1 %cond, i32 0, i32 1
; CHECK-NEXT:    %[[SEL:.*]] = select i1 %cond, i32 1, i32 0
; CHECK-NEXT:    switch i32 %[[SEL]], label %[[CASEA:.*]] [
; CHECK-NEXT:      i32 0, label %[[CASEB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CASEB]]:
; CHECK-NEXT:    %[[HB:.*]] = call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr @BufferB.str)
; CHECK-NEXT:    %[[LB:.*]] = call { float, i1 } @llvm.dx.resource.load.rawbuffer.f32.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %[[HB]], i32 %[[IDX]], i32 0)
; CHECK-NEXT:    %[[VB:.*]] = extractvalue { float, i1 } %[[LB]], 0
; CHECK-NEXT:    br label %[[END:.*]]
; CHECK:       [[CASEA]]:
; CHECK-NEXT:    %[[HA:.*]] = call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr @BufferA.str)
; CHECK-NEXT:    %[[LA:.*]] = call { float, i1 } @llvm.dx.resource.load.rawbuffer.f32.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %[[HA]], i32 %[[IDX]], i32 0)
; CHECK-NEXT:    %[[VA:.*]] = extractvalue { float, i1 } %[[LA]], 0
; CHECK-NEXT:    br label %[[END]]
; CHECK:       [[END]]:
; CHECK-NEXT:    %[[V:.*]] = phi float [ %[[VB]], %[[CASEB]] ], [ %[[VA]], %[[CASEA]] ]
; CHECK-NEXT:    ret float %[[V]]

@BufferA.str = internal unnamed_addr constant [8 x i8] c"BufferA\00"
@BufferB.str = internal unnamed_addr constant [8 x i8] c"BufferB\00"

define float @pointer_select(i1 %cond) {
entry:
  %handle0 = call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr @BufferA.str)
  %handle1 = call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr @BufferB.str)
  %ptr0 = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %handle0, i32 0)
  %ptr1 = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %handle1, i32 1)
  %ptr = select i1 %cond, ptr %ptr0, ptr %ptr1
  %value = load float, ptr %ptr, align 4
  ret float %value
}
