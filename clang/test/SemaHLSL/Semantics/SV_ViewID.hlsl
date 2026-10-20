// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.2-library -fnative-half-type -fnative-int16-type -finclude-default-header -fsyntax-only -verify %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-library -fnative-half-type -fnative-int16-type -finclude-default-header -fsyntax-only -verify %s

[shader("vertex")]
void vertex(uint v : SV_ViewID) {}
[shader("pixel")]
void pixel(int v : sv_viewid0) {}
[shader("pixel")]
void flat(nointerpolation uint v : SV_ViewID) {}

struct Input {
  float4 p : SV_Position;
  uint v : SV_ViewID;
};
[shader("pixel")]
void valid_struct(Input i) {}

[shader("pixel")]
void bad_float(float v : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' must be a scalar of 32 bit integer type (was 'float')}}
[shader("pixel")]
void bad_bool(bool v : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' must be a scalar of 32 bit integer type (was 'bool')}}
[shader("pixel")]
void bad_uint16(uint16_t v : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' must be a scalar of 32 bit integer type (was 'uint16_t' (aka 'unsigned short'))}}
[shader("vertex")]
void bad_vector(uint2 v : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' must be a scalar of 32 bit integer type (was 'uint2' (aka 'vector<uint, 2>'))}}
[shader("vertex")]
void bad_array(uint v[1] : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' must be a scalar of 32 bit integer type (was 'uint[1]'}}

[shader("vertex")]
void bad_index(uint v : SV_ViewID1) {}
// expected-error@-1 {{semantic 'SV_ViewID' does not allow indexing}}

[shader("pixel")]
void same_index(uint v : SV_ViewID, // expected-note {{previous use is here}}
                uint w : SV_ViewID0) {} // expected-note {{'w' declared here}}
// expected-error@-1 {{semantic index overlap SV_ViewID0}}

// Integer inputs can only use nointerpolation.
[shader("pixel")]
void bad_interpolation(linear uint v : SV_ViewID) {}
// expected-error@-1 {{interpolation modifiers other than 'nointerpolation' cannot be used with type 'uint' (aka 'unsigned int')}}

[shader("vertex")]
uint vertex_output() : SV_ViewID { return 0; }
// expected-error@-1 {{semantic 'SV_ViewID' is not supported in vertex shader outputs}}
[shader("pixel")]
uint pixel_output() : SV_ViewID { return 0; }
// expected-error@-1 {{semantic 'SV_ViewID' is not supported in pixel shader outputs}}

[shader("compute")][numthreads(1, 1, 1)]
void compute(uint v : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' is not supported in compute shader inputs}}
[shader("amplification")][numthreads(1, 1, 1)]
void amplification(uint v : SV_ViewID) {}
// expected-error@-1 {{semantic 'SV_ViewID' is not supported in amplification shader inputs}}
