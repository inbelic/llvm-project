// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.0-pixel -finclude-default-header -fsyntax-only -verify=old %s
// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.1-pixel -finclude-default-header -fsyntax-only -verify=valid %s
// RUN: %clang_cc1 -triple spirv-pc-vulkan1.3-pixel -finclude-default-header -fsyntax-only -verify=valid %s
// valid-no-diagnostics

void main(uint v : SV_ViewID) {}
// old-error@-1 {{attribute 'SV_ViewID' requires shader model 6.1 or greater}}
