// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.2-library -fnative-half-type -fnative-int16-type -finclude-default-header -fsyntax-only -verify %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-library -fnative-half-type -fnative-int16-type -finclude-default-header -fsyntax-only -verify %s

// Type constraints from the semantics overview for vertex and pixel shader
// system values.

// SV_VertexID and SV_InstanceID: a scalar up to 32-bit int or uint.
[shader("vertex")]
void vertex_id(int a : SV_VertexID, int16_t b : SV_InstanceID) {}
[shader("vertex")]
void vertex_id_vector(uint1 id : SV_VertexID) {}
// expected-error@-1 {{semantic 'SV_VertexID' must be a scalar of 16 or 32 bit integer type (was 'uint1' (aka 'vector<uint, 1>'))}}
[shader("vertex")]
void instance_id_array(uint id[1] : SV_InstanceID) {}
// expected-error@-1 {{semantic 'SV_InstanceID' must be a scalar of 16 or 32 bit integer type (was 'uint[1]'}}

// SV_Position: a vector of 4 components of up to 32-bit float.
[shader("pixel")]
void position(half4 p : SV_Position) {}
[shader("pixel")]
void position_vector2(float2 p : SV_Position) {}
// expected-error@-1 {{semantic 'SV_Position' must be a vector of 4 components of 16 or 32 bit floating-point type (was 'float2' (aka 'vector<float, 2>'))}}
[shader("vertex")]
float position_scalar() : SV_Position { return 0; }
// expected-error@-1 {{semantic 'SV_Position' must be a vector of 4 components of 16 or 32 bit floating-point type (was 'float')}}

// Vertex inputs with system-value names are arbitrary semantics.
[shader("vertex")]
void position_input(float2 p : SV_Position) {}
