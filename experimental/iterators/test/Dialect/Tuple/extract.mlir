// RUN: iterators-opt %s | iterators-opt | FileCheck %s

// CHECK-LABEL: func.func @extract(
// CHECK-SAME:                     %[[ARG0:.*]]: tuple<i32>) -> i32 {
// CHECK-NEXT:    %[[V0:element.*]] = tuple.extract %[[ARG0]][0] : tuple<i32>
// CHECK-NEXT:    return %[[V0]] : i32
func.func @extract(%arg0 : tuple<i32>) -> i32 {
  %element = tuple.extract %arg0[0] : tuple<i32>
  return %element : i32
}
