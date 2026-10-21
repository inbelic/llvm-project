//===- HLSLSemanticStagesTest.cpp -----------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Frontend/HLSL/SemanticSignatures.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include <ostream>

using namespace llvm;
using namespace llvm::hlsl;

namespace llvm::hlsl {

static StringRef getInterpretationName(SemanticInterpretation Interpretation) {
  switch (Interpretation) {
  case SemanticInterpretation::Invalid:
    return "Invalid";
  case SemanticInterpretation::NotAllocated:
    return "NotAllocated";
  case SemanticInterpretation::NotPacked:
    return "NotPacked";
  case SemanticInterpretation::Arbitrary:
    return "Arbitrary";
  case SemanticInterpretation::SV:
    return "SV";
  case SemanticInterpretation::SGV:
    return "SGV";
  case SemanticInterpretation::ClipCull:
    return "ClipCull";
  case SemanticInterpretation::TessFactor:
    return "TessFactor";
  case SemanticInterpretation::Target:
    return "Target";
  }
  llvm_unreachable("unhandled interpretation");
}

// Print the enum by name to keep the test failures readable.
static void PrintTo(SemanticInterpretation Interpretation, std::ostream *OS) {
  *OS << getInterpretationName(Interpretation).str();
}

} // namespace llvm::hlsl

namespace {

using SemanticKind = dxbc::PSV::SemanticKind;

// Every shader stage a semantic could possibly be used in, plus a stage that
// never holds a signature (Library) to make sure it is always rejected.
constexpr Triple::EnvironmentType AllStages[] = {
    Triple::Vertex,        Triple::Hull,  Triple::Domain,
    Triple::Geometry,      Triple::Pixel, Triple::Compute,
    Triple::Amplification, Triple::Mesh,  Triple::Library};

// The semantic kinds getAvailableStages knows about.
constexpr SemanticKind SupportedKinds[] = {SemanticKind::Arbitrary,
                                           SemanticKind::Position,
                                           SemanticKind::VertexID,
                                           SemanticKind::Target,
                                           SemanticKind::IsFrontFace,
                                           SemanticKind::ClipDistance,
                                           SemanticKind::CullDistance,
                                           SemanticKind::TessFactor,
                                           SemanticKind::InsideTessFactor,
                                           SemanticKind::DispatchThreadID,
                                           SemanticKind::GroupID,
                                           SemanticKind::GroupIndex,
                                           SemanticKind::GroupThreadID,
                                           SemanticKind::InstanceID,
                                           SemanticKind::Barycentrics,
                                           SemanticKind::StartVertexLocation,
                                           SemanticKind::StartInstanceLocation,
                                           SemanticKind::SampleIndex,
                                           SemanticKind::ViewID,
                                           SemanticKind::PrimitiveID};

// Ensure all stages return a valid SemanticInterpretation
TEST(HLSLSemanticStagesTest, StagesAreValid) {
  for (SemanticKind Kind : SupportedKinds) {
    ArrayRef<SemanticStageInfo> Stages = getAvailableStages(Kind);
    EXPECT_FALSE(Stages.empty());
    for (const SemanticStageInfo &Info : Stages) {
      EXPECT_TRUE(any(Info.AllowedIOTypesMask))
          << "stage " << Triple::getEnvironmentTypeName(Info.Stage).str()
          << " allows no IOType";
      EXPECT_NE(Info.Interpretation, SemanticInterpretation::Invalid);
      EXPECT_THAT(AllStages, testing::Contains(Info.Stage));
    }
  }
}

// Ensure a stage is not listed twice with overlapping IOTypes
TEST(HLSLSemanticStagesTest, StageIOTypesAreDisjoint) {
  for (SemanticKind Kind : SupportedKinds) {
    ArrayRef<SemanticStageInfo> Stages = getAvailableStages(Kind);
    for (Triple::EnvironmentType Stage : AllStages) {
      IOType Seen = static_cast<IOType>(0);
      for (const SemanticStageInfo &Info : Stages) {
        if (Info.Stage != Stage)
          continue;
        EXPECT_FALSE(any(Seen & Info.AllowedIOTypesMask))
            << "stage " << Triple::getEnvironmentTypeName(Stage).str()
            << " is listed twice for the same IOType";
        Seen |= Info.AllowedIOTypesMask;
      }
    }
  }
}

TEST(HLSLSemanticStagesTest, BarycentricsAreUnpackedPixelInputs) {
  for (Triple::EnvironmentType Stage : AllStages)
    for (IOType IO :
         {IOType::In, IOType::Out, IOType::PatchConstantOrPrimitive})
      EXPECT_EQ(getInterpretationKind(SemanticKind::Barycentrics, Stage, IO),
                Stage == Triple::Pixel && IO == IOType::In
                    ? SemanticInterpretation::NotPacked
                    : SemanticInterpretation::Invalid);
}

// Accessed through dedicated DXIL operations and never placed in a signature.
static void expectNotAllocatedVertexInput(SemanticKind Kind) {
  for (Triple::EnvironmentType Stage : AllStages)
    for (IOType IO :
         {IOType::In, IOType::Out, IOType::PatchConstantOrPrimitive})
      EXPECT_EQ(getInterpretationKind(Kind, Stage, IO),
                Stage == Triple::Vertex && IO == IOType::In
                    ? SemanticInterpretation::NotAllocated
                    : SemanticInterpretation::Invalid);
}

TEST(HLSLSemanticStagesTest, StartVertexLocationIsANotAllocatedVertexInput) {
  expectNotAllocatedVertexInput(SemanticKind::StartVertexLocation);
}

TEST(HLSLSemanticStagesTest, StartInstanceLocationIsANotAllocatedVertexInput) {
  expectNotAllocatedVertexInput(SemanticKind::StartInstanceLocation);
}

// ViewID is read with a dedicated operation by every graphics stage that
// consumes it, but is not available to amplification shaders or mesh shader
// outputs.
TEST(HLSLSemanticStagesTest, ViewIDIsANotAllocatedGraphicsInput) {
  for (Triple::EnvironmentType Stage :
       {Triple::Vertex, Triple::Geometry, Triple::Pixel, Triple::Mesh})
    EXPECT_EQ(getInterpretationKind(SemanticKind::ViewID, Stage, IOType::In),
              SemanticInterpretation::NotAllocated);
  for (Triple::EnvironmentType Stage : AllStages)
    EXPECT_EQ(getInterpretationKind(SemanticKind::ViewID, Stage, IOType::Out),
              SemanticInterpretation::Invalid);
  EXPECT_EQ(getInterpretationKind(SemanticKind::ViewID, Triple::Amplification,
                                  IOType::In),
            SemanticInterpretation::Invalid);
  EXPECT_EQ(
      getInterpretationKind(SemanticKind::ViewID, Triple::Compute, IOType::In),
      SemanticInterpretation::Invalid);
  EXPECT_EQ(getInterpretationKind(SemanticKind::ViewID, Triple::Mesh,
                                  IOType::PatchConstantOrPrimitive),
            SemanticInterpretation::Invalid);
}

TEST(HLSLSemanticStagesTest, PrimitiveIDIsASystemGeneratedPixelInput) {
  EXPECT_EQ(getInterpretationKind(SemanticKind::PrimitiveID, Triple::Pixel,
                                  IOType::In),
            SemanticInterpretation::SGV);
  EXPECT_EQ(getInterpretationKind(SemanticKind::PrimitiveID, Triple::Pixel,
                                  IOType::Out),
            SemanticInterpretation::Invalid);
  EXPECT_EQ(getInterpretationKind(SemanticKind::PrimitiveID, Triple::Vertex,
                                  IOType::In),
            SemanticInterpretation::Invalid);
}

TEST(HLSLSemanticStagesTest, SampleIndexIsAnUnpackedPixelInput) {
  for (Triple::EnvironmentType Stage : AllStages)
    for (IOType IO :
         {IOType::In, IOType::Out, IOType::PatchConstantOrPrimitive})
      EXPECT_EQ(getInterpretationKind(SemanticKind::SampleIndex, Stage, IO),
                Stage == Triple::Pixel && IO == IOType::In
                    ? SemanticInterpretation::NotPacked
                    : SemanticInterpretation::Invalid);
}

} // namespace
