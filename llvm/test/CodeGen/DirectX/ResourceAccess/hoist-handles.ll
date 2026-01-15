; RUN: opt -S -dxil-resource-type -dxil-resource-access  \
; RUN:  -mtriple=dxil-pc-shadermodel6.3-library %s | FileCheck %s

@.str = internal unnamed_addr constant [2 x i8] c"a\00", align 1

; CHECK-LABEL: hoist_simple_load(
; CHECK-SAME:   i1 %[[COND:.*]])
define half @hoist_simple_load(i1 %cond) local_unnamed_addr {
; CHECK:      entry:
; CHECK-NEXT:   br i1 %[[COND]], label %if.else.i, label %if.then.i

; CHECK:      if.then.i:
; CHECK-NEXT:   %[[HANDLE0:.*]] = tail call target("dx.RawBuffer", half, 1, 0) @llvm.dx.resource.handlefromimplicitbinding.tdx.RawBuffer_f16_1_0t(i32 1, i32 0, i32 1, i32 0, ptr nonnull @.str)
; CHECK-NEXT:   %[[LOAD0:.*]] = call { half, i1 } @llvm.dx.resource.load.rawbuffer.f16.tdx.RawBuffer_f16_1_0t(target("dx.RawBuffer", half, 1, 0) %[[HANDLE0]], i32 0, i32 0)
; CHECK-NEXT:   %[[X0:.*]] = extractvalue { half, i1 } %0, 0
; CHECK-NEXT:   br label %main.exit

; CHECK:      if.else.i:
; CHECK-NEXT:   %[[HANDLE1:.*]] = tail call target("dx.RawBuffer", half, 1, 0) @llvm.dx.resource.handlefromimplicitbinding.tdx.RawBuffer_f16_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
; CHECK-NEXT:   %[[LOAD1:.*]] = call { half, i1 } @llvm.dx.resource.load.rawbuffer.f16.tdx.RawBuffer_f16_1_0t(target("dx.RawBuffer", half, 1, 0) %[[HANDLE1]], i32 0, i32 0)
; CHECK-NEXT:   %[[X1:.*]] = extractvalue { half, i1 } %[[LOAD1]], 0
; CHECK-NEXT:   br label %main.exit

; CHECK:      main.exit:
; CHECK-NEXT:   %[[X:.*]] = phi half [ %[[X0]], %if.then.i ], [ %[[X1]], %if.else.i ]
; CHECK-NEXT:   ret half %[[X]]
entry:
  br i1 %cond, label %if.else.i, label %if.then.i

if.then.i:
  %handle0 = tail call target("dx.RawBuffer", half, 1, 0) @llvm.dx.resource.handlefromimplicitbinding.tdx.RawBuffer_f16_1_0t(i32 1, i32 0, i32 1, i32 0, ptr nonnull @.str)
  %ptr0 = tail call noundef nonnull align 2 dereferenceable(2) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f16_1_0t(target("dx.RawBuffer", half, 1, 0) %handle0, i32 0)
  br label %main.exit

if.else.i:
  %handle1 = tail call target("dx.RawBuffer", half, 1, 0) @llvm.dx.resource.handlefromimplicitbinding.tdx.RawBuffer_f16_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
  %ptr1 = tail call noundef nonnull align 2 dereferenceable(2) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_f16_1_0t(target("dx.RawBuffer", half, 1, 0) %handle1, i32 0)
  br label %main.exit

main.exit:
  %.sink1 = phi ptr [ %ptr0, %if.then.i ], [ %ptr1, %if.else.i ]
  %loadSink = load half, ptr %.sink1, align 2
  ret half %loadSink
}
