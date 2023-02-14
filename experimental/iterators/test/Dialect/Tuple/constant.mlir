// RUN: iterators-opt %s | iterators-opt | FileCheck %s

// CHECK-LABEL: func.func @no_type_qualified() -> tuple<i64> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.constant <[42]>
func.func @no_type_qualified() -> tuple<i64> {
  %tuple = tuple.constant #tuple.tuple<[42]>
  return %tuple : tuple<i64>
}

// CHECK-LABEL: func.func @no_type_unqualified() -> tuple<i64> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.constant <[42]>
func.func @no_type_unqualified() -> tuple<i64> {
  %tuple = tuple.constant <[42]>
  return %tuple : tuple<i64>
}

// CHECK-LABEL: func.func @attr_type() -> tuple<i64> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.constant <[42]>
func.func @attr_type() -> tuple<i64> {
  %tuple = tuple.constant #tuple.tuple<[42]> : tuple<i64>
  return %tuple : tuple<i64>
}

// CHECK-LABEL: func.func @many_types() -> tuple<ui1, f16, i32, si16, index, tensor<2xi32>, tensor<2xi32>, none> {
// CHECK-NEXT:    %[[V0:tuple.*]] = tuple.constant <[0 : ui1, 1.000000e+00 : f16, 2 : i32, 3 : si16, 4 : index, dense<10> : tensor<2xi32>, sparse<0, 1> : tensor<2xi32>, "hello"]>
#d = dense<10> : tensor<2xi32>
#s = sparse<[[0]], [1]> : tensor<2xi32>
func.func @many_types() -> tuple<ui1, f16, i32, si16, index, tensor<2xi32>, tensor<2xi32>, none> {
  %tuple = tuple.constant
      #tuple.tuple<[0 : ui1, 1.0 : f16, 2 : i32, 3 : si16, 4 : index, #d, #s, "hello"]> :
          tuple<ui1, f16, i32, si16, index, tensor<2xi32>, tensor<2xi32>, none>
  return %tuple : tuple<ui1, f16, i32, si16, index, tensor<2xi32>, tensor<2xi32>, none>
}
