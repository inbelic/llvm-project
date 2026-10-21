; RUN: opt -S -dxil-resource-type -dxil-resource-access -mtriple=dxil-pc-shadermodel6.6-compute %s | FileCheck %s

; Test that a resource access which may map to one of several global resources
; is legalized by switching on which resource is accessed, regardless of where
; optimizations have placed the access relative to the selection of resource.

@A.str = private unnamed_addr constant [2 x i8] c"A\00", align 1
@B.str = private unnamed_addr constant [2 x i8] c"B\00", align 1
@C.str = private unnamed_addr constant [2 x i8] c"C\00", align 1

; The load is sunk past the merge block of the phi of resource pointers, so it
; can't be placed into the phi's predecessors without being speculated.
; CHECK-LABEL: define float @sunk_past_merge(
; CHECK:       merge:
; CHECK-NEXT:    %[[SEL:.*]] = phi i32 [ 1, %if.a ], [ 0, %if.b ]
; CHECK-NEXT:    br i1 %c1, label %use, label %exit
; CHECK:       use:
; CHECK-NEXT:    switch i32 %[[SEL]], label %[[CASEA:.*]] [
; CHECK-NEXT:      i32 0, label %[[CASEB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CASEB]]:
; CHECK-NEXT:    %[[HB:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
; CHECK-NEXT:    %[[LB:.*]] = call { float, i1 } @llvm.dx.resource.load.rawbuffer.f32.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %[[HB]], i32 %tid, i32 0)
; CHECK-NEXT:    %[[VB:.*]] = extractvalue { float, i1 } %[[LB]], 0
; CHECK-NEXT:    br label %[[END:.*]]
; CHECK:       [[CASEA]]:
; CHECK-NEXT:    %[[HA:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
; CHECK-NEXT:    %[[LA:.*]] = call { float, i1 } @llvm.dx.resource.load.rawbuffer.f32.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %[[HA]], i32 %tid, i32 0)
; CHECK-NEXT:    %[[VA:.*]] = extractvalue { float, i1 } %[[LA]], 0
; CHECK-NEXT:    br label %[[END]]
; CHECK:       [[END]]:
; CHECK-NEXT:    %[[V:.*]] = phi float [ %[[VB]], %[[CASEB]] ], [ %[[VA]], %[[CASEA]] ]
; CHECK-NEXT:    br label %exit
; CHECK:       exit:
; CHECK-NEXT:    %r = phi float [ %[[V]], %[[END]] ], [ 0.000000e+00, %merge ]
define float @sunk_past_merge(i32 %tid, i1 %c0, i1 %c1) {
entry:
  %a = tail call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
  %b = tail call target("dx.RawBuffer", float, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_f32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
  br i1 %c0, label %if.a, label %if.b

if.a:
  %pa = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %a, i32 %tid)
  br label %merge

if.b:
  %pb = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f32_1_0t(target("dx.RawBuffer", float, 1, 0) %b, i32 %tid)
  br label %merge

merge:
  %ptr = phi ptr [ %pa, %if.a ], [ %pb, %if.b ]
  br i1 %c1, label %use, label %exit

use:
  %v = load float, ptr %ptr, align 4
  br label %exit

exit:
  %r = phi float [ %v, %use ], [ 0.0, %merge ]
  ret float %r
}

; A GEP between the phi of resource pointers and the access is re-applied in
; each case, while a GEP above the phi is folded into the propagated offset.
; CHECK-LABEL: define void @gep_chain(
; CHECK:       merge:
; CHECK-NEXT:    %[[SEL:.*]] = phi i32 [ 1, %if.a ], [ 0, %if.b ]
; CHECK-NEXT:    %[[OFF:.*]] = phi i32 [ 8, %if.a ], [ 0, %if.b ]
; CHECK-NEXT:    switch i32 %[[SEL]], label %[[CASEA:.*]] [
; CHECK-NEXT:      i32 0, label %[[CASEB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CASEB]]:
; CHECK-NEXT:    %[[HB:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_v4f64_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
; CHECK-NEXT:    %[[MULB:.*]] = mul i32 %idx, 8
; CHECK-NEXT:    %[[OFFB:.*]] = add i32 %[[MULB]], %[[OFF]]
; CHECK-NEXT:    call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_v4f64_1_0t.f64(target("dx.RawBuffer", <4 x double>, 1, 0) %[[HB]], i32 %tid, i32 %[[OFFB]], double %val)
; CHECK:       [[CASEA]]:
; CHECK-NEXT:    %[[HA:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_v4f64_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
; CHECK-NEXT:    %[[MULA:.*]] = mul i32 %idx, 8
; CHECK-NEXT:    %[[OFFA:.*]] = add i32 %[[MULA]], %[[OFF]]
; CHECK-NEXT:    call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_v4f64_1_0t.f64(target("dx.RawBuffer", <4 x double>, 1, 0) %[[HA]], i32 %tid, i32 %[[OFFA]], double %val)
define void @gep_chain(i32 %tid, i32 %idx, i1 %c, double %val) {
entry:
  %a = tail call target("dx.RawBuffer", <4 x double>, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_v4f64_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
  %b = tail call target("dx.RawBuffer", <4 x double>, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_v4f64_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
  br i1 %c, label %if.a, label %if.b

if.a:
  %pa = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_v4f64_1_0t(target("dx.RawBuffer", <4 x double>, 1, 0) %a, i32 %tid)
  %pa.1 = getelementptr inbounds i8, ptr %pa, i32 8
  br label %merge

if.b:
  %pb = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_v4f64_1_0t(target("dx.RawBuffer", <4 x double>, 1, 0) %b, i32 %tid)
  br label %merge

merge:
  %ptr = phi ptr [ %pa.1, %if.a ], [ %pb, %if.b ]
  %gep = getelementptr double, ptr %ptr, i32 %idx
  store double %val, ptr %gep, align 8
  ret void
}

; Three different global resources, of different resource kinds, are selected
; between with a switch of two cases and a default.
; CHECK-LABEL: define i32 @three_resources(
; CHECK:       merge:
; CHECK-NEXT:    %[[IDX:.*]] = phi i32 [ %tid, %case.a ], [ %tid, %case.b ], [ 0, %case.c ]
; CHECK-NEXT:    %[[SEL:.*]] = phi i32 [ 2, %case.a ], [ 1, %case.b ], [ 0, %case.c ]
; CHECK-NEXT:    switch i32 %[[SEL]], label %[[CASEA:.*]] [
; CHECK-NEXT:      i32 0, label %[[CASEC:.*]]
; CHECK-NEXT:      i32 1, label %[[CASEB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CASEC]]:
; CHECK-NEXT:    %[[HC:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @C.str)
; CHECK-NEXT:    %[[LC:.*]] = call { i32, i1 } @llvm.dx.resource.load.rawbuffer.i32.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %[[HC]], i32 %[[IDX]], i32 0)
; CHECK-NEXT:    %[[VC:.*]] = extractvalue { i32, i1 } %[[LC]], 0
; CHECK:       [[CASEB]]:
; CHECK-NEXT:    %[[HB:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.TypedBuffer_i32_1_0_1t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
; CHECK-NEXT:    %[[LB:.*]] = call { i32, i1 } @llvm.dx.resource.load.typedbuffer.i32.tdx.TypedBuffer_i32_1_0_1t(target("dx.TypedBuffer", i32, 1, 0, 1) %[[HB]], i32 %[[IDX]])
; CHECK-NEXT:    %[[VB:.*]] = extractvalue { i32, i1 } %[[LB]], 0
; CHECK:       [[CASEA]]:
; CHECK-NEXT:    %[[HA:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
; CHECK-NEXT:    %[[LA:.*]] = call { i32, i1 } @llvm.dx.resource.load.rawbuffer.i32.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %[[HA]], i32 %[[IDX]], i32 0)
; CHECK-NEXT:    %[[VA:.*]] = extractvalue { i32, i1 } %[[LA]], 0
; CHECK:         %[[V:.*]] = phi i32 [ %[[VC]], %[[CASEC]] ], [ %[[VB]], %[[CASEB]] ], [ %[[VA]], %[[CASEA]] ]
; CHECK-NEXT:    ret i32 %[[V]]
define i32 @three_resources(i32 %tid, i32 %sel) {
entry:
  %a = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
  %b = tail call target("dx.TypedBuffer", i32, 1, 0, 1) @llvm.dx.resource.handlefrombinding.tdx.TypedBuffer_i32_1_0_1t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
  %c = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @C.str)
  switch i32 %sel, label %case.c [
    i32 0, label %case.a
    i32 1, label %case.b
  ]

case.a:
  %pa = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %a, i32 %tid)
  br label %merge

case.b:
  %pb = call ptr @llvm.dx.resource.getpointer.p0.tdx.TypedBuffer_i32_1_0_1t(target("dx.TypedBuffer", i32, 1, 0, 1) %b, i32 %tid)
  br label %merge

case.c:
  %pc = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %c, i32 0)
  br label %merge

merge:
  %ptr = phi ptr [ %pa, %case.a ], [ %pb, %case.b ], [ %pc, %case.c ]
  %v = load i32, ptr %ptr, align 4
  ret i32 %v
}

; Value returning atomics are merged with a phi of the per-resource results.
; CHECK-LABEL: define i32 @atomics(
; CHECK:         %[[SEL0:.*]] = select i1 %c, i32 1, i32 0
; CHECK:         switch i32 %[[SEL0]], label %[[RMWA:.*]] [
; CHECK-NEXT:      i32 0, label %[[RMWB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[RMWB]]:
; CHECK:         %[[OLDB:.*]] = call i32 @llvm.dx.resource.atomic.binop.i32.tdx.RawBuffer_i32_1_0t(
; CHECK:       [[RMWA]]:
; CHECK:         %[[OLDA:.*]] = call i32 @llvm.dx.resource.atomic.binop.i32.tdx.RawBuffer_i32_1_0t(
; CHECK:         %[[OLD:.*]] = phi i32 [ %[[OLDB]], %[[RMWB]] ], [ %[[OLDA]], %[[RMWA]] ]
; CHECK-NEXT:    switch i32 %{{.*}}, label %[[CXA:.*]] [
; CHECK-NEXT:      i32 0, label %[[CXB:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CXB]]:
; CHECK:         %[[RESB:.*]] = call i32 @llvm.dx.resource.atomic.compare.exchange.i32.tdx.RawBuffer_i32_1_0t({{.*}}, i32 %[[OLD]], i32 %val)
; CHECK:       [[CXA]]:
; CHECK:         %[[RESA:.*]] = call i32 @llvm.dx.resource.atomic.compare.exchange.i32.tdx.RawBuffer_i32_1_0t({{.*}}, i32 %[[OLD]], i32 %val)
; CHECK:         %[[RES:.*]] = phi i32 [ %[[RESB]], %[[CXB]] ], [ %[[RESA]], %[[CXA]] ]
; CHECK-NEXT:    ret i32 %[[RES]]
define i32 @atomics(i32 %tid, i1 %c, i32 %val) {
entry:
  %a = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @A.str)
  %b = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @B.str)
  %h = select i1 %c, target("dx.RawBuffer", i32, 1, 0) %a, target("dx.RawBuffer", i32, 1, 0) %b
  %ptr = call ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %h, i32 %tid)
  %old = atomicrmw add ptr %ptr, i32 %val monotonic
  %pair = cmpxchg ptr %ptr, i32 %old, i32 %val monotonic monotonic
  %res = extractvalue { i32, i1 } %pair, 0
  ret i32 %res
}
