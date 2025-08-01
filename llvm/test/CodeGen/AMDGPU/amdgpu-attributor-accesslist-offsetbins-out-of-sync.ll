; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; RUN: opt -S -mtriple=amdgcn-amd-amdhsa -passes='amdgpu-attributor' %s -o - | FileCheck %s

%struct.ShaderClosure = type { <3 x float>, i32, float, <3 x float>, [10 x float], [8 x i8] }
%struct.ShaderData = type { <3 x float>, <3 x float>, <3 x float>, <3 x float>, i32, i32, i32, i32, i32, float, float, i32, i32, float, float, %struct.differential3, %struct.differential3, %struct.differential, %struct.differential, <3 x float>, <3 x float>, <3 x float>, %struct.differential3, i32, i32, i32, float, <3 x float>, <3 x float>, <3 x float>, [64 x %struct.ShaderClosure] }
%struct.differential = type { float, float }
%struct.differential3 = type { <3 x float>, <3 x float> }

define internal fastcc void @foo(ptr %kg) {
; CHECK-LABEL: define internal fastcc void @foo(
; CHECK-SAME: ptr [[KG:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  [[ENTRY:.*:]]
; CHECK-NEXT:    [[CLOSURE_I25_I:%.*]] = getelementptr i8, ptr [[KG]], i64 336
; CHECK-NEXT:    [[NUM_CLOSURE_I26_I:%.*]] = getelementptr i8, ptr [[KG]], i64 276
; CHECK-NEXT:    br label %[[WHILE_COND:.*]]
; CHECK:       [[WHILE_COND]]:
; CHECK-NEXT:    [[TMP0:%.*]] = addrspacecast ptr [[KG]] to ptr addrspace(5)
; CHECK-NEXT:    [[TMP1:%.*]] = load i32, ptr addrspace(5) [[TMP0]], align 4, !noalias.addrspace [[META0:![0-9]+]]
; CHECK-NEXT:    [[IDXPROM_I:%.*]] = zext i32 [[TMP1]] to i64
; CHECK-NEXT:    switch i32 0, label %[[SW_BB92:.*]] [
; CHECK-NEXT:      i32 1, label %[[SW_BB92]]
; CHECK-NEXT:      i32 0, label %[[SUBD_TRIANGLE_PATCH_EXIT_I_I35:.*]]
; CHECK-NEXT:    ]
; CHECK:       [[SUBD_TRIANGLE_PATCH_EXIT_I_I35]]:
; CHECK-NEXT:    [[ARRAYIDX_I27_I:%.*]] = getelementptr float, ptr [[KG]], i64 [[IDXPROM_I]]
; CHECK-NEXT:    [[TMP2:%.*]] = addrspacecast ptr [[ARRAYIDX_I27_I]] to ptr addrspace(5)
; CHECK-NEXT:    store float 0.000000e+00, ptr addrspace(5) [[TMP2]], align 4, !noalias.addrspace [[META0]]
; CHECK-NEXT:    br label %[[WHILE_COND]]
; CHECK:       [[SW_BB92]]:
; CHECK-NEXT:    [[INSERT:%.*]] = insertelement <3 x i32> zeroinitializer, i32 [[TMP1]], i64 0
; CHECK-NEXT:    [[SPLAT_SPLATINSERT_I:%.*]] = bitcast <3 x i32> [[INSERT]] to <3 x float>
; CHECK-NEXT:    [[SHFL:%.*]] = shufflevector <3 x float> [[SPLAT_SPLATINSERT_I]], <3 x float> zeroinitializer, <4 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP3:%.*]] = addrspacecast ptr [[NUM_CLOSURE_I26_I]] to ptr addrspace(5)
; CHECK-NEXT:    [[LOAD:%.*]] = load i32, ptr addrspace(5) [[TMP3]], align 4, !noalias.addrspace [[META0]]
; CHECK-NEXT:    [[IDXPROM_I27_I:%.*]] = sext i32 [[LOAD]] to i64
; CHECK-NEXT:    [[ARRAYIDX_I28_I:%.*]] = getelementptr [64 x %struct.ShaderClosure], ptr [[CLOSURE_I25_I]], i64 0, i64 [[IDXPROM_I27_I]]
; CHECK-NEXT:    [[TMP4:%.*]] = addrspacecast ptr [[ARRAYIDX_I28_I]] to ptr addrspace(5)
; CHECK-NEXT:    store <4 x float> [[SHFL]], ptr addrspace(5) [[TMP4]], align 16, !noalias.addrspace [[META0]]
; CHECK-NEXT:    [[INC_I30_I:%.*]] = or i32 [[LOAD]], 1
; CHECK-NEXT:    [[TMP5:%.*]] = addrspacecast ptr [[NUM_CLOSURE_I26_I]] to ptr addrspace(5)
; CHECK-NEXT:    store i32 [[INC_I30_I]], ptr addrspace(5) [[TMP5]], align 4, !noalias.addrspace [[META0]]
; CHECK-NEXT:    br label %[[WHILE_COND]]
;
entry:
  %closure.i25.i = getelementptr i8, ptr %kg, i64 336
  %num_closure.i26.i = getelementptr i8, ptr %kg, i64 276
  br label %while.cond

while.cond:
  %load = load i32, ptr %kg, align 4
  %idxprom.i = zext i32 %load to i64
  switch i32 0, label %sw.bb92 [
  i32 1, label %sw.bb92
  i32 0, label %subd_triangle_patch.exit.i.i35
  ]

subd_triangle_patch.exit.i.i35:
  %arrayidx.i27.i = getelementptr float, ptr %kg, i64 %idxprom.i
  store float 0.000000e+00, ptr %arrayidx.i27.i, align 4
  br label %while.cond

sw.bb92:
  %insert = insertelement <3 x i32> zeroinitializer, i32 %load, i64 0
  %splat.splatinsert.i = bitcast <3 x i32> %insert to <3 x float>
  %shfl = shufflevector <3 x float> %splat.splatinsert.i, <3 x float> zeroinitializer, <4 x i32> zeroinitializer
  %load.1 = load i32, ptr %num_closure.i26.i, align 4
  %idxprom.i27.i = sext i32 %load.1 to i64
  %arrayidx.i28.i = getelementptr [64 x %struct.ShaderClosure], ptr %closure.i25.i, i64 0, i64 %idxprom.i27.i
  store <4 x float> %shfl, ptr %arrayidx.i28.i, align 16
  %inc.i30.i = or i32 %load.1, 1
  store i32 %inc.i30.i, ptr %num_closure.i26.i, align 4
  br label %while.cond
}

define amdgpu_kernel void @kernel() #0 {
; CHECK-LABEL: define amdgpu_kernel void @kernel(
; CHECK-SAME: ) #[[ATTR1:[0-9]+]] {
; CHECK-NEXT:  [[ENTRY:.*:]]
; CHECK-NEXT:    [[SD:%.*]] = alloca [[STRUCT_SHADERDATA:%.*]], align 16, addrspace(5)
; CHECK-NEXT:    [[KGLOBALS_ASCAST1:%.*]] = addrspacecast ptr addrspace(5) [[SD]] to ptr
; CHECK-NEXT:    [[NUM_CLOSURE_I_I:%.*]] = getelementptr i8, ptr addrspace(5) [[SD]], i32 276
; CHECK-NEXT:    store <2 x i32> zeroinitializer, ptr addrspace(5) [[NUM_CLOSURE_I_I]], align 4
; CHECK-NEXT:    call fastcc void @foo(ptr [[KGLOBALS_ASCAST1]])
; CHECK-NEXT:    ret void
;
entry:
  %sd = alloca %struct.ShaderData, align 16, addrspace(5)
  %kglobals.ascast1 = addrspacecast ptr addrspace(5) %sd to ptr
  %num_closure.i.i = getelementptr i8, ptr addrspace(5) %sd, i32 276
  store <2 x i32> zeroinitializer, ptr addrspace(5) %num_closure.i.i, align 4
  call fastcc void @foo(ptr %kglobals.ascast1)
  ret void
}

attributes #0 = { norecurse }
;.
; CHECK: [[META0]] = !{i32 1, i32 5, i32 6, i32 10}
;.
