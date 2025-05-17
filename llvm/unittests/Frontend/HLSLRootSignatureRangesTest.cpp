//===------ HLSLRootSignatureRangeTest.cpp - RootSignature Range tests ----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Frontend/HLSL/HLSLRootSignature.h"
#include "gtest/gtest.h"

using namespace llvm::hlsl::rootsig;

namespace {

TEST(HLSLRootSignatureTest, NoOverlappingInsertTests) {
  // Ensures that there is never a reported overlap
  ResourceRange::IMap::Allocator Allocator;
  ResourceRange Range(Allocator);

  RangeInfo A;
  A.LowerBound = 0;
  A.UpperBound = 3;
  EXPECT_FALSE(Range.insert(A));

  RangeInfo B;
  B.LowerBound = 4;
  B.UpperBound = 7;
  EXPECT_FALSE(Range.insert(B));

  RangeInfo C;
  C.LowerBound = 10;
  C.UpperBound = RangeInfo::Unbounded;
  EXPECT_FALSE(Range.insert(C));

  EXPECT_EQ(Range.lookup(0), &A);
  EXPECT_EQ(Range.lookup(2), &A);
  EXPECT_EQ(Range.lookup(3), &A);

  EXPECT_EQ(Range.lookup(4), &B);
  EXPECT_EQ(Range.lookup(5), &B);
  EXPECT_EQ(Range.lookup(7), &B);

  EXPECT_EQ(Range.lookup(8), nullptr);
  EXPECT_EQ(Range.lookup(9), nullptr);

  EXPECT_EQ(Range.lookup(10), &C);
  EXPECT_EQ(Range.lookup(42), &C);
  EXPECT_EQ(Range.lookup(98237423), &C);
  EXPECT_EQ(Range.lookup(RangeInfo::Unbounded), &C);
}

TEST(HLSLRootSignatureTest, SingleOverlappingInsertTests) {
  // Ensures that we correctly report an overlap when we insert a range that
  // overlaps with one other range
  ResourceRange::IMap::Allocator Allocator;
  ResourceRange Range(Allocator);

  RangeInfo A;
  A.LowerBound = 1;
  A.UpperBound = 5;
  EXPECT_FALSE(Range.insert(A));

  RangeInfo B;
  B.LowerBound = 0;
  B.UpperBound = 2;
  EXPECT_TRUE(Range.insert(B));

  RangeInfo C;
  C.LowerBound = 4;
  C.UpperBound = RangeInfo::Unbounded;
  EXPECT_TRUE(Range.insert(C));

  EXPECT_EQ(Range.lookup(0), &B);
  EXPECT_EQ(Range.lookup(1), &B);
  EXPECT_EQ(Range.lookup(2), &B);
  EXPECT_EQ(Range.lookup(3), &A);
  EXPECT_EQ(Range.lookup(4), &C);
  EXPECT_EQ(Range.lookup(5), &C);
}

TEST(HLSLRootSignatureTest, MultipleOverlappingInsertTests) {
  // Ensures that we correctly report an overlap when inserted range
  // overlaps more than one range
  ResourceRange::IMap::Allocator Allocator;
  ResourceRange Range(Allocator);

  RangeInfo A;
  A.LowerBound = 0;
  A.UpperBound = 2;
  EXPECT_FALSE(Range.insert(A));

  RangeInfo B;
  B.LowerBound = 4;
  B.UpperBound = 6;
  EXPECT_FALSE(Range.insert(B));

  RangeInfo C;
  C.LowerBound = 1;
  C.UpperBound = 5;
  EXPECT_TRUE(Range.insert(C));

  EXPECT_EQ(Range.lookup(0), &A);
  EXPECT_EQ(Range.lookup(1), &A);
  EXPECT_EQ(Range.lookup(2), &A);
  EXPECT_EQ(Range.lookup(3), &C);
  EXPECT_EQ(Range.lookup(4), &B);
  EXPECT_EQ(Range.lookup(5), &B);
  EXPECT_EQ(Range.lookup(6), &B);
}


TEST(HLSLRootSignatureTest, EncapsulateInsertTests) {
  // Ensures that we correctly report an overlap when inserted range
  // encapsulates one or more ranges
  ResourceRange::IMap::Allocator Allocator;
  ResourceRange Range(Allocator);

  RangeInfo A;
  A.LowerBound = 0;
  A.UpperBound = 2;
  EXPECT_FALSE(Range.insert(A));

  RangeInfo B;
  B.LowerBound = 4;
  B.UpperBound = 5;
  EXPECT_FALSE(Range.insert(B));

  // Encapsulates B
  RangeInfo C;
  C.LowerBound = 4;
  C.UpperBound = 6;
  EXPECT_TRUE(Range.insert(C));

  EXPECT_EQ(Range.lookup(0), &A);
  EXPECT_EQ(Range.lookup(1), &A);
  EXPECT_EQ(Range.lookup(2), &A);
  EXPECT_EQ(Range.lookup(3), nullptr);
  EXPECT_EQ(Range.lookup(4), &C);
  EXPECT_EQ(Range.lookup(5), &C);
  EXPECT_EQ(Range.lookup(6), &C);

  // Encapsulates all other ranges
  RangeInfo D;
  D.LowerBound = 0;
  D.UpperBound = 7;
  EXPECT_TRUE(Range.insert(D));

  EXPECT_EQ(Range.lookup(0), &D);
  EXPECT_EQ(Range.lookup(1), &D);
  EXPECT_EQ(Range.lookup(2), &D);
  EXPECT_EQ(Range.lookup(3), &D);
  EXPECT_EQ(Range.lookup(4), &D);
  EXPECT_EQ(Range.lookup(5), &D);
  EXPECT_EQ(Range.lookup(6), &D);
}

} // namespace
