// NOTE: Assertions have been autogenerated by utils/update_cc_test_checks.py UTC_ARGS: --version 2
// REQUIRES: riscv-registered-target
// RUN: %clang_cc1 -triple riscv64 -target-feature +v -target-feature +zfh \
// RUN:   -target-feature +zvfh -disable-O0-optnone  \
// RUN:   -emit-llvm %s -o - | opt -S -passes=mem2reg | \
// RUN:   FileCheck --check-prefix=CHECK-RV64 %s

#include <riscv_vector.h>

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_f64m1x5_tu
// CHECK-RV64-SAME: (target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0:[0-9]+]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.triscv.vector.tuple_nxv8i8_5t.p0.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], i64 [[VL]], i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vfloat64m1x5_t test_vlseg5e64_v_f64m1x5_tu(vfloat64m1x5_t maskedoff_tuple, const double *base, size_t vl) {
  return __riscv_vlseg5e64_v_f64m1x5_tu(maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_i64m1x5_tu
// CHECK-RV64-SAME: (target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.triscv.vector.tuple_nxv8i8_5t.p0.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], i64 [[VL]], i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vint64m1x5_t test_vlseg5e64_v_i64m1x5_tu(vint64m1x5_t maskedoff_tuple, const int64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_i64m1x5_tu(maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_u64m1x5_tu
// CHECK-RV64-SAME: (target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.triscv.vector.tuple_nxv8i8_5t.p0.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], i64 [[VL]], i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vuint64m1x5_t test_vlseg5e64_v_u64m1x5_tu(vuint64m1x5_t maskedoff_tuple, const uint64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_u64m1x5_tu(maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_f64m1x5_tum
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 2, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vfloat64m1x5_t test_vlseg5e64_v_f64m1x5_tum(vbool64_t mask, vfloat64m1x5_t maskedoff_tuple, const double *base, size_t vl) {
  return __riscv_vlseg5e64_v_f64m1x5_tum(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_i64m1x5_tum
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 2, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vint64m1x5_t test_vlseg5e64_v_i64m1x5_tum(vbool64_t mask, vint64m1x5_t maskedoff_tuple, const int64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_i64m1x5_tum(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_u64m1x5_tum
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 2, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vuint64m1x5_t test_vlseg5e64_v_u64m1x5_tum(vbool64_t mask, vuint64m1x5_t maskedoff_tuple, const uint64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_u64m1x5_tum(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_f64m1x5_tumu
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 0, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vfloat64m1x5_t test_vlseg5e64_v_f64m1x5_tumu(vbool64_t mask, vfloat64m1x5_t maskedoff_tuple, const double *base, size_t vl) {
  return __riscv_vlseg5e64_v_f64m1x5_tumu(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_i64m1x5_tumu
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 0, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vint64m1x5_t test_vlseg5e64_v_i64m1x5_tumu(vbool64_t mask, vint64m1x5_t maskedoff_tuple, const int64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_i64m1x5_tumu(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_u64m1x5_tumu
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 0, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vuint64m1x5_t test_vlseg5e64_v_u64m1x5_tumu(vbool64_t mask, vuint64m1x5_t maskedoff_tuple, const uint64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_u64m1x5_tumu(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_f64m1x5_mu
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 1, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vfloat64m1x5_t test_vlseg5e64_v_f64m1x5_mu(vbool64_t mask, vfloat64m1x5_t maskedoff_tuple, const double *base, size_t vl) {
  return __riscv_vlseg5e64_v_f64m1x5_mu(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_i64m1x5_mu
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 1, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vint64m1x5_t test_vlseg5e64_v_i64m1x5_mu(vbool64_t mask, vint64m1x5_t maskedoff_tuple, const int64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_i64m1x5_mu(mask, maskedoff_tuple, base, vl);
}

// CHECK-RV64-LABEL: define dso_local target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @test_vlseg5e64_v_u64m1x5_mu
// CHECK-RV64-SAME: (<vscale x 1 x i1> [[MASK:%.*]], target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE:%.*]], ptr noundef [[BASE:%.*]], i64 noundef [[VL:%.*]]) #[[ATTR0]] {
// CHECK-RV64-NEXT:  entry:
// CHECK-RV64-NEXT:    [[TMP0:%.*]] = call target("riscv.vector.tuple", <vscale x 8 x i8>, 5) @llvm.riscv.vlseg5.mask.triscv.vector.tuple_nxv8i8_5t.p0.nxv1i1.i64(target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[MASKEDOFF_TUPLE]], ptr [[BASE]], <vscale x 1 x i1> [[MASK]], i64 [[VL]], i64 1, i64 6)
// CHECK-RV64-NEXT:    ret target("riscv.vector.tuple", <vscale x 8 x i8>, 5) [[TMP0]]
//
vuint64m1x5_t test_vlseg5e64_v_u64m1x5_mu(vbool64_t mask, vuint64m1x5_t maskedoff_tuple, const uint64_t *base, size_t vl) {
  return __riscv_vlseg5e64_v_u64m1x5_mu(mask, maskedoff_tuple, base, vl);
}

