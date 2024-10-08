; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --check-attributes --check-globals
; RUN: opt < %s -passes='simplifycfg<hoist-common-insts>' -simplifycfg-require-and-preserve-domtree=1 -S | FileCheck %s

declare ptr @foo(ptr %p, i64 %x)
declare ptr @foo2(ptr %p, ptr %p2, i64 %x)
declare void @side.effect()

define ptr @test_hoist_int_attrs(i1 %c, ptr %p, ptr %p2, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_int_attrs
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], ptr [[P2:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    [[R:%.*]] = call ptr @foo2(ptr align 32 dereferenceable_or_null(100) [[P]], ptr align 32 dereferenceable(50) [[P2]], i64 range(i64 10, 100000) [[X]]) #[[ATTR0:[0-9]+]]
; CHECK-NEXT:    br i1 [[C]], label [[COMMON_RET:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    ret ptr [[R]]
; CHECK:       else:
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call ptr @foo2(ptr align 64 dereferenceable_or_null(100) %p, ptr dereferenceable(50) align 64 %p2, i64 range(i64 10, 1000) %x) memory(read)
  ret ptr %r

else:
  %r2 = call ptr @foo2(ptr align 32 dereferenceable_or_null(200) %p, ptr dereferenceable(100) align 32 %p2, i64 range(i64 10000, 100000) %x) memory(write)
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_int_attrs2(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_int_attrs2
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    [[R:%.*]] = call ptr @foo(ptr dereferenceable(50) [[P]], i64 range(i64 10, 1000) [[X]]) #[[ATTR1:[0-9]+]]
; CHECK-NEXT:    br i1 [[C]], label [[COMMON_RET:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    ret ptr [[R]]
; CHECK:       else:
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call ptr @foo(ptr dereferenceable(50) %p, i64 range(i64 10, 1000) %x) memory(read)
  ret ptr %r

else:
  %r2 = call ptr @foo(ptr dereferenceable(100) align 32 dereferenceable_or_null(200) %p, i64 range(i64 11, 100) %x) memory(none)
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_bool_attrs2(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_bool_attrs2
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    [[R:%.*]] = call noundef ptr @foo(ptr nonnull [[P]], i64 noundef [[X]]) #[[ATTR2:[0-9]+]]
; CHECK-NEXT:    br i1 [[C]], label [[COMMON_RET:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    ret ptr [[R]]
; CHECK:       else:
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call noundef ptr @foo(ptr readnone nonnull noundef %p, i64 noundef %x) cold mustprogress nocallback nofree nosync willreturn
  ret ptr %r

else:
  %r2 = call noundef nonnull ptr @foo(ptr readonly nonnull %p, i64 noundef %x) mustprogress nocallback nofree willreturn
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_bool_attrs3(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_bool_attrs3
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    [[R:%.*]] = call nonnull ptr @foo(ptr [[P]], i64 noundef [[X]]) #[[ATTR3:[0-9]+]]
; CHECK-NEXT:    br i1 [[C]], label [[COMMON_RET:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    ret ptr [[R]]
; CHECK:       else:
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call nonnull ptr @foo(ptr readonly noundef %p, i64 noundef %x) cold nocallback nofree nosync willreturn alwaysinline
  ret ptr %r

else:
  %r2 = call noundef nonnull ptr @foo(ptr writeonly nonnull %p, i64 noundef %x) nosync willreturn alwaysinline
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_bool_attrs_fail_non_droppable(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_bool_attrs_fail_non_droppable
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    br i1 [[C]], label [[IF:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    [[COMMON_RET_OP:%.*]] = phi ptr [ [[R:%.*]], [[IF]] ], [ [[R2:%.*]], [[ELSE]] ]
; CHECK-NEXT:    ret ptr [[COMMON_RET_OP]]
; CHECK:       if:
; CHECK-NEXT:    [[R]] = call nonnull ptr @foo(ptr noundef readonly [[P]], i64 noundef [[X]]) #[[ATTR4:[0-9]+]]
; CHECK-NEXT:    br label [[COMMON_RET:%.*]]
; CHECK:       else:
; CHECK-NEXT:    [[R2]] = call noundef nonnull ptr @foo(ptr nonnull writeonly [[P]], i64 noundef [[X]]) #[[ATTR5:[0-9]+]]
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call nonnull ptr @foo(ptr readonly noundef %p, i64 noundef %x) cold nocallback nofree nosync willreturn alwaysinline
  ret ptr %r

else:
  %r2 = call noundef nonnull ptr @foo(ptr writeonly nonnull %p, i64 noundef %x) nosync willreturn
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_bool_attrs_fail_non_droppable2(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_bool_attrs_fail_non_droppable2
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    br i1 [[C]], label [[IF:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    [[COMMON_RET_OP:%.*]] = phi ptr [ [[R:%.*]], [[IF]] ], [ [[R2:%.*]], [[ELSE]] ]
; CHECK-NEXT:    ret ptr [[COMMON_RET_OP]]
; CHECK:       if:
; CHECK-NEXT:    [[R]] = call nonnull ptr @foo(ptr noundef readonly [[P]], i64 noundef [[X]]) #[[ATTR6:[0-9]+]]
; CHECK-NEXT:    br label [[COMMON_RET:%.*]]
; CHECK:       else:
; CHECK-NEXT:    [[R2]] = call noundef nonnull ptr @foo(ptr nonnull writeonly byval(i64) [[P]], i64 noundef [[X]]) #[[ATTR5]]
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call nonnull ptr @foo(ptr readonly noundef %p, i64 noundef %x) cold nocallback nofree nosync willreturn
  ret ptr %r

else:
  %r2 = call noundef nonnull ptr @foo(ptr byval(i64) writeonly nonnull %p, i64 noundef %x) nosync willreturn
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_bool_attrs_fail_non_droppable3(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_bool_attrs_fail_non_droppable3
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    br i1 [[C]], label [[IF:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    [[COMMON_RET_OP:%.*]] = phi ptr [ [[R:%.*]], [[IF]] ], [ [[R2:%.*]], [[ELSE]] ]
; CHECK-NEXT:    ret ptr [[COMMON_RET_OP]]
; CHECK:       if:
; CHECK-NEXT:    [[R]] = call nonnull ptr @foo(ptr noundef readonly byval(i32) [[P]], i64 noundef [[X]]) #[[ATTR6]]
; CHECK-NEXT:    br label [[COMMON_RET:%.*]]
; CHECK:       else:
; CHECK-NEXT:    [[R2]] = call noundef nonnull ptr @foo(ptr nonnull writeonly byval(i64) [[P]], i64 noundef [[X]]) #[[ATTR5]]
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call nonnull ptr @foo(ptr byval(i32) readonly noundef %p, i64 noundef %x) cold nocallback nofree nosync willreturn
  ret ptr %r

else:
  %r2 = call noundef nonnull ptr @foo(ptr byval(i64) writeonly nonnull %p, i64 noundef %x) nosync willreturn
  call void @side.effect()
  ret ptr %r2
}

define ptr @test_hoist_bool_attrs4(i1 %c, ptr %p, i64 %x) {
; CHECK-LABEL: define {{[^@]+}}@test_hoist_bool_attrs4
; CHECK-SAME: (i1 [[C:%.*]], ptr [[P:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:    [[R:%.*]] = call nonnull ptr @foo(ptr byval(i64) [[P]], i64 noundef [[X]]) #[[ATTR5]]
; CHECK-NEXT:    br i1 [[C]], label [[COMMON_RET:%.*]], label [[ELSE:%.*]]
; CHECK:       common.ret:
; CHECK-NEXT:    ret ptr [[R]]
; CHECK:       else:
; CHECK-NEXT:    call void @side.effect()
; CHECK-NEXT:    br label [[COMMON_RET]]
;
  br i1 %c, label %if, label %else
if:
  %r = call nonnull ptr @foo(ptr byval(i64) readonly noundef %p, i64 noundef %x) cold nocallback nofree nosync willreturn
  ret ptr %r

else:
  %r2 = call noundef nonnull ptr @foo(ptr byval(i64) writeonly nonnull %p, i64 noundef %x) nosync willreturn
  call void @side.effect()
  ret ptr %r2
}

;.
; CHECK: attributes #[[ATTR0]] = { memory(readwrite) }
; CHECK: attributes #[[ATTR1]] = { memory(read) }
; CHECK: attributes #[[ATTR2]] = { mustprogress nocallback nofree willreturn }
; CHECK: attributes #[[ATTR3]] = { alwaysinline nosync willreturn }
; CHECK: attributes #[[ATTR4]] = { alwaysinline cold nocallback nofree nosync willreturn }
; CHECK: attributes #[[ATTR5]] = { nosync willreturn }
; CHECK: attributes #[[ATTR6]] = { cold nocallback nofree nosync willreturn }
;.
