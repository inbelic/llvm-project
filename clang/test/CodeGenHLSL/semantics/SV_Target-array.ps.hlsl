// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.3-pixel -x hlsl -emit-llvm -finclude-default-header -disable-llvm-passes -o - %s | FileCheck %s --check-prefix=CHECK-DXIL
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-pixel -x hlsl -emit-llvm -finclude-default-header -disable-llvm-passes -o - %s | FileCheck %s --check-prefix=CHECK-SPIRV

struct Targets {
  float4 A : SV_Target0;
  float2 B[2] : SV_Target2;
  float C : SV_Target5;
};

[shader("pixel")]
Targets main() {
  Targets T;
  T.A = 1;
  T.B[0] = 2;
  T.B[1] = 3;
  T.C = 4;
  return T;
}

// Each render target is its own signature element, including each element of
// a target array. Stores use the element ID, always at row 0.
// CHECK-DXIL-LABEL: define void @main()
// CHECK-DXIL: call void @llvm.dx.store.output.v4f32(i32 0, i32 0, i8 0, <4 x float> %{{.*}})
// CHECK-DXIL: call void @llvm.dx.store.output.v2f32(i32 1, i32 0, i8 0, <2 x float> %{{.*}})
// CHECK-DXIL: call void @llvm.dx.store.output.v2f32(i32 2, i32 0, i8 0, <2 x float> %{{.*}})
// CHECK-DXIL: call void @llvm.dx.store.output.f32(i32 3, i32 0, i8 0, float %{{.*}})

// The render-target index is the semantic index and the packed row.
// CHECK-DXIL-DAG: !{i32 0, !"SV_Target", i32 9, i32 16, ![[#IDX0:]], i32 0, i32 1, i8 4, i32 0, i8 0, i8 0, i8 0, i32 0}
// CHECK-DXIL-DAG: !{i32 1, !"SV_Target", i32 9, i32 16, ![[#IDX2:]], i32 0, i32 1, i8 2, i32 2, i8 0, i8 0, i8 0, i32 0}
// CHECK-DXIL-DAG: !{i32 2, !"SV_Target", i32 9, i32 16, ![[#IDX3:]], i32 0, i32 1, i8 2, i32 3, i8 0, i8 0, i8 0, i32 0}
// CHECK-DXIL-DAG: !{i32 3, !"SV_Target", i32 9, i32 16, ![[#IDX5:]], i32 0, i32 1, i8 1, i32 5, i8 0, i8 0, i8 0, i32 0}
// CHECK-DXIL-DAG: ![[#IDX0]] = !{i32 0}
// CHECK-DXIL-DAG: ![[#IDX2]] = !{i32 2}
// CHECK-DXIL-DAG: ![[#IDX3]] = !{i32 3}
// CHECK-DXIL-DAG: ![[#IDX5]] = !{i32 5}

// SPIR-V render targets use the location of their render-target index. The
// array occupies locations 2 and 3.
// CHECK-SPIRV-DAG: @SV_Target0 = {{.*}} global <4 x float>, !spirv.Decorations ![[#LOC0:]]
// CHECK-SPIRV-DAG: @SV_Target2 = {{.*}} global [2 x <2 x float>], !spirv.Decorations ![[#LOC2:]]
// CHECK-SPIRV-DAG: @SV_Target5 = {{.*}} global float, !spirv.Decorations ![[#LOC5:]]
// CHECK-SPIRV-DAG: ![[#LOC0]] = !{![[#L0:]]}
// CHECK-SPIRV-DAG: ![[#L0]] = !{i32 30, i32 0}
// CHECK-SPIRV-DAG: ![[#LOC2]] = !{![[#L2:]]}
// CHECK-SPIRV-DAG: ![[#L2]] = !{i32 30, i32 2}
// CHECK-SPIRV-DAG: ![[#LOC5]] = !{![[#L5:]]}
// CHECK-SPIRV-DAG: ![[#L5]] = !{i32 30, i32 5}
