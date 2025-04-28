// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.0-library -ast-dump \
// RUN:  -disable-llvm-passes -o - %s | FileCheck %s

// This test ensures that the sample root signature is parsed without error and
// the Attr AST Node is created succesfully. If an invalid root signature was
// passed in then we would exit out of Sema before the Attr is created.

#define SampleRS \
  "DescriptorTable( " \
  "  CBV(b1), " \
  "  SRV(t1, numDescriptors = 8, " \
  "          flags = DESCRIPTORS_VOLATILE), " \
  "  UAV(u1, numDescriptors = 0, " \
  "          flags = DESCRIPTORS_VOLATILE) " \
  "), " \
  "DescriptorTable(Sampler(s0, numDescriptors = 4, space = 1))"

// CHECK: -HLSLRootSignatureDecl 0x{{.*}} {{.*}} implicit RootSig
// CHECK: -RootSignatureAttr 0x{{.*}} {{.*}} RootSig
[RootSignature(SampleRS)]
void main() {}
