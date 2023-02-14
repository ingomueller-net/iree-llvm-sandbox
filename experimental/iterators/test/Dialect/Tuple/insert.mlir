// RUN: iterators-opt %s | iterators-opt | FileCheck %s

// CHECK-LABEL: func.func @insert(
// CHECK-SAME:                     %[[ARG0:.*]]: tuple<i32>,
// CHECK-SAME:                     %[[ARG1:.*]]: i32) -> tuple<i32> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.insert %[[ARG1]] into %[[ARG0]][0] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : tuple<i32>
func.func @insert(%arg0 : tuple<i32>, %arg1 : i32) -> tuple<i32> {
  %tuple = tuple.insert %arg1 into %arg0[0] : tuple<i32>
  return %tuple : tuple<i32>
}
