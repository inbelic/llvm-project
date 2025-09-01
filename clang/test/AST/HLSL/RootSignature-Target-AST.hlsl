// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.0-rootsignature -ast-dump \
// RUN:  -hlsl-entry EntryRootSig -disable-llvm-passes -o - %s | FileCheck %s --check-prefixes=CHECK,CHECK-V1_1

// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.0-rootsignature -ast-dump \
// RUN:  -fdx-rootsignature-version=rootsig_1_0 \
// RUN:  -hlsl-entry EntryRootSig -disable-llvm-passes -o - %s | FileCheck %s --check-prefixes=CHECK,CHECK-V1_0

// CHECK: -HLSLRootSignatureDecl 0x{{.*}} {{.*}} implicit [[ENTRY_RS_DECL:__hlsl_rootsig_decl_\d*]]
// CHECK-V1_0-SAME: version: 1.0,
// CHECK-V1_1-SAME: version: 1.1,
// CHECK-SAME: RootElements{
// CHECK-SAME: RootCBV(b0,
// CHECK-SAME:   space = 0, visibility = All,
// CHECK-V1_0-SAME: flags = DataVolatile
// CHECK-V1_1-SAME: flags = DataStaticWhileSetAtExecute
// CHECK-SAME: )
// CHECK-SAME: }
#define EntryRootSig "CBV(b0)"
