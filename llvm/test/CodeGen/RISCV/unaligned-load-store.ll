; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefixes=ALL,SLOW,SLOWBASE,RV32I %s
; RUN: llc -mtriple=riscv64 -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefixes=ALL,SLOW,SLOWBASE,RV64I %s
; RUN: llc -mtriple=riscv32 -mattr=+zbkb -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefixes=ALL,SLOW,SLOWZBKB,RV32IZBKB %s
; RUN: llc -mtriple=riscv64 -mattr=+zbkb -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefixes=ALL,SLOW,SLOWZBKB,RV64IZBKB %s
; RUN: llc -mtriple=riscv32 -mattr=+unaligned-scalar-mem -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefixes=ALL,FAST,RV32I-FAST %s
; RUN: llc -mtriple=riscv64 -mattr=+unaligned-scalar-mem -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefixes=ALL,FAST,RV64I-FAST %s

; A collection of cases showing codegen for unaligned loads and stores

define i8 @load_i8(ptr %p) {
; ALL-LABEL: load_i8:
; ALL:       # %bb.0:
; ALL-NEXT:    lbu a0, 0(a0)
; ALL-NEXT:    ret
  %res = load i8, ptr %p, align 1
  ret i8 %res
}

define i16 @load_i16(ptr %p) {
; SLOW-LABEL: load_i16:
; SLOW:       # %bb.0:
; SLOW-NEXT:    lbu a1, 1(a0)
; SLOW-NEXT:    lbu a0, 0(a0)
; SLOW-NEXT:    slli a1, a1, 8
; SLOW-NEXT:    or a0, a1, a0
; SLOW-NEXT:    ret
;
; FAST-LABEL: load_i16:
; FAST:       # %bb.0:
; FAST-NEXT:    lh a0, 0(a0)
; FAST-NEXT:    ret
  %res = load i16, ptr %p, align 1
  ret i16 %res
}

define i24 @load_i24(ptr %p) {
; SLOWBASE-LABEL: load_i24:
; SLOWBASE:       # %bb.0:
; SLOWBASE-NEXT:    lbu a1, 1(a0)
; SLOWBASE-NEXT:    lbu a2, 0(a0)
; SLOWBASE-NEXT:    lbu a0, 2(a0)
; SLOWBASE-NEXT:    slli a1, a1, 8
; SLOWBASE-NEXT:    or a1, a1, a2
; SLOWBASE-NEXT:    slli a0, a0, 16
; SLOWBASE-NEXT:    or a0, a1, a0
; SLOWBASE-NEXT:    ret
;
; RV32IZBKB-LABEL: load_i24:
; RV32IZBKB:       # %bb.0:
; RV32IZBKB-NEXT:    lbu a1, 0(a0)
; RV32IZBKB-NEXT:    lbu a2, 1(a0)
; RV32IZBKB-NEXT:    lbu a0, 2(a0)
; RV32IZBKB-NEXT:    packh a1, a1, a2
; RV32IZBKB-NEXT:    pack a0, a1, a0
; RV32IZBKB-NEXT:    ret
;
; RV64IZBKB-LABEL: load_i24:
; RV64IZBKB:       # %bb.0:
; RV64IZBKB-NEXT:    lbu a1, 0(a0)
; RV64IZBKB-NEXT:    lbu a2, 1(a0)
; RV64IZBKB-NEXT:    lbu a0, 2(a0)
; RV64IZBKB-NEXT:    packh a1, a1, a2
; RV64IZBKB-NEXT:    slli a0, a0, 16
; RV64IZBKB-NEXT:    or a0, a1, a0
; RV64IZBKB-NEXT:    ret
;
; FAST-LABEL: load_i24:
; FAST:       # %bb.0:
; FAST-NEXT:    lbu a1, 2(a0)
; FAST-NEXT:    lhu a0, 0(a0)
; FAST-NEXT:    slli a1, a1, 16
; FAST-NEXT:    or a0, a0, a1
; FAST-NEXT:    ret
  %res = load i24, ptr %p, align 1
  ret i24 %res
}

define i32 @load_i32(ptr %p) {
; SLOWBASE-LABEL: load_i32:
; SLOWBASE:       # %bb.0:
; SLOWBASE-NEXT:    lbu a1, 1(a0)
; SLOWBASE-NEXT:    lbu a2, 0(a0)
; SLOWBASE-NEXT:    lbu a3, 2(a0)
; SLOWBASE-NEXT:    lbu a0, 3(a0)
; SLOWBASE-NEXT:    slli a1, a1, 8
; SLOWBASE-NEXT:    or a1, a1, a2
; SLOWBASE-NEXT:    slli a3, a3, 16
; SLOWBASE-NEXT:    slli a0, a0, 24
; SLOWBASE-NEXT:    or a0, a0, a3
; SLOWBASE-NEXT:    or a0, a0, a1
; SLOWBASE-NEXT:    ret
;
; RV32IZBKB-LABEL: load_i32:
; RV32IZBKB:       # %bb.0:
; RV32IZBKB-NEXT:    lbu a1, 1(a0)
; RV32IZBKB-NEXT:    lbu a2, 2(a0)
; RV32IZBKB-NEXT:    lbu a3, 3(a0)
; RV32IZBKB-NEXT:    lbu a0, 0(a0)
; RV32IZBKB-NEXT:    packh a2, a2, a3
; RV32IZBKB-NEXT:    packh a0, a0, a1
; RV32IZBKB-NEXT:    pack a0, a0, a2
; RV32IZBKB-NEXT:    ret
;
; RV64IZBKB-LABEL: load_i32:
; RV64IZBKB:       # %bb.0:
; RV64IZBKB-NEXT:    lbu a1, 0(a0)
; RV64IZBKB-NEXT:    lbu a2, 1(a0)
; RV64IZBKB-NEXT:    lbu a3, 2(a0)
; RV64IZBKB-NEXT:    lbu a0, 3(a0)
; RV64IZBKB-NEXT:    packh a1, a1, a2
; RV64IZBKB-NEXT:    slli a3, a3, 16
; RV64IZBKB-NEXT:    slli a0, a0, 24
; RV64IZBKB-NEXT:    or a0, a0, a3
; RV64IZBKB-NEXT:    or a0, a0, a1
; RV64IZBKB-NEXT:    ret
;
; FAST-LABEL: load_i32:
; FAST:       # %bb.0:
; FAST-NEXT:    lw a0, 0(a0)
; FAST-NEXT:    ret
  %res = load i32, ptr %p, align 1
  ret i32 %res
}

define i64 @load_i64(ptr %p) {
; RV32I-LABEL: load_i64:
; RV32I:       # %bb.0:
; RV32I-NEXT:    lbu a1, 1(a0)
; RV32I-NEXT:    lbu a2, 2(a0)
; RV32I-NEXT:    lbu a3, 3(a0)
; RV32I-NEXT:    lbu a4, 0(a0)
; RV32I-NEXT:    slli a1, a1, 8
; RV32I-NEXT:    slli a2, a2, 16
; RV32I-NEXT:    slli a3, a3, 24
; RV32I-NEXT:    or a1, a1, a4
; RV32I-NEXT:    or a2, a3, a2
; RV32I-NEXT:    lbu a3, 5(a0)
; RV32I-NEXT:    lbu a4, 4(a0)
; RV32I-NEXT:    lbu a5, 6(a0)
; RV32I-NEXT:    lbu a0, 7(a0)
; RV32I-NEXT:    slli a3, a3, 8
; RV32I-NEXT:    or a3, a3, a4
; RV32I-NEXT:    slli a5, a5, 16
; RV32I-NEXT:    slli a0, a0, 24
; RV32I-NEXT:    or a5, a0, a5
; RV32I-NEXT:    or a0, a2, a1
; RV32I-NEXT:    or a1, a5, a3
; RV32I-NEXT:    ret
;
; RV64I-LABEL: load_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    lbu a1, 1(a0)
; RV64I-NEXT:    lbu a2, 2(a0)
; RV64I-NEXT:    lbu a3, 3(a0)
; RV64I-NEXT:    lbu a4, 0(a0)
; RV64I-NEXT:    slli a1, a1, 8
; RV64I-NEXT:    slli a2, a2, 16
; RV64I-NEXT:    slli a3, a3, 24
; RV64I-NEXT:    or a1, a1, a4
; RV64I-NEXT:    or a2, a3, a2
; RV64I-NEXT:    lbu a3, 5(a0)
; RV64I-NEXT:    lbu a4, 4(a0)
; RV64I-NEXT:    lbu a5, 6(a0)
; RV64I-NEXT:    lbu a0, 7(a0)
; RV64I-NEXT:    slli a3, a3, 8
; RV64I-NEXT:    or a3, a3, a4
; RV64I-NEXT:    slli a5, a5, 16
; RV64I-NEXT:    slli a0, a0, 24
; RV64I-NEXT:    or a0, a0, a5
; RV64I-NEXT:    or a1, a2, a1
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    slli a0, a0, 32
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    ret
;
; RV32IZBKB-LABEL: load_i64:
; RV32IZBKB:       # %bb.0:
; RV32IZBKB-NEXT:    lbu a1, 0(a0)
; RV32IZBKB-NEXT:    lbu a2, 1(a0)
; RV32IZBKB-NEXT:    lbu a3, 2(a0)
; RV32IZBKB-NEXT:    lbu a4, 3(a0)
; RV32IZBKB-NEXT:    lbu a5, 5(a0)
; RV32IZBKB-NEXT:    lbu a6, 6(a0)
; RV32IZBKB-NEXT:    lbu a7, 7(a0)
; RV32IZBKB-NEXT:    lbu a0, 4(a0)
; RV32IZBKB-NEXT:    packh a3, a3, a4
; RV32IZBKB-NEXT:    packh a1, a1, a2
; RV32IZBKB-NEXT:    packh a2, a6, a7
; RV32IZBKB-NEXT:    packh a4, a0, a5
; RV32IZBKB-NEXT:    pack a0, a1, a3
; RV32IZBKB-NEXT:    pack a1, a4, a2
; RV32IZBKB-NEXT:    ret
;
; RV64IZBKB-LABEL: load_i64:
; RV64IZBKB:       # %bb.0:
; RV64IZBKB-NEXT:    lbu a1, 4(a0)
; RV64IZBKB-NEXT:    lbu a2, 5(a0)
; RV64IZBKB-NEXT:    lbu a3, 6(a0)
; RV64IZBKB-NEXT:    lbu a4, 7(a0)
; RV64IZBKB-NEXT:    lbu a5, 0(a0)
; RV64IZBKB-NEXT:    lbu a6, 1(a0)
; RV64IZBKB-NEXT:    lbu a7, 2(a0)
; RV64IZBKB-NEXT:    lbu a0, 3(a0)
; RV64IZBKB-NEXT:    packh a1, a1, a2
; RV64IZBKB-NEXT:    packh a2, a3, a4
; RV64IZBKB-NEXT:    packh a3, a5, a6
; RV64IZBKB-NEXT:    packh a0, a7, a0
; RV64IZBKB-NEXT:    slli a2, a2, 16
; RV64IZBKB-NEXT:    slli a0, a0, 16
; RV64IZBKB-NEXT:    or a1, a2, a1
; RV64IZBKB-NEXT:    or a0, a0, a3
; RV64IZBKB-NEXT:    pack a0, a0, a1
; RV64IZBKB-NEXT:    ret
;
; RV32I-FAST-LABEL: load_i64:
; RV32I-FAST:       # %bb.0:
; RV32I-FAST-NEXT:    lw a2, 0(a0)
; RV32I-FAST-NEXT:    lw a1, 4(a0)
; RV32I-FAST-NEXT:    mv a0, a2
; RV32I-FAST-NEXT:    ret
;
; RV64I-FAST-LABEL: load_i64:
; RV64I-FAST:       # %bb.0:
; RV64I-FAST-NEXT:    ld a0, 0(a0)
; RV64I-FAST-NEXT:    ret
  %res = load i64, ptr %p, align 1
  ret i64 %res
}

define void @store_i8(ptr %p, i8 %v) {
; ALL-LABEL: store_i8:
; ALL:       # %bb.0:
; ALL-NEXT:    sb a1, 0(a0)
; ALL-NEXT:    ret
  store i8 %v, ptr %p, align 1
  ret void
}

define void @store_i16(ptr %p, i16 %v) {
; SLOW-LABEL: store_i16:
; SLOW:       # %bb.0:
; SLOW-NEXT:    srli a2, a1, 8
; SLOW-NEXT:    sb a1, 0(a0)
; SLOW-NEXT:    sb a2, 1(a0)
; SLOW-NEXT:    ret
;
; FAST-LABEL: store_i16:
; FAST:       # %bb.0:
; FAST-NEXT:    sh a1, 0(a0)
; FAST-NEXT:    ret
  store i16 %v, ptr %p, align 1
  ret void
}

define void @store_i24(ptr %p, i24 %v) {
; SLOW-LABEL: store_i24:
; SLOW:       # %bb.0:
; SLOW-NEXT:    srli a2, a1, 8
; SLOW-NEXT:    srli a3, a1, 16
; SLOW-NEXT:    sb a1, 0(a0)
; SLOW-NEXT:    sb a2, 1(a0)
; SLOW-NEXT:    sb a3, 2(a0)
; SLOW-NEXT:    ret
;
; FAST-LABEL: store_i24:
; FAST:       # %bb.0:
; FAST-NEXT:    srli a2, a1, 16
; FAST-NEXT:    sh a1, 0(a0)
; FAST-NEXT:    sb a2, 2(a0)
; FAST-NEXT:    ret
  store i24 %v, ptr %p, align 1
  ret void
}

define void @store_i32(ptr %p, i32 %v) {
; SLOW-LABEL: store_i32:
; SLOW:       # %bb.0:
; SLOW-NEXT:    srli a2, a1, 24
; SLOW-NEXT:    srli a3, a1, 16
; SLOW-NEXT:    srli a4, a1, 8
; SLOW-NEXT:    sb a1, 0(a0)
; SLOW-NEXT:    sb a4, 1(a0)
; SLOW-NEXT:    sb a3, 2(a0)
; SLOW-NEXT:    sb a2, 3(a0)
; SLOW-NEXT:    ret
;
; FAST-LABEL: store_i32:
; FAST:       # %bb.0:
; FAST-NEXT:    sw a1, 0(a0)
; FAST-NEXT:    ret
  store i32 %v, ptr %p, align 1
  ret void
}

define void @store_i64(ptr %p, i64 %v) {
; RV32I-LABEL: store_i64:
; RV32I:       # %bb.0:
; RV32I-NEXT:    srli a3, a2, 24
; RV32I-NEXT:    srli a4, a2, 16
; RV32I-NEXT:    srli a5, a2, 8
; RV32I-NEXT:    srli a6, a1, 24
; RV32I-NEXT:    srli a7, a1, 16
; RV32I-NEXT:    sb a2, 4(a0)
; RV32I-NEXT:    sb a5, 5(a0)
; RV32I-NEXT:    sb a4, 6(a0)
; RV32I-NEXT:    sb a3, 7(a0)
; RV32I-NEXT:    srli a2, a1, 8
; RV32I-NEXT:    sb a1, 0(a0)
; RV32I-NEXT:    sb a2, 1(a0)
; RV32I-NEXT:    sb a7, 2(a0)
; RV32I-NEXT:    sb a6, 3(a0)
; RV32I-NEXT:    ret
;
; RV64I-LABEL: store_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srli a2, a1, 56
; RV64I-NEXT:    srli a3, a1, 48
; RV64I-NEXT:    srli a4, a1, 40
; RV64I-NEXT:    srli a5, a1, 32
; RV64I-NEXT:    srli a6, a1, 24
; RV64I-NEXT:    srli a7, a1, 16
; RV64I-NEXT:    sb a5, 4(a0)
; RV64I-NEXT:    sb a4, 5(a0)
; RV64I-NEXT:    sb a3, 6(a0)
; RV64I-NEXT:    sb a2, 7(a0)
; RV64I-NEXT:    srli a2, a1, 8
; RV64I-NEXT:    sb a1, 0(a0)
; RV64I-NEXT:    sb a2, 1(a0)
; RV64I-NEXT:    sb a7, 2(a0)
; RV64I-NEXT:    sb a6, 3(a0)
; RV64I-NEXT:    ret
;
; RV32IZBKB-LABEL: store_i64:
; RV32IZBKB:       # %bb.0:
; RV32IZBKB-NEXT:    srli a3, a2, 24
; RV32IZBKB-NEXT:    srli a4, a2, 16
; RV32IZBKB-NEXT:    srli a5, a2, 8
; RV32IZBKB-NEXT:    srli a6, a1, 24
; RV32IZBKB-NEXT:    srli a7, a1, 16
; RV32IZBKB-NEXT:    sb a2, 4(a0)
; RV32IZBKB-NEXT:    sb a5, 5(a0)
; RV32IZBKB-NEXT:    sb a4, 6(a0)
; RV32IZBKB-NEXT:    sb a3, 7(a0)
; RV32IZBKB-NEXT:    srli a2, a1, 8
; RV32IZBKB-NEXT:    sb a1, 0(a0)
; RV32IZBKB-NEXT:    sb a2, 1(a0)
; RV32IZBKB-NEXT:    sb a7, 2(a0)
; RV32IZBKB-NEXT:    sb a6, 3(a0)
; RV32IZBKB-NEXT:    ret
;
; RV64IZBKB-LABEL: store_i64:
; RV64IZBKB:       # %bb.0:
; RV64IZBKB-NEXT:    srli a2, a1, 56
; RV64IZBKB-NEXT:    srli a3, a1, 48
; RV64IZBKB-NEXT:    srli a4, a1, 40
; RV64IZBKB-NEXT:    srli a5, a1, 32
; RV64IZBKB-NEXT:    srli a6, a1, 24
; RV64IZBKB-NEXT:    srli a7, a1, 16
; RV64IZBKB-NEXT:    sb a5, 4(a0)
; RV64IZBKB-NEXT:    sb a4, 5(a0)
; RV64IZBKB-NEXT:    sb a3, 6(a0)
; RV64IZBKB-NEXT:    sb a2, 7(a0)
; RV64IZBKB-NEXT:    srli a2, a1, 8
; RV64IZBKB-NEXT:    sb a1, 0(a0)
; RV64IZBKB-NEXT:    sb a2, 1(a0)
; RV64IZBKB-NEXT:    sb a7, 2(a0)
; RV64IZBKB-NEXT:    sb a6, 3(a0)
; RV64IZBKB-NEXT:    ret
;
; RV32I-FAST-LABEL: store_i64:
; RV32I-FAST:       # %bb.0:
; RV32I-FAST-NEXT:    sw a1, 0(a0)
; RV32I-FAST-NEXT:    sw a2, 4(a0)
; RV32I-FAST-NEXT:    ret
;
; RV64I-FAST-LABEL: store_i64:
; RV64I-FAST:       # %bb.0:
; RV64I-FAST-NEXT:    sd a1, 0(a0)
; RV64I-FAST-NEXT:    ret
  store i64 %v, ptr %p, align 1
  ret void
}

define void @merge_stores_i8_i16(ptr %p) {
; SLOW-LABEL: merge_stores_i8_i16:
; SLOW:       # %bb.0:
; SLOW-NEXT:    sb zero, 0(a0)
; SLOW-NEXT:    sb zero, 1(a0)
; SLOW-NEXT:    ret
;
; FAST-LABEL: merge_stores_i8_i16:
; FAST:       # %bb.0:
; FAST-NEXT:    sh zero, 0(a0)
; FAST-NEXT:    ret
  store i8 0, ptr %p
  %p2 = getelementptr i8, ptr %p, i32 1
  store i8 0, ptr %p2
  ret void
}

define void @merge_stores_i8_i32(ptr %p) {
; SLOW-LABEL: merge_stores_i8_i32:
; SLOW:       # %bb.0:
; SLOW-NEXT:    sb zero, 0(a0)
; SLOW-NEXT:    sb zero, 1(a0)
; SLOW-NEXT:    sb zero, 2(a0)
; SLOW-NEXT:    sb zero, 3(a0)
; SLOW-NEXT:    ret
;
; FAST-LABEL: merge_stores_i8_i32:
; FAST:       # %bb.0:
; FAST-NEXT:    sw zero, 0(a0)
; FAST-NEXT:    ret
  store i8 0, ptr %p
  %p2 = getelementptr i8, ptr %p, i32 1
  store i8 0, ptr %p2
  %p3 = getelementptr i8, ptr %p, i32 2
  store i8 0, ptr %p3
  %p4 = getelementptr i8, ptr %p, i32 3
  store i8 0, ptr %p4
  ret void
}

define void @merge_stores_i8_i64(ptr %p) {
; SLOW-LABEL: merge_stores_i8_i64:
; SLOW:       # %bb.0:
; SLOW-NEXT:    sb zero, 0(a0)
; SLOW-NEXT:    sb zero, 1(a0)
; SLOW-NEXT:    sb zero, 2(a0)
; SLOW-NEXT:    sb zero, 3(a0)
; SLOW-NEXT:    sb zero, 4(a0)
; SLOW-NEXT:    sb zero, 5(a0)
; SLOW-NEXT:    sb zero, 6(a0)
; SLOW-NEXT:    sb zero, 7(a0)
; SLOW-NEXT:    ret
;
; RV32I-FAST-LABEL: merge_stores_i8_i64:
; RV32I-FAST:       # %bb.0:
; RV32I-FAST-NEXT:    sw zero, 0(a0)
; RV32I-FAST-NEXT:    sw zero, 4(a0)
; RV32I-FAST-NEXT:    ret
;
; RV64I-FAST-LABEL: merge_stores_i8_i64:
; RV64I-FAST:       # %bb.0:
; RV64I-FAST-NEXT:    sd zero, 0(a0)
; RV64I-FAST-NEXT:    ret
  store i8 0, ptr %p
  %p2 = getelementptr i8, ptr %p, i32 1
  store i8 0, ptr %p2
  %p3 = getelementptr i8, ptr %p, i32 2
  store i8 0, ptr %p3
  %p4 = getelementptr i8, ptr %p, i32 3
  store i8 0, ptr %p4
  %p5 = getelementptr i8, ptr %p, i32 4
  store i8 0, ptr %p5
  %p6 = getelementptr i8, ptr %p, i32 5
  store i8 0, ptr %p6
  %p7 = getelementptr i8, ptr %p, i32 6
  store i8 0, ptr %p7
  %p8 = getelementptr i8, ptr %p, i32 7
  store i8 0, ptr %p8
  ret void
}

define void @merge_stores_i16_i32(ptr %p) {
; SLOW-LABEL: merge_stores_i16_i32:
; SLOW:       # %bb.0:
; SLOW-NEXT:    sh zero, 0(a0)
; SLOW-NEXT:    sh zero, 2(a0)
; SLOW-NEXT:    ret
;
; FAST-LABEL: merge_stores_i16_i32:
; FAST:       # %bb.0:
; FAST-NEXT:    sw zero, 0(a0)
; FAST-NEXT:    ret
  store i16 0, ptr %p
  %p2 = getelementptr i16, ptr %p, i32 1
  store i16 0, ptr %p2
  ret void
}

define void @merge_stores_i16_i64(ptr %p) {
; SLOW-LABEL: merge_stores_i16_i64:
; SLOW:       # %bb.0:
; SLOW-NEXT:    sh zero, 0(a0)
; SLOW-NEXT:    sh zero, 2(a0)
; SLOW-NEXT:    sh zero, 4(a0)
; SLOW-NEXT:    sh zero, 6(a0)
; SLOW-NEXT:    ret
;
; RV32I-FAST-LABEL: merge_stores_i16_i64:
; RV32I-FAST:       # %bb.0:
; RV32I-FAST-NEXT:    sw zero, 0(a0)
; RV32I-FAST-NEXT:    sw zero, 4(a0)
; RV32I-FAST-NEXT:    ret
;
; RV64I-FAST-LABEL: merge_stores_i16_i64:
; RV64I-FAST:       # %bb.0:
; RV64I-FAST-NEXT:    sd zero, 0(a0)
; RV64I-FAST-NEXT:    ret
  store i16 0, ptr %p
  %p2 = getelementptr i16, ptr %p, i32 1
  store i16 0, ptr %p2
  %p3 = getelementptr i16, ptr %p, i32 2
  store i16 0, ptr %p3
  %p4 = getelementptr i16, ptr %p, i32 3
  store i16 0, ptr %p4
  ret void
}

define void @merge_stores_i32_i64(ptr %p) {
; SLOW-LABEL: merge_stores_i32_i64:
; SLOW:       # %bb.0:
; SLOW-NEXT:    sw zero, 0(a0)
; SLOW-NEXT:    sw zero, 4(a0)
; SLOW-NEXT:    ret
;
; RV32I-FAST-LABEL: merge_stores_i32_i64:
; RV32I-FAST:       # %bb.0:
; RV32I-FAST-NEXT:    sw zero, 0(a0)
; RV32I-FAST-NEXT:    sw zero, 4(a0)
; RV32I-FAST-NEXT:    ret
;
; RV64I-FAST-LABEL: merge_stores_i32_i64:
; RV64I-FAST:       # %bb.0:
; RV64I-FAST-NEXT:    sd zero, 0(a0)
; RV64I-FAST-NEXT:    ret
  store i32 0, ptr %p
  %p2 = getelementptr i32, ptr %p, i32 1
  store i32 0, ptr %p2
  ret void
}

define void @store_large_constant(ptr %x) {
; SLOW-LABEL: store_large_constant:
; SLOW:       # %bb.0:
; SLOW-NEXT:    li a1, -2
; SLOW-NEXT:    li a2, 220
; SLOW-NEXT:    li a3, 186
; SLOW-NEXT:    li a4, 152
; SLOW-NEXT:    li a5, 118
; SLOW-NEXT:    li a6, 84
; SLOW-NEXT:    li a7, 50
; SLOW-NEXT:    sb a4, 4(a0)
; SLOW-NEXT:    sb a3, 5(a0)
; SLOW-NEXT:    sb a2, 6(a0)
; SLOW-NEXT:    sb a1, 7(a0)
; SLOW-NEXT:    li a1, 16
; SLOW-NEXT:    sb a1, 0(a0)
; SLOW-NEXT:    sb a7, 1(a0)
; SLOW-NEXT:    sb a6, 2(a0)
; SLOW-NEXT:    sb a5, 3(a0)
; SLOW-NEXT:    ret
;
; RV32I-FAST-LABEL: store_large_constant:
; RV32I-FAST:       # %bb.0:
; RV32I-FAST-NEXT:    lui a1, 1043916
; RV32I-FAST-NEXT:    lui a2, 484675
; RV32I-FAST-NEXT:    addi a1, a1, -1384
; RV32I-FAST-NEXT:    addi a2, a2, 528
; RV32I-FAST-NEXT:    sw a2, 0(a0)
; RV32I-FAST-NEXT:    sw a1, 4(a0)
; RV32I-FAST-NEXT:    ret
;
; RV64I-FAST-LABEL: store_large_constant:
; RV64I-FAST:       # %bb.0:
; RV64I-FAST-NEXT:    lui a1, %hi(.LCPI16_0)
; RV64I-FAST-NEXT:    ld a1, %lo(.LCPI16_0)(a1)
; RV64I-FAST-NEXT:    sd a1, 0(a0)
; RV64I-FAST-NEXT:    ret
  store i64 18364758544493064720, ptr %x, align 1
  ret void
}
;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; SLOWZBKB: {{.*}}
