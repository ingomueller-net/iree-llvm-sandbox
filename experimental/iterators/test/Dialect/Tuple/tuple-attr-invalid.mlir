// RUN: iterators-opt -allow-unregistered-dialect \
// RUN:   -verify-diagnostics -split-input-file %s

// Test case: mismatched attribute type.
// expected-error@+1 {{attribute type must be 'tuple<i64>', not 'tuple<i32>'}}
#a = #tuple.tuple<[42 : i64]> : tuple<i32>

// -----

// Test case: mismatched attribute type.
// expected-error@+1 {{attribute '@sym' is not a TypedAttr}}
#a = #tuple.tuple<[@sym]>
