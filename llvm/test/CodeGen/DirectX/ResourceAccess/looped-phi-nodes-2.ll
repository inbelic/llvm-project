; RUN: opt -S -dxil-resource-type -dxil-resource-access -mtriple=dxil-pc-shadermodel6.3-library %s | FileCheck %s

; Ensure that an updatecounter on a cyclic loop of resource handles over
; different global resources is legalized by switching on a cyclic phi of which
; resource is accessed. bufB is id 0 and bufA is id 1.

; CHECK-LABEL: define i32 @updatecounter_loop(
; CHECK:      loop:
; CHECK-NEXT:   phi i32 [ 0, %entry ]
; CHECK-NEXT:   %[[DSTSEL:[^ ]+]] = phi i32 [ 0, %entry ], [ %[[SRCSEL:[^,]+]], %[[END:[^ ]+]] ]
; CHECK-NEXT:   phi i32 [ 0, %entry ]
; CHECK-NEXT:   %[[SRCSEL]] = phi i32 [ 1, %entry ], [ %[[DSTSEL]], %[[END]] ]
; CHECK-NOT:    phi target(
; CHECK:        switch i32 %[[SRCSEL]], label %[[CASEA:.*]] [
; CHECK-NEXT:     i32 0, label %[[CASEB:.*]]
; CHECK-NEXT:   ]
; CHECK:      [[CASEB]]:
; CHECK-NEXT:   %[[HB:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 %{{.*}}, ptr nonnull @.str.2)
; CHECK-NEXT:   %[[CB:.*]] = call i32 @llvm.dx.resource.updatecounter.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %[[HB]], i8 1)
; CHECK:      [[CASEA]]:
; CHECK-NEXT:   %[[HA:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 0, i32 1, i32 %{{.*}}, ptr nonnull @.str)
; CHECK-NEXT:   %[[CA:.*]] = call i32 @llvm.dx.resource.updatecounter.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %[[HA]], i8 1)
; CHECK:      [[END]]:
; CHECK-NEXT:   %[[C:.*]] = phi i32 [ %[[CB]], %[[CASEB]] ], [ %[[CA]], %[[CASEA]] ]
; CHECK:        ret i32 %[[C]]

@.str = private unnamed_addr constant [5 x i8] c"bufA\00", align 1
@.str.2 = private unnamed_addr constant [5 x i8] c"bufB\00", align 1

define i32 @updatecounter_loop(i32 %n) {
entry:
  %handle0 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
  %handle1 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
  br label %loop

loop:
  %dst = phi target("dx.RawBuffer", i32, 1, 0) [ %handle1, %entry ], [ %src, %loop ]
  %src = phi target("dx.RawBuffer", i32, 1, 0) [ %handle0, %entry ], [ %dst, %loop ]
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %count = call i32 @llvm.dx.resource.updatecounter.tdx.RawBuffer_i32_1_0t(target("dx.RawBuffer", i32, 1, 0) %src, i8 1)
  %inc = add nuw i32 %i, 1
  %exit = icmp eq i32 %inc, %n
  br i1 %exit, label %end, label %loop

end:
  ret i32 %count
}
