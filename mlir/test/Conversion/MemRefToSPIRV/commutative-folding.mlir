// RUN: mlir-opt -split-input-file -convert-memref-to-spirv="bool-num-bits=8" -cse %s | FileCheck %s

module attributes {
  spirv.target_env = #spirv.target_env<
    #spirv.vce<v1.0, [Shader, Int64], [SPV_KHR_storage_buffer_storage_class]>, #spirv.resource_limits<>>
} {

func.func @load_i16(%arg0: memref<10xi16, #spirv.storage_class<StorageBuffer>>, %index : index) -> i16 {
  // CHECK: %[[ARG1_CAST:.+]] = builtin.unrealized_conversion_cast %[[ARG1]] : index to i32
  // CHECK: %[[ZERO:.+]] = spirv.Constant 0 : i32
  // CHECK: %[[TWO:.+]] = spirv.Constant 2 : i32
  // CHECK: %[[QUOTIENT:.+]] = spirv.SDiv %[[ARG1_CAST]], %[[TWO]] : i32
  // CHECK: %[[PTR:.+]] = spirv.AccessChain %{{.+}}[%[[ZERO]], %[[QUOTIENT]]]
  // CHECK: %[[LOAD:.+]] = spirv.Load  "StorageBuffer" %[[PTR]]
  // CHECK: %[[SIXTEEN:.+]] = spirv.Constant 16 : i32
  // CHECK: %[[IDX:.+]] = spirv.UMod %[[ARG1_CAST]], %[[TWO]] : i32
  // CHECK: %[[BITS:.+]] = spirv.IMul %[[IDX]], %[[SIXTEEN]] : i32
  // CHECK: %[[VALUE:.+]] = spirv.ShiftRightArithmetic %[[LOAD]], %[[BITS]] : i32, i32
  // CHECK: %[[MASK:.+]] = spirv.Constant 65535 : i32
  // CHECK: %[[T1:.+]] = spirv.BitwiseAnd %[[VALUE]], %[[MASK]] : i32
  // CHECK: %[[T3:.+]] = spirv.ShiftLeftLogical %[[T1]], %[[SIXTEEN]] : i32, i32
  // CHECK: %[[SR:.+]] = spirv.ShiftRightArithmetic %[[T3]], %[[SIXTEEN]] : i32, i32
  // CHECK: builtin.unrealized_conversion_cast %[[SR]]
  %0 = memref.load %arg0[%index] : memref<10xi16, #spirv.storage_class<StorageBuffer>>
  return %0: i16
}

}
