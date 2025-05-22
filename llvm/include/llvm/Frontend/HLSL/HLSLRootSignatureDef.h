//===- HLSLRootSignatureDef.h - HLSL Root Signature definitions -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file This file contains common enums for HLSL Root Signatures.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_FRONTEND_HLSL_HLSLROOTSIGNATUREDEF_H
#define LLVM_FRONTEND_HLSL_HLSLROOTSIGNATUREDEF_H

namespace llvm {
namespace hlsl {
namespace rootsig {

/// Enumeration values for available Root Signature version
enum class RootSignatureVersion : uint8_t {
  rootsig_1_0 = 1,
  rootsig_1_1 = 2,
};

} // namespace rootsig
} // namespace hlsl
} // namespace llvm

#endif // LLVM_FRONTEND_HLSL_HLSLROOTSIGNATUREDEF_H
