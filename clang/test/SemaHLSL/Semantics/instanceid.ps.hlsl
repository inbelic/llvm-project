// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.3-pixel -finclude-default-header -x hlsl -verify -o - %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-pixel -finclude-default-header -x hlsl -verify -o - %s

// SV_InstanceID is an arbitrary semantic on pixel shader inputs.
float4 main(nointerpolation int id : SV_InstanceID) : SV_Target {
  return (float4)id;
}

// expected-no-diagnostics
