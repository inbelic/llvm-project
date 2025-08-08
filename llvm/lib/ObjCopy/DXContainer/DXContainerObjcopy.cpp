//===- DXContainerObjcopy.cpp ---------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/ObjCopy/DXContainer/DXContainerObjcopy.h"
#include "llvm/ObjCopy/CommonConfig.h"
#include "llvm/ObjCopy/DXContainer/DXContainerConfig.h"
#include "llvm/Support/FileOutputBuffer.h"

#include "DXContainerReader.h"
#include "DXContainerWriter.h"

namespace llvm {
namespace objcopy {
namespace dxc {

using namespace object;

static Error dumpPartAsObject(StringRef Filename, dxbc::Header Header,
                              const Part &P) {
  size_t HeaderOffset = sizeof(dxbc::Header) // DXContainer header
                        + sizeof(uint32_t);  // Single part offset
  size_t Size = HeaderOffset + 4 + sizeof(uint32_t) + P.Data.size();

  Header.FileSize = Size;
  Header.PartCount = 1;

  Expected<std::unique_ptr<FileOutputBuffer>> BufferOrErr =
      FileOutputBuffer::create(Filename, Size);
  if (!BufferOrErr)
    return createFileError(Filename, BufferOrErr.takeError());
  std::unique_ptr<FileOutputBuffer> Buf = std::move(*BufferOrErr);

  uint8_t *BufPtr = Buf->getBufferStart();
  memcpy(BufPtr, reinterpret_cast<const char *>(&Header), sizeof(dxbc::Header));
  BufPtr += sizeof(dxbc::Header);
  memcpy(BufPtr, reinterpret_cast<const char *>(&HeaderOffset),
         sizeof(uint32_t));
  BufPtr += sizeof(uint32_t);
  memcpy(BufPtr, reinterpret_cast<const char *>(P.Name.data()), P.Name.size());
  BufPtr += P.Name.size();
  uint32_t PartSize = P.Data.size();
  memcpy(BufPtr, reinterpret_cast<const char *>(&PartSize), sizeof(uint32_t));
  BufPtr += sizeof(uint32_t);
  memcpy(BufPtr, reinterpret_cast<const char *>(P.Data.data()), P.Data.size());
  BufPtr += P.Data.size();

  if (Error E = Buf->commit())
    return createFileError(Filename, std::move(E));
  return Error::success();
}

static Error dumpPartToFile(StringRef PartName, StringRef Filename,
                            StringRef InputFilename, Object &Obj) {
  for (auto &P : Obj.Parts)
    if (P.Name == PartName) {
      if (Error E = dumpPartAsObject(Filename, Obj.Header, P))
        return E;
      return Error::success();
    }

  return createFileError(InputFilename, object_error::parse_failed,
                         "part '%s' not found", PartName.str().c_str());
}

static Error handleArgs(const CommonConfig &Config, Object &Obj) {
  // Dump sections before strip of any parts
  for (StringRef Flag : Config.DumpSection) {
    StringRef SectionName;
    StringRef FileName;
    std::tie(SectionName, FileName) = Flag.split('=');
    if (Error E =
            dumpPartToFile(SectionName, FileName, Config.InputFilename, Obj))
      return E;
  }

  return Error::success();
}

Error executeObjcopyOnBinary(const CommonConfig &Config,
                             const DXContainerConfig &,
                             DXContainerObjectFile &In, raw_ostream &Out) {
  DXContainerReader Reader(In);
  Expected<std::unique_ptr<Object>> ObjOrErr = Reader.create();
  if (!ObjOrErr)
    return createFileError(Config.InputFilename, ObjOrErr.takeError());
  Object *Obj = ObjOrErr->get();
  assert(Obj && "Unable to deserialize DXContainer object");

  if (Error E = handleArgs(Config, *Obj))
    return E;

  DXContainerWriter Writer(*Obj, Out);
  if (Error E = Writer.write())
    return createFileError(Config.OutputFilename, std::move(E));
  return Error::success();
}

} // end namespace dxc
} // end namespace objcopy
} // end namespace llvm
