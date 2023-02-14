// RUN: iterators-opt %s | iterators-opt | FileCheck %s

// CHECK-LABEL: func.func @extract_i32(
// CHECK-SAME:                         %[[ARG0:.*]]: tuple<i32>) -> tuple<i32> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.extract_slice %[[ARG0]] [0] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : tuple<i32>
func.func @extract_i32(%arg0 : tuple<i32>) -> tuple<i32> {
  %tuple = tuple.extract_slice %arg0 [0] : tuple<i32>
  return %tuple : tuple<i32>
}

// CHECK-LABEL: func.func @extract_expand(
// CHECK-SAME:                            %[[ARG0:.*]]: tuple<i32>) -> tuple<i32, i32> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.extract_slice %[[ARG0]] [0, 0] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : tuple<i32, i32>
func.func @extract_expand(%arg0 : tuple<i32>) -> tuple<i32, i32> {
  %tuple = tuple.extract_slice %arg0 [0, 0] : tuple<i32>
  return %tuple : tuple<i32, i32>
}

// CHECK-LABEL: func.func @extract_empty(
// CHECK-SAME:                           %[[ARG0:.*]]: tuple<i32>) -> tuple<> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.extract_slice %[[ARG0]] [] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : tuple<>
func.func @extract_empty(%arg0 : tuple<i32>) -> tuple<> {
  %tuple = tuple.extract_slice %arg0 [] : tuple<i32>
  return %tuple : tuple<>
}
