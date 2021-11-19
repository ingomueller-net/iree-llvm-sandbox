// RUN: mlir-proto-opt %s -split-input-file | FileCheck %s

func @predicate_noresults(%pred: vector<8xi1>) {
  vector_ext.predicate (%pred: vector<8xi1>) {
  }
  return
}

// CHECK-LABEL:   func @predicate_noresults(
// CHECK-NEXT:      vector_ext.predicate(%{{.*}}: vector<8xi1>) {
// CHECK-NEXT:      }
// CHECK-NEXT:      return
// CHECK-NEXT:    }

// -----

func @predicate_results(%pred: vector<32xi1>) {
  vector_ext.predicate (%pred: vector<32xi1>) -> i32 {
    %c0 = arith.constant 0 : i32
    vector_ext.yield %c0 : i32
  }
  return
}

// CHECK-LABEL:   func @predicate_results(
// CHECK-NEXT:      %{{.*}} = vector_ext.predicate(%{{.*}}: vector<32xi1>) -> (i32) {
// CHECK-NEXT:        %[[CONST:.*]] = arith.constant 0 : i32
// CHECK-NEXT:        vector_ext.yield %[[CONST]] : i32
// CHECK-NEXT:      }
// CHECK-NEXT:      return
// CHECK-NEXT:    }
