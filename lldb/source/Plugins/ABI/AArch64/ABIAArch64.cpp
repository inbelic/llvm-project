//===-- AArch66.h ---------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "lldb/lldb-types.h"

#include "ABIAArch64.h"
#include "ABIMacOSX_arm64.h"
#include "ABISysV_arm64.h"
#include "Utility/ARM64_DWARF_Registers.h"
#include "Utility/ARM64_ehframe_Registers.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Target/Process.h"

#include <bitset>
#include <optional>

using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE(ABIAArch64)

void ABIAArch64::Initialize() {
  ABISysV_arm64::Initialize();
  ABIMacOSX_arm64::Initialize();
}

void ABIAArch64::Terminate() {
  ABISysV_arm64::Terminate();
  ABIMacOSX_arm64::Terminate();
}

lldb::addr_t ABIAArch64::FixCodeAddress(lldb::addr_t pc) {
  if (lldb::ProcessSP process_sp = GetProcessSP()) {
    // b55 is the highest bit outside TBI (if it's enabled), use
    // it to determine if the high bits are set to 0 or 1.
    const addr_t pac_sign_extension = 0x0080000000000000ULL;
    addr_t mask = process_sp->GetCodeAddressMask();
    // Test if the high memory mask has been overriden separately
    if (pc & pac_sign_extension &&
        process_sp->GetHighmemCodeAddressMask() != LLDB_INVALID_ADDRESS_MASK)
      mask = process_sp->GetHighmemCodeAddressMask();

    if (mask != LLDB_INVALID_ADDRESS_MASK)
      return FixAddress(pc, mask);
  }
  return pc;
}

lldb::addr_t ABIAArch64::FixDataAddress(lldb::addr_t pc) {
  if (lldb::ProcessSP process_sp = GetProcessSP()) {
    // b55 is the highest bit outside TBI (if it's enabled), use
    // it to determine if the high bits are set to 0 or 1.
    const addr_t pac_sign_extension = 0x0080000000000000ULL;
    addr_t mask = process_sp->GetDataAddressMask();
    // Test if the high memory mask has been overriden separately
    if (pc & pac_sign_extension &&
        process_sp->GetHighmemDataAddressMask() != LLDB_INVALID_ADDRESS_MASK)
      mask = process_sp->GetHighmemDataAddressMask();
    if (mask != LLDB_INVALID_ADDRESS_MASK)
      return FixAddress(pc, mask);
  }
  return pc;
}

std::pair<uint32_t, uint32_t>
ABIAArch64::GetEHAndDWARFNums(llvm::StringRef name) {
  if (name == "pc")
    return {arm64_ehframe::pc, arm64_dwarf::pc};
  if (name == "cpsr")
    return {arm64_ehframe::cpsr, arm64_dwarf::cpsr};
  return MCBasedABI::GetEHAndDWARFNums(name);
}

std::string ABIAArch64::GetMCName(std::string reg) {
  MapRegisterName(reg, "v", "q");
  MapRegisterName(reg, "x29", "fp");
  MapRegisterName(reg, "x30", "lr");
  return reg;
}

uint32_t ABIAArch64::GetGenericNum(llvm::StringRef name) {
  return llvm::StringSwitch<uint32_t>(name)
      .Case("pc", LLDB_REGNUM_GENERIC_PC)
      .Cases("lr", "x30", LLDB_REGNUM_GENERIC_RA)
      .Cases("sp", "x31", LLDB_REGNUM_GENERIC_SP)
      .Cases("fp", "x29", LLDB_REGNUM_GENERIC_FP)
      .Case("cpsr", LLDB_REGNUM_GENERIC_FLAGS)
      .Case("x0", LLDB_REGNUM_GENERIC_ARG1)
      .Case("x1", LLDB_REGNUM_GENERIC_ARG2)
      .Case("x2", LLDB_REGNUM_GENERIC_ARG3)
      .Case("x3", LLDB_REGNUM_GENERIC_ARG4)
      .Case("x4", LLDB_REGNUM_GENERIC_ARG5)
      .Case("x5", LLDB_REGNUM_GENERIC_ARG6)
      .Case("x6", LLDB_REGNUM_GENERIC_ARG7)
      .Case("x7", LLDB_REGNUM_GENERIC_ARG8)
      .Default(LLDB_INVALID_REGNUM);
}

static void addPartialRegisters(
    std::vector<lldb_private::DynamicRegisterInfo::Register> &regs,
    llvm::ArrayRef<std::optional<uint32_t>> full_reg_indices,
    uint32_t full_reg_size, const char *partial_reg_format,
    uint32_t partial_reg_size, lldb::Encoding encoding, lldb::Format format) {
  for (auto it : llvm::enumerate(full_reg_indices)) {
    std::optional<uint32_t> full_reg_index = it.value();
    if (!full_reg_index || regs[*full_reg_index].byte_size != full_reg_size)
      return;

    lldb_private::DynamicRegisterInfo::Register partial_reg{
        lldb_private::ConstString(
            llvm::formatv(partial_reg_format, it.index()).str()),
        lldb_private::ConstString(),
        lldb_private::ConstString("supplementary registers"),
        partial_reg_size,
        LLDB_INVALID_INDEX32,
        encoding,
        format,
        LLDB_INVALID_REGNUM,
        LLDB_INVALID_REGNUM,
        LLDB_INVALID_REGNUM,
        LLDB_INVALID_REGNUM,
        {*full_reg_index},
        {}};
    addSupplementaryRegister(regs, partial_reg);
  }
}

void ABIAArch64::AugmentRegisterInfo(
    std::vector<lldb_private::DynamicRegisterInfo::Register> &regs) {
  lldb_private::MCBasedABI::AugmentRegisterInfo(regs);

  lldb_private::ConstString sp_string{"sp"};

  std::array<std::optional<uint32_t>, 32> x_regs;
  std::array<std::optional<uint32_t>, 32> v_regs;
  std::array<std::optional<uint32_t>, 32> z_regs;
  std::optional<uint32_t> z_byte_size;

  for (auto it : llvm::enumerate(regs)) {
    lldb_private::DynamicRegisterInfo::Register &info = it.value();
    // GDB sends x31 as "sp".  Add the "x31" alt_name for convenience.
    if (info.name == sp_string && !info.alt_name)
      info.alt_name.SetCString("x31");

    unsigned int reg_num;
    auto get_reg = [&info, &reg_num](const char *prefix) {
      llvm::StringRef reg_name = info.name.GetStringRef();
      llvm::StringRef alt_name = info.alt_name.GetStringRef();
      return (reg_name.consume_front(prefix) &&
              llvm::to_integer(reg_name, reg_num, 10) && reg_num < 32) ||
             (alt_name.consume_front(prefix) &&
              llvm::to_integer(alt_name, reg_num, 10) && reg_num < 32);
    };

    if (get_reg("x"))
      x_regs[reg_num] = it.index();
    else if (get_reg("v"))
      v_regs[reg_num] = it.index();
    else if (get_reg("z")) {
      z_regs[reg_num] = it.index();
      if (!z_byte_size)
        z_byte_size = info.byte_size;
    }
    // if we have at least one subregister, abort
    else if (get_reg("w") || get_reg("s") || get_reg("d"))
      return;
  }

  // Create aliases for partial registers.

  // Wn for Xn.
  addPartialRegisters(regs, x_regs, 8, "w{0}", 4, lldb::eEncodingUint,
                      lldb::eFormatHex);

  auto bool_predicate = [](const auto &reg_num) { return bool(reg_num); };
  bool saw_v_regs = llvm::any_of(v_regs, bool_predicate);
  bool saw_z_regs = llvm::any_of(z_regs, bool_predicate);

  // Sn/Dn for Vn.
  if (saw_v_regs) {
    addPartialRegisters(regs, v_regs, 16, "s{0}", 4, lldb::eEncodingIEEE754,
                        lldb::eFormatFloat);
    addPartialRegisters(regs, v_regs, 16, "d{0}", 8, lldb::eEncodingIEEE754,
                        lldb::eFormatFloat);
  } else if (saw_z_regs && z_byte_size) {
    // When SVE is enabled, some debug stubs will not describe the Neon V
    // registers because they can be read from the bottom 128 bits of the SVE
    // registers.

    // The size used here is the one sent by the debug server. This only needs
    // to be correct right now. Later we will rely on the value of vg instead.
    addPartialRegisters(regs, z_regs, *z_byte_size, "v{0}", 16,
                        lldb::eEncodingVector, lldb::eFormatVectorOfUInt8);
    addPartialRegisters(regs, z_regs, *z_byte_size, "s{0}", 4,
                        lldb::eEncodingIEEE754, lldb::eFormatFloat);
    addPartialRegisters(regs, z_regs, *z_byte_size, "d{0}", 8,
                        lldb::eEncodingIEEE754, lldb::eFormatFloat);
  }
}

UnwindPlanSP ABIAArch64::CreateFunctionEntryUnwindPlan() {
  UnwindPlan::Row row;

  // Our previous Call Frame Address is the stack pointer
  row.GetCFAValue().SetIsRegisterPlusOffset(LLDB_REGNUM_GENERIC_SP, 0);

  // Our previous PC is in the LR, all other registers are the same.
  row.SetRegisterLocationToRegister(LLDB_REGNUM_GENERIC_PC,
                                    LLDB_REGNUM_GENERIC_RA, true);

  auto plan_sp = std::make_shared<UnwindPlan>(eRegisterKindGeneric);
  plan_sp->AppendRow(std::move(row));
  plan_sp->SetSourceName("arm64 at-func-entry default");
  plan_sp->SetSourcedFromCompiler(eLazyBoolNo);
  plan_sp->SetUnwindPlanValidAtAllInstructions(eLazyBoolNo);
  plan_sp->SetUnwindPlanForSignalTrap(eLazyBoolNo);
  return plan_sp;
}

UnwindPlanSP ABIAArch64::CreateDefaultUnwindPlan() {
  UnwindPlan::Row row;
  const int32_t ptr_size = 8;

  row.GetCFAValue().SetIsRegisterPlusOffset(LLDB_REGNUM_GENERIC_FP,
                                            2 * ptr_size);
  row.SetUnspecifiedRegistersAreUndefined(true);

  row.SetRegisterLocationToAtCFAPlusOffset(LLDB_REGNUM_GENERIC_FP,
                                           ptr_size * -2, true);
  row.SetRegisterLocationToAtCFAPlusOffset(LLDB_REGNUM_GENERIC_PC,
                                           ptr_size * -1, true);

  auto plan_sp = std::make_shared<UnwindPlan>(eRegisterKindGeneric);
  plan_sp->AppendRow(std::move(row));
  plan_sp->SetSourceName("arm64 default unwind plan");
  plan_sp->SetSourcedFromCompiler(eLazyBoolNo);
  plan_sp->SetUnwindPlanValidAtAllInstructions(eLazyBoolNo);
  plan_sp->SetUnwindPlanForSignalTrap(eLazyBoolNo);
  return plan_sp;
}
