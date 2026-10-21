// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-vertex -x hlsl -emit-llvm -finclude-default-header -fnative-half-type -fnative-int16-type -disable-llvm-passes -o - %s | FileCheck %s

// Vulkan integer built-ins are 32-bit scalars, so 16-bit SV_VertexID and
// SV_InstanceID declarations read the 32-bit built-ins and truncate them.
uint main(uint16_t Vertex : SV_VertexID, int16_t Instance : SV_InstanceID) : A {
  return Vertex + Instance;
}

// CHECK-DAG: @SV_VertexID = {{.*}} addrspace(7) externally_initialized constant i32,
// CHECK-DAG: @SV_InstanceID = {{.*}} addrspace(7) externally_initialized constant i32,
// CHECK-LABEL: define void @main()
// CHECK: %[[V:.*]] = load i32, ptr addrspace(7) @SV_VertexID
// CHECK: %[[V16:.*]] = trunc i32 %[[V]] to i16
// CHECK: %[[I:.*]] = load i32, ptr addrspace(7) @SV_InstanceID
// CHECK: %[[I16:.*]] = trunc i32 %[[I]] to i16
// CHECK: call spir_func i32 @_Z4maints(i16 %[[V16]], i16 %[[I16]])
