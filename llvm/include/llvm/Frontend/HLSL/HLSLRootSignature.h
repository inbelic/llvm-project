//===- HLSLRootSignature.h - HLSL Root Signature helper objects -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file This file contains helper objects for working with HLSL Root
/// Signatures.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_FRONTEND_HLSL_HLSLROOTSIGNATURE_H
#define LLVM_FRONTEND_HLSL_HLSLROOTSIGNATURE_H

#include "llvm/Support/DXILABI.h"
#include <variant>

namespace llvm {
namespace hlsl {
namespace root_signature {

// Definition of the various enumerations and flags

enum class ShaderVisibility {
  All = 0,
  Vertex = 1,
  Hull = 2,
  Domain = 3,
  Geometry = 4,
  Pixel = 5,
  Amplification = 6,
  Mesh = 7,
};

// Models the end of a descriptor table and stores its visibility
struct DescriptorTable {
  ShaderVisibility Visibility = ShaderVisibility::All;
  uint32_t NumClauses = 0; // The number of clauses in the table
};

// Models DTClause : CBV | SRV | UAV | Sampler, by collecting like parameters
using ClauseType = llvm::dxil::ResourceClass;
struct DescriptorTableClause {
  ClauseType Type;
};

// Models RootElement : DescriptorTable
using RootElement = std::variant<DescriptorTable, DescriptorTableClause>;

// Models a reference to all non-register parameter types that any RootElement may have
using ParamType = std::variant<ShaderVisibility *>;

} // namespace root_signature
} // namespace hlsl
} // namespace llvm

#endif // LLVM_FRONTEND_HLSL_HLSLROOTSIGNATURE_H
