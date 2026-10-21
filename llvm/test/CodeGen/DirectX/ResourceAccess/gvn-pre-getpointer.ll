; RUN: opt -passes=gvn -S %s \
; RUN:   | opt -S -dxil-resource-type -dxil-resource-access \
; RUN:     -mtriple=dxil-pc-shadermodel6.3-library | FileCheck %s

; GVN's PRE is free to merge the dx.resource.getpointer calls of the branches
; into a phi of resource pointers in the common successor. Ensure that
; dxil-resource-access legalizes this, and that the convergent wave operations
; are not moved.
;
; NOTE: The following ir represents case F and G from:
; https://godbolt.org/z/cK4xh1P49.

; CHECK-LABEL: define void @main(
; CHECK-NOT:     phi ptr
; CHECK:       if.then.i:
; CHECK:         %[[SUM:.*]] = tail call i32 @llvm.dx.wave.reduce.sum.i32(
; CHECK-NEXT:    call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %{{.*}}, i32 %[[TID:.*]], i32 0, i32 %[[SUM]])
; CHECK:       if.else.i:
; CHECK:         call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %{{.*}}, i32 0, i32 0, i32 %{{.*}})
; CHECK:       main.exit:
; CHECK-NEXT:    %[[OUT0:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
; CHECK-NEXT:    %[[IN:.*]] = tail call {{.*}} @llvm.dx.resource.handlefrombinding.tdx.TypedBuffer_i32_1_0_1t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
; CHECK-NEXT:    %[[LD:.*]] = call { i32, i1 } @llvm.dx.resource.load.typedbuffer.i32.tdx.TypedBuffer_i32_1_0_1t(target("dx.TypedBuffer", i32, 1, 0, 1) %[[IN]], i32 %[[TID]])
; CHECK-NEXT:    %[[V:.*]] = extractvalue { i32, i1 } %[[LD]], 0
; CHECK-NEXT:    %[[SUM2:.*]] = tail call i32 @llvm.dx.wave.reduce.sum.i32(i32 %[[V]])
; CHECK-NEXT:    call void @llvm.dx.resource.store.rawbuffer.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %[[OUT0]], i32 %[[TID]], i32 0, i32 %[[SUM2]])
; CHECK-NEXT:    ret void

%"class.hlsl::RWBuffer" = type { target("dx.TypedBuffer", i32, 1, 0, 1) }
%"class.hlsl::RWStructuredBuffer" = type { target("dx.RawBuffer", i32, 1, 0), target("dx.RawBuffer", i32, 1, 0) }
%__cblayout_c = type <{ i32 }>

@In = internal global %"class.hlsl::RWBuffer" poison, align 4
@.str = private unnamed_addr constant [3 x i8] c"In\00", align 1
@Out0 = internal global %"class.hlsl::RWStructuredBuffer" poison, align 4
@.str.2 = private unnamed_addr constant [5 x i8] c"Out0\00", align 1
@Out1 = internal global %"class.hlsl::RWStructuredBuffer" poison, align 4
@.str.4 = private unnamed_addr constant [5 x i8] c"Out1\00", align 1
@c.cb = local_unnamed_addr global target("dx.CBuffer", %__cblayout_c) poison
@cond = external hidden local_unnamed_addr addrspace(2) global i32, align 4
@c.str = private unnamed_addr constant [2 x i8] c"c\00", align 1

define void @main() local_unnamed_addr {
entry:
  %0 = tail call target("dx.TypedBuffer", i32, 1, 0, 1) @llvm.dx.resource.handlefrombinding.tdx.TypedBuffer_i32_1_0_1t(i32 0, i32 0, i32 1, i32 0, ptr nonnull @.str)
  store target("dx.TypedBuffer", i32, 1, 0, 1) %0, ptr @In, align 4
  %1 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 1, i32 1, i32 0, ptr nonnull @.str.2)
  store target("dx.RawBuffer", i32, 1, 0) %1, ptr @Out0, align 4
  store target("dx.RawBuffer", i32, 1, 0) %1, ptr getelementptr inbounds nuw (i8, ptr @Out0, i32 4), align 4
  %2 = tail call target("dx.RawBuffer", i32, 1, 0) @llvm.dx.resource.handlefrombinding.tdx.RawBuffer_i32_1_0t(i32 0, i32 2, i32 1, i32 0, ptr nonnull @.str.4)
  store target("dx.RawBuffer", i32, 1, 0) %2, ptr @Out1, align 4
  store target("dx.RawBuffer", i32, 1, 0) %2, ptr getelementptr inbounds nuw (i8, ptr @Out1, i32 4), align 4
  %c.cb_h.i.i = tail call target("dx.CBuffer", %__cblayout_c) @llvm.dx.resource.handlefromimplicitbinding.tdx.CBuffer_s___cblayout_cst(i32 4, i32 0, i32 1, i32 0, ptr nonnull @c.str)
  store target("dx.CBuffer", %__cblayout_c) %c.cb_h.i.i, ptr @c.cb, align 4
  %3 = tail call i32 @llvm.dx.flattened.thread.id.in.group()
  %4 = load i32, ptr addrspace(2) @cond, align 4
  %loadedv.i = trunc nuw i32 %4 to i1
  br i1 %loadedv.i, label %if.then.i, label %if.else.i

if.then.i:                                        ; preds = %entry
  %5 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.TypedBuffer_i32_1_0_1t.i32(target("dx.TypedBuffer", i32, 1, 0, 1) %0, i32 %3)
  %6 = load i32, ptr %5, align 4
  %hlsl.wave.active.sum.i = tail call i32 @llvm.dx.wave.reduce.sum.i32(i32 %6)
  %7 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %1, i32 %3)
  store i32 %hlsl.wave.active.sum.i, ptr %7, align 4
  br label %main.exit

if.else.i:                                        ; preds = %entry
  %8 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.TypedBuffer_i32_1_0_1t.i32(target("dx.TypedBuffer", i32, 1, 0, 1) %0, i32 %3)
  %9 = load i32, ptr %8, align 4
  %10 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %1, i32 0)
  store i32 %9, ptr %10, align 4
  br label %main.exit

main.exit:                                    ; preds = %if.then.i, %if.else.i
  %11 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.TypedBuffer_i32_1_0_1t.i32(target("dx.TypedBuffer", i32, 1, 0, 1) %0, i32 %3)
  %12 = load i32, ptr %11, align 4
  %hlsl.wave.active.sum5.i = tail call i32 @llvm.dx.wave.reduce.sum.i32(i32 %12)
  %13 = tail call noundef nonnull align 4 dereferenceable(4) ptr @llvm.dx.resource.getpointer.p0.tdx.RawBuffer_i32_1_0t.i32(target("dx.RawBuffer", i32, 1, 0) %1, i32 %3)
  store i32 %hlsl.wave.active.sum5.i, ptr %13, align 4
  ret void
}
