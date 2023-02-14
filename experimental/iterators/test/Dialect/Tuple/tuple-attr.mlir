// RUN: iterators-opt -allow-unregistered-dialect %s \
// RUN: | iterators-opt -allow-unregistered-dialect \
// RUN: | FileCheck %s

// CHECK: module

// Test case: basic printing and parsing.
// CHECK-NEXT: #tuple.tuple<[42]> : tuple<i64>}
"d.op"() {a = #tuple.tuple<[42]> : tuple<i64>} : () -> ()

// Test case: omitted attribute type is computed.
// CHECK-NEXT: #tuple.tuple<[42]> : tuple<i64>}
"d.op"() {a = #tuple.tuple<[42]>} : () -> ()

// Test case: omitted field types of the default type of literals aren't printed.
// CHECK-NEXT: #tuple.tuple<[42, "a", true, 1.337000e+00]> : tuple<i64, none, i1, f64>}
"d.op"() {a = #tuple.tuple<[42, "a", true, 1.337]>} : () -> ()

// Test case: specified field types are preserved.
// CHECK-NEXT: {a = #tuple.tuple<[42 : i32, "a" : tuple<>, 1.336910e+00 : f16]> : tuple<i32, tuple<>, f16>}
"d.op"() {a = #tuple.tuple<[42 : i32, "a" : tuple<>, 1.337 : f16]>} : () -> ()

// Test case: empty tuple.
// CHECK-NEXT: {a = #tuple.tuple<[]> : tuple<>}
"d.op"() {a = #tuple.tuple<[]> : tuple<>} : () -> ()

// Test case: nested tuple.
// CHECK-NEXT: {a = #tuple.tuple<[#tuple.tuple<[]> : tuple<>, 0, #tuple.tuple<[1]> : tuple<i64>, #tuple.tuple<[#tuple.tuple<[2]> : tuple<i64>]> : tuple<tuple<i64>>]> : tuple<tuple<>, i64, tuple<i64>, tuple<tuple<i64>>>}
"d.op"() {a = #tuple.tuple<[#tuple.tuple<[]>, 0, #tuple.tuple<[1]>, #tuple.tuple<[#tuple.tuple<[2]>]>]> : tuple<tuple<>, i64, tuple<i64>, tuple<tuple<i64>>>} : () -> ()
