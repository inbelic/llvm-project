; RUN: opt -S -dxil-resource-access -mtriple=dxil--shadermodel6.3-library %s | FileCheck %s

; Test that a resource access that may map to one of several global resources
; is legalized by switching on which resource is accessed, with one access per
; global resource.

; CHECK-LABEL: define void @main(
; CHECK-NOT:    select i1 %loadedv.i, target(
; CHECK:        %[[SEL:.*]] = select i1 %loadedv.i, i32 1, i32 0
; CHECK:        %[[VAL:.*]] = extractvalue { i32, i1 }
; CHECK:        switch i32 %[[SEL]], label %[[CASE1:.*]] [
; CHECK-NEXT:     i32 0, label %[[CASE0:.*]]
; CHECK-NEXT:   ]
; CHECK:      [[CASE0]]:
; CHECK-NEXT:   %[[H0:.*]] = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
; CHECK-NEXT:   call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %[[H0]], i32 %{{.*}}, i32 0, i32 %[[VAL]])
; CHECK-NEXT:   br label %[[END:.*]]
; CHECK:      [[CASE1]]:
; CHECK-NEXT:   %[[H1:.*]] = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
; CHECK-NEXT:   call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %[[H1]], i32 %{{.*}}, i32 0, i32 %[[VAL]])
; CHECK-NEXT:   br label %[[END]]
; CHECK:      [[END]]:
; CHECK-NEXT:   ret void

%__cblayout_c = type <{ i32 }>

@.str = internal unnamed_addr constant [3 x i8] c"In\00", align 1
@.str.2 = internal unnamed_addr constant [5 x i8] c"Out0\00", align 1
@.str.4 = internal unnamed_addr constant [5 x i8] c"Out1\00", align 1
@c.cb = local_unnamed_addr global target("dx.CBuffer", %__cblayout_c) poison
@c.str = internal unnamed_addr constant [2 x i8] c"c\00", align 1

define void @main() local_unnamed_addr {
entry:
  %0 = tail call target("dx.TypedBuffer", i32, 1, 0, 1) @llvm.dx.resource.handlefrombinding.tdx.TypedBuffer_i32_1_0_1t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
  %1 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
  %2 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
  %c.cb_h.i.i = tail call target("dx.CBuffer", %__cblayout_c) @llvm.dx.resource.handlefromimplicitbinding.tdx.CBuffer_s___cblayout_cst(i32 4, i32 0, i32 1, i32 0, ptr nonnull @c.str)
  store target("dx.CBuffer", %__cblayout_c) %c.cb_h.i.i, ptr @c.cb, align 4
  %3 = tail call i32 @llvm.dx.flattened.thread.id.in.group()
  %c.cb = load target("dx.CBuffer", %__cblayout_c), ptr @c.cb, align 4
  %4 = call ptr addrspace(2) @llvm.dx.resource.getpointer.p2.tdx.CBuffer_s___cblayout_cst(target("dx.CBuffer", %__cblayout_c) %c.cb, i32 0)
  %5 = load i32, ptr addrspace(2) %4, align 4
  %loadedv.i = trunc nuw i32 %5 to i1
  %spec.select = select i1 %loadedv.i, target("dx.RawBuffer", i32, 1, 0) %2, target("dx.RawBuffer", i32, 1, 0) %1
  %6 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.TypedBuffer_i32_1_0_1t(target("dx.TypedBuffer", i32, 1, 0, 1) %0, i32 %3)
  %7 = load i32, ptr %6, align 4
  %8 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %spec.select, i32 %3)
  store i32 %7, ptr %8, align 4
  ret void
}
