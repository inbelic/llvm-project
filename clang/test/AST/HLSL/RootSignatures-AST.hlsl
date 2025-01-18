// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.0-library -ast-dump -disable-llvm-passes -o - 2>&1 %s | FileCheck %s

#define SampleRS \
  "DescriptorTable( " \
  "  CBV(b1), " \
  "  SRV(t1, numDescriptors = 8, " \
  "          flags = DESCRIPTORS_VOLATILE), " \
  "  UAV(u1, numDescriptors = 0, " \
  "          flags = DESCRIPTORS_VOLATILE) " \
  "), " \
  "DescriptorTable(Sampler(s0, numDescriptors = 4, space = 1))"

// CHECK: everything is fine
[RootSignature(SampleRS)]
void main() {}
