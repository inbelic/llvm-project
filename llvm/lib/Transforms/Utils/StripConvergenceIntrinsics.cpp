//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass strips convergence intrinsics and convergencectrl operand bundles,
// as those are only useful when modifying the CFG during IR passes.
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Utils/StripConvergenceIntrinsics.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Utils.h"

using namespace llvm;

static bool stripConvergenceIntrinsics(Function &F) {
  DenseSet<Instruction *> ToRemove;

  auto CleanupIntrinsic = [&](IntrinsicInst *II) {
    if (II->getIntrinsicID() != Intrinsic::experimental_convergence_entry &&
        II->getIntrinsicID() != Intrinsic::experimental_convergence_loop &&
        II->getIntrinsicID() != Intrinsic::experimental_convergence_anchor)
      return false;

    II->replaceAllUsesWith(UndefValue::get(II->getType()));
    ToRemove.insert(II);
    return true;
  };

  auto CleanupCall = [&](CallInst *CI) {
    auto OB = CI->getOperandBundle(LLVMContext::OB_convergencectrl);
    if (!OB.has_value())
      return;

    auto *NewCall = CallBase::removeOperandBundle(
        CI, LLVMContext::OB_convergencectrl, CI->getIterator());
    NewCall->copyMetadata(*CI);
    CI->replaceAllUsesWith(NewCall);
    ToRemove.insert(CI);
  };

  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *II = dyn_cast<IntrinsicInst>(&I))
        if (CleanupIntrinsic(II))
          continue;
      if (auto *CI = dyn_cast<CallInst>(&I))
        CleanupCall(CI);
    }
  }

  for (Instruction *I : ToRemove)
    I->eraseFromParent();

  return ToRemove.size() != 0;
}

PreservedAnalyses
StripConvergenceIntrinsicsPass::run(Function &F, FunctionAnalysisManager &) {
  if (!stripConvergenceIntrinsics(F))
    return PreservedAnalyses::all();
  return PreservedAnalyses::none();
}

namespace {
class StripConvergenceIntrinsicsLegacyPass : public FunctionPass {
public:
  static char ID;

  StripConvergenceIntrinsicsLegacyPass() : FunctionPass(ID) {
    initializeStripConvergenceIntrinsicsLegacyPassPass(
        *PassRegistry::getPassRegistry());
  }

  bool runOnFunction(Function &F) override {
    return stripConvergenceIntrinsics(F);
  }
};
} // namespace

char StripConvergenceIntrinsicsLegacyPass::ID = 0;
INITIALIZE_PASS(StripConvergenceIntrinsicsLegacyPass,
                "strip-convergence-intrinsics",
                "Strip convergence intrinsics and operand bundles", false,
                false)

FunctionPass *llvm::createStripConvergenceIntrinsicsPass() {
  return new StripConvergenceIntrinsicsLegacyPass();
}
