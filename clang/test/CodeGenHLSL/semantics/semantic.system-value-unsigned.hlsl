// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.3-vertex -x hlsl -emit-llvm -finclude-default-header -disable-llvm-passes -o - %s | FileCheck %s

// Integer system values may be declared as int, but DXIL signatures use an
// unsigned component type (U32 = 5) for them. An arbitrary semantic keeps its
// signed type (I32 = 4), even with a system-value name.
struct Output {
  float4 Pos : SV_Position;
  int Instance : SV_InstanceID;
};

Output main(int Vertex : SV_VertexID, int Instance : SV_InstanceID) {
  Output O;
  O.Pos = 0;
  O.Instance = Vertex + Instance;
  return O;
}

// CHECK-DAG: !{i32 0, !"SV_VertexID", i32 5, i32 1, {{.*}}}
// CHECK-DAG: !{i32 1, !"SV_InstanceID", i32 5, i32 2, {{.*}}}
// CHECK-DAG: !{i32 1, !"SV_InstanceID", i32 4, i32 0, {{.*}}}
