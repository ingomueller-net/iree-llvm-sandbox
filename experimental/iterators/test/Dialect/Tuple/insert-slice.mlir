// RUN: iterators-opt %s | iterators-opt | FileCheck %s

// CHECK-LABEL: func.func @insert_i32(
// CHECK-SAME:                        %[[ARG0:.*]]: tuple<i32>,
// CHECK-SAME:                        %[[ARG1:.*]]: tuple<i32>) -> tuple<i32> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.insert_slice %[[ARG1]] into %[[ARG0]] [0] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : tuple<i32>
func.func @insert_i32(%arg0 : tuple<i32>, %arg1 : tuple<i32>) -> tuple<i32> {
  %tuple = tuple.insert_slice %arg1 into %arg0 [0] : tuple<i32>
  return %tuple : tuple<i32>
}

// CHECK-LABEL: func.func @insert_reverse(
// CHECK-SAME:                            %[[ARG0:.*]]: tuple<i32, i64>,
// CHECK-SAME:                            %[[ARG1:.*]]: tuple<i64, i32>) -> tuple<i32, i64> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.insert_slice %[[ARG1]] into %[[ARG0]] [1, 0] : tuple<i32, i64>
// CHECK-NEXT:    return %[[V0]] : tuple<i32, i64>
func.func @insert_reverse(%arg0 : tuple<i32, i64>, %arg1 : tuple<i64, i32>) -> tuple<i32, i64> {
  %tuple = tuple.insert_slice %arg1 into %arg0 [1, 0] : tuple<i32, i64>
  return %tuple : tuple<i32, i64>
}

// CHECK-LABEL: func.func @insert_empty(
// CHECK-SAME:                          %[[ARG0:.*]]: tuple<i32>,
// CHECK-SAME:                          %[[ARG1:.*]]: tuple<>) -> tuple<i32> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.insert_slice %[[ARG1]] into %[[ARG0]] [] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : tuple<i32>
func.func @insert_empty(%arg0 : tuple<i32>, %arg1 : tuple<>) -> tuple<i32> {
  %tuple = tuple.insert_slice %arg1 into %arg0 [] : tuple<i32>
  return %tuple : tuple<i32>
}
