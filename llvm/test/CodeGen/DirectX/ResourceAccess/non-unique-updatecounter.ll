; RUN: opt -S -dxil-resource-access -mtriple=dxil--shadermodel6.3-library %s | FileCheck %s

; Test that an updatecounter on a select of resource handles is legalized by
; switching on which resource is accessed.

; CHECK-LABEL: define i32 @updatecounter_select(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %[[SEL:.*]] = select i1 %cond, i32 1, i32 0
; CHECK-NEXT:    switch i32 %[[SEL]], label %[[CASE0:.*]] [
; CHECK-NEXT:      i32 0, label %[[CASE1:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[CASE1]]:
; CHECK-NEXT:    %[[H1:.*]] = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
; CHECK-NEXT:    %[[C1:.*]] = call i32 @llvm.dx.resource.updatecounter.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %[[H1]], i8 1)
; CHECK-NEXT:    br label %[[END:.*]]
; CHECK:       [[CASE0]]:
; CHECK-NEXT:    %[[H0:.*]] = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
; CHECK-NEXT:    %[[C0:.*]] = call i32 @llvm.dx.resource.updatecounter.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %[[H0]], i8 1)
; CHECK-NEXT:    br label %[[END]]
; CHECK:       [[END]]:
; CHECK-NEXT:    %[[C:.*]] = phi i32 [ %[[C1]], %[[CASE1]] ], [ %[[C0]], %[[CASE0]] ]
; CHECK-NEXT:    ret i32 %[[C]]

@.str.2 = internal unnamed_addr constant [5 x i8] c"Out0\00", align 1
@.str.4 = internal unnamed_addr constant [5 x i8] c"Out1\00", align 1

define i32 @updatecounter_select(i1 %cond) {
entry:
  %handle0 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
  %handle1 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
  %handle = select i1 %cond, target("dx.RawBuffer", i32, 1, 0) %handle0, target("dx.RawBuffer", i32, 1, 0) %handle1
  %count = call i32 @llvm.dx.resource.updatecounter.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %handle, i8 1)
  ret i32 %count
}
