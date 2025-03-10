// RUN: structured-opt %s -split-input-file \
// RUN:   -convert-triton-spmd-to-func-args \
// RUN: | FileCheck %s

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: i32, %[[ARG1:.*]]: i32, %[[ARG2:.*]]: i32, %[[ARG3:.*]]: i32, %[[ARG4:.*]]: i32, %[[ARG5:.*]]: i32) -> i32
// CHECK-NEXT:    return %[[ARG3]] : i32
func.func public @kernel() -> i32 {
  %0 = tt.get_num_programs {axis = 0 : i32} : i32
  return %0 : i32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: i32, %[[ARG1:.*]]: i32, %[[ARG2:.*]]: i32, %[[ARG3:.*]]: i32, %[[ARG4:.*]]: i32, %[[ARG5:.*]]: i32) -> i32
// CHECK-NEXT:    return %[[ARG4]] : i32
func.func public @kernel() -> i32 {
  %0 = tt.get_num_programs {axis = 1 : i32} : i32
  return %0 : i32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: i32, %[[ARG1:.*]]: i32, %[[ARG2:.*]]: i32, %[[ARG3:.*]]: i32, %[[ARG4:.*]]: i32, %[[ARG5:.*]]: i32) -> i32
// CHECK-NEXT:    return %[[ARG5]] : i32
func.func public @kernel() -> i32 {
  %0 = tt.get_num_programs {axis = 2 : i32} : i32
  return %0 : i32
}
