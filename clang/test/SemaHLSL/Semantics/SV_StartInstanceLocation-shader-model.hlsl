// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.7-vertex -finclude-default-header -fsyntax-only -verify=old %s
// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.8-vertex -finclude-default-header -fsyntax-only -verify=valid %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-vertex -finclude-default-header -fsyntax-only -verify=valid %s
// valid-no-diagnostics

void main(int v : SV_StartInstanceLocation) {}
// old-error@-1 {{attribute 'SV_StartInstanceLocation' requires shader model 6.8 or greater}}
