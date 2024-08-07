; RUN: mlir-translate -import-llvm %s | FileCheck %s

!0 = !{!1, !1, i64 0}
!1 = !{!"scalar type", !2, i64 0}
!2 = !{}

!3 = !{i64 0, i64 4, !0, i64 8, i64 4, !0}

; CHECK: llvm.func @memcpy_with_tbaa_struct(
; CHECK-SAME: %[[ARG:.*]]: !llvm.ptr) {
; CHECK:     %[[C4:.*]] = llvm.mlir.constant(4 : i32) : i32
; CHECK: "llvm.intr.memcpy"(%[[ARG]], %[[ARG]], %[[C4]]) <{isVolatile = false,
; CHECK-SAME: tbaa_struct = #llvm.tbaa_struct_tag<members = {<0, 4, #tbaa_tag>, <8, 4, #tbaa_tag>}>}>
; CHECK-SAME: (!llvm.ptr, !llvm.ptr, i32) -> ()

define void @memcpy_with_tbaa_struct(ptr %arg1) {
  call void @llvm.memcpy.p0.p0.i32(ptr %arg1, ptr %arg1, i32 4, i1 false), !tbaa.struct !3
  ret void
}

declare void @llvm.memcpy.p0.p0.i32(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i32, i1 immarg)
