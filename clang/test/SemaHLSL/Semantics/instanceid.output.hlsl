// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.3-library -finclude-default-header -x hlsl -verify -o - %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-library -finclude-default-header -x hlsl -verify -o - %s

// SV_InstanceID is a system value only on vertex input. As a vertex output it
// is an arbitrary semantic, so any type is accepted.
[shader("vertex")]
float2 main(uint id : SV_InstanceID) : SV_InstanceID {
  return (float2)id;
}

// expected-no-diagnostics
