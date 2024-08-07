// RUN: mlir-translate -mlir-to-llvmir %s | FileCheck %s

#tbaa_root = #llvm.tbaa_root<id = "Example TBAA">
#tbaa_type_desc = #llvm.tbaa_type_desc<id = "scalar type", members = {<#tbaa_root, 0>}>
#tbaa_tag = #llvm.tbaa_tag<base_type = #tbaa_type_desc, access_type = #tbaa_type_desc, offset = 0>
#tbaa_struct = #llvm.tbaa_struct_tag<members = {<0, 4, #tbaa_tag>, <8, 4, #tbaa_tag>}>

llvm.func @memcpy_with_tbaa_struct(%arg0: !llvm.ptr) {
  %0 = llvm.mlir.constant(4 : i32) : i32
  "llvm.intr.memcpy"(%arg0, %arg0, %0) <{isVolatile = false, tbaa_struct = #tbaa_struct}> : (!llvm.ptr, !llvm.ptr, i32) -> ()
  llvm.return
}

// CHECK-DAG: ![[INFO:.*]] = !{i32 2, !"Debug Info Version", i32 3}
// CHECK-DAG: ![[TBAA_ROOT:.*]] = !{!"Example TBAA"}
// CHECK-DAG: ![[TBAA_TYPE_DESC:.*]] = !{!"scalar type", ![[TBAA_ROOT]], i64 0}
// CHECK-DAG: ![[TBAA_TAG:.*]] = !{![[TBAA_TYPE_DESC]], ![[TBAA_TYPE_DESC]], i64 0}
// CHECK-DAG: ![[TBAA_STRUCT:.*]] = !{i64 0, i64 4, ![[TBAA_TAG]], i64 8, i64 4, ![[TBAA_TAG]]}

// CHECK-DAG: define void @memcpy_with_tbaa_struct(ptr %0) {
// CHECK-DAG:   call void @llvm.memcpy.p0.p0.i32(ptr %0, ptr %0, i32 4, i1 false), !tbaa.struct ![[TBAA_STRUCT]]
// CHECK-DAG:   ret void
// CHECK-DAG: }
