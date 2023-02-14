// RUN: iterators-opt %s | iterators-opt | FileCheck %s

// CHECK-LABEL: func.func @concat_i32f32(
// CHECK-SAME:                           %[[ARG0:.*]]: tuple<i32>,
// CHECK-SAME:                           %[[ARG1:.*]]: tuple<f32>) -> tuple<i32, f32> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.concat %[[ARG0]] + %[[ARG1]] : tuple<i32> + tuple<f32>
func.func @concat_i32f32(%lhs : tuple<i32>, %rhs : tuple<f32>) -> tuple<i32, f32> {
  %tuple = tuple.concat %lhs + %rhs : tuple<i32> + tuple<f32>
  return %tuple : tuple<i32, f32>
}

// CHECK-LABEL: func.func @concat_empty_lhs(
// CHECK-SAME:                              %[[ARG0:.*]]: tuple<>,
// CHECK-SAME:                              %[[ARG1:.*]]: tuple<f32>) -> tuple<f32> {
func.func @concat_empty_lhs(%lhs : tuple<>, %rhs : tuple<f32>) -> tuple<f32> {
  %tuple = tuple.concat %lhs + %rhs : tuple<> + tuple<f32>
  return %tuple : tuple<f32>
}

// CHECK-LABEL: func.func @concat_empty_rhs(
// CHECK-SAME:                              %[[ARG0:.*]]: tuple<i32>,
// CHECK-SAME:                              %[[ARG1:.*]]: tuple<>) -> tuple<i32> {
func.func @concat_empty_rhs(%lhs : tuple<i32>, %rhs : tuple<>) -> tuple<i32> {
  %tuple = tuple.concat %lhs + %rhs : tuple<i32> + tuple<>
  return %tuple : tuple<i32>
}
