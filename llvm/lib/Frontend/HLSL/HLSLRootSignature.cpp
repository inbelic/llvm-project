
//===- HLSLResource.cpp - HLSL Resource helper objects --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file This file contains helpers for working with HLSL RootSignatures.
///
//===----------------------------------------------------------------------===//

#include "llvm/Frontend/HLSL/HLSLRootSignature.h"

using namespace llvm;
using namespace llvm::hlsl::root_signature;

// General printing helpers
static void DumpVisibility(raw_ostream &OS, ShaderVisibility Visibility) {
  switch (Visibility) {
  case ShaderVisibility::All: OS << "All"; break;
  case ShaderVisibility::Vertex: OS << "Vertex"; break;
  case ShaderVisibility::Hull: OS << "Hull"; break;
  case ShaderVisibility::Domain: OS << "Domain"; break;
  case ShaderVisibility::Geometry: OS << "Geometry"; break;
  case ShaderVisibility::Pixel: OS << "Pixel"; break;
  case ShaderVisibility::Amplification: OS << "Amplification"; break;
  case ShaderVisibility::Mesh: OS << "Mesh"; break;
  }
}

void DescriptorTableClause::Dump(raw_ostream &OS) const {
}

void DescriptorTable::Dump(raw_ostream &OS) const {
  OS << "DescriptorTable(visibility = ";
  DumpVisibility(OS, Visibility);
  OS << ")";
}

void RootElement::Dump(raw_ostream &OS) const {
  switch (Tag) {
  case RootElement::ElementType::DescriptorTable: Table.Dump(OS); break;
  case RootElement::ElementType::DescriptorTableClause: Clause.Dump(OS); break;
  }
  OS << ")";
}
