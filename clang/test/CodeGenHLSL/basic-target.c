// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-pixel -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-vertex -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-compute -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-library -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-hull -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-domain -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.0-geometry -emit-llvm -o - %s | FileCheck %s --check-prefix=NOI64

// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-pixel -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-vertex -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-compute -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-library -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-hull -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-domain -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64
// RUN: %clang -cc1 -triple dxil-pc-shadermodel6.3-geometry -emit-llvm -o - %s | FileCheck %s --check-prefix=WITHI64

// NOI64: target datalayout = "e-m:e-p:32:32-i1:32-i8:8-i16:16-i32:32-i64:64-f16:16-f32:32-f64:64-n8:16:32-v48:16:16-v96:32:32-v192:64:64"
// NOI64: target triple = "dxilv1.0-pc-shadermodel6.0-{{[a-z]+}}"

// WITHI64: target datalayout = "e-m:e-p:32:32-i1:32-i8:8-i16:16-i32:32-i64:64-f16:16-f32:32-f64:64-n8:16:32:64-v48:16:16-v96:32:32-v192:64:64"
// WITHI64: target triple = "dxilv1.3-pc-shadermodel6.3-{{[a-z]+}}"
