// RUN: mlir-opt %s | FileCheck %s

// Implement the concrete example given here:
//  https://llvm.org/docs/LangRef.html#tbaa-metadata

#tbaa_root = #llvm.tbaa_root<id = "Example TBAA">
#tbaa_type_desc = #llvm.tbaa_type_desc<id = "omnipotent char", members = {<#tbaa_root, 0>}>

#tbaa_int_desc = #llvm.tbaa_type_desc<id = "int", members = {<#tbaa_type_desc, 0>}>
#tbaa_float_desc = #llvm.tbaa_type_desc<id = "float", members = {<#tbaa_type_desc, 0>}>
#tbaa_double_desc = #llvm.tbaa_type_desc<id = "double", members = {<#tbaa_type_desc, 0>}>

#tbaa_inner_desc = #llvm.tbaa_type_desc<id = "inner", members = {<#tbaa_int_desc, 0>, <#tbaa_float_desc, 4>}>
#tbaa_outer_desc = #llvm.tbaa_type_desc<id = "outer", members = {<#tbaa_float_desc, 0>, <#tbaa_double_desc, 4>, <#tbaa_inner_desc, 12>}>

#tbaa_tag_f = #llvm.tbaa_tag<access_type = #tbaa_float_desc, base_type = #tbaa_outer_desc, offset = 0>
#tbaa_tag_inner_i = #llvm.tbaa_tag<access_type = #tbaa_int_desc, base_type = #tbaa_outer_desc, offset = 12>
#tbaa_tag_inner_f = #llvm.tbaa_tag<access_type = #tbaa_float_desc, base_type = #tbaa_outer_desc, offset = 16>

// CHECK-DAG: #[[ROOT:.*]] = #llvm.tbaa_root<id = "Example TBAA">
// CHECK-DAG: #[[TYPE_DESC:.*]] = #llvm.tbaa_type_desc<id = "omnipotent char", members = {<#[[ROOT]], 0>}>

// CHECK-DAG: #[[INT_DESC:.*]] = #llvm.tbaa_type_desc<id = "int", members = {<#[[TYPE_DESC]], 0>}>
// CHECK-DAG: #[[FLOAT_DESC:.*]] = #llvm.tbaa_type_desc<id = "float", members = {<#[[TYPE_DESC]], 0>}>
// CHECK-DAG: #[[DOUBLE_DESC:.*]] = #llvm.tbaa_type_desc<id = "double", members = {<#[[TYPE_DESC]], 0>}>

// CHECK-DAG: #[[INNER_DESC:.*]] = #llvm.tbaa_type_desc<id = "inner", members = {<#[[INT_DESC]], 0>, <#[[FLOAT_DESC]], 4>}>
// CHECK-DAG: #[[OUTER_DESC:.*]] = #llvm.tbaa_type_desc<id = "outer", members = {<#[[FLOAT_DESC]], 0>, <#[[DOUBLE_DESC]], 4>, <#[[INNER_DESC]], 12>}>

// CHECK-DAG: #[[F_TAG:.*]] = #llvm.tbaa_tag<base_type = #[[OUTER_DESC]], access_type = #[[FLOAT_DESC]], offset = 0>
// CHECK-DAG: #[[INNER_I_TAG:.*]] = #llvm.tbaa_tag<base_type = #[[OUTER_DESC]], access_type = #[[INT_DESC]], offset = 12>
// CHECK-DAG: #[[INNER_F_TAG:.*]] = #llvm.tbaa_tag<base_type = #[[OUTER_DESC]], access_type = #[[FLOAT_DESC]], offset = 16>

llvm.func @tbaa_store(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: !llvm.ptr) {
  %f0 = llvm.mlir.constant(0.0 : f32) : f32
  %i0 = llvm.mlir.constant(0 : i32) : i32
  llvm.store %f0, %arg0 {tbaa = [#tbaa_tag_f]} : f32, !llvm.ptr
  llvm.store %i0, %arg1 {tbaa = [#tbaa_tag_inner_i]} : i32, !llvm.ptr
  llvm.store %f0, %arg2 {tbaa = [#tbaa_tag_inner_f]} : f32, !llvm.ptr
  llvm.return
}

#tbaa_struct_outer = #llvm.tbaa_struct_tag<members={<0, 4, #tbaa_tag_f>, <12, 4, #tbaa_tag_inner_i>, <16, 4, #tbaa_tag_inner_f>}>

// CHECK: llvm.func @tbaa_memcpy(%[[PTR:.*]]: !llvm.ptr) {
// CHECK: %[[ZERO:.*]] = llvm.mlir.constant(42 : i32) : i32
// CHECK: "llvm.intr.memcpy"
// CHECK: "llvm.intr.memcpy"(%[[PTR]], %[[PTR]], %[[ZERO]]) <{isVolatile = true,
// CHECK-SAME: tbaa_struct = #llvm.tbaa_struct_tag<members = {<0, 4, #[[F_TAG]]>, <12, 4, #[[INNER_I_TAG]]>, <16, 4, #[[INNER_F_TAG]]>}>

llvm.func @tbaa_memcpy(%ptr: !llvm.ptr) {
  %0 = llvm.mlir.constant(42 : i32) : i32
  "llvm.intr.memcpy"(%ptr, %ptr, %0) <{isVolatile = true}> : (!llvm.ptr, !llvm.ptr, i32) -> ()
  "llvm.intr.memcpy"(%ptr, %ptr, %0) <{isVolatile = true, tbaa_struct = #tbaa_struct_outer}> : (!llvm.ptr, !llvm.ptr, i32) -> ()
  llvm.return
}
