// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.3-library -finclude-default-header -x hlsl -verify -o - %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-library -finclude-default-header -x hlsl -verify -o - %s

// SV_Coverage is only available as a pixel shader input or output.

[shader("vertex")]
float4 vs_input(uint c : SV_Coverage) : SV_Position {
// expected-error@-1 {{semantic 'SV_Coverage' is not supported in vertex shader inputs}}
  return 0;
}

[shader("vertex")]
uint vs_output(float4 p : POSITION) : SV_Coverage {
// expected-error@-1 {{semantic 'SV_Coverage' is not supported in vertex shader outputs}}
  return 0;
}

[shader("compute")]
[numthreads(1, 1, 1)]
void cs_input(uint c : SV_Coverage) {}
// expected-error@-1 {{semantic 'SV_Coverage' is not supported in compute shader inputs}}
