// RUN: iterators-opt %s -convert-iterators-to-llvm \
// RUN: | FileCheck --enable-var-scope %s

!element_type = !llvm.struct<(i32)>

func.func @main() {
  // CHECK-LABEL: func.func @main()
  %input = "iterators.constantstream"() { value = [] } : () -> (!iterators.stream<!element_type>)
  "iterators.sink"(%input) : (!iterators.stream<!element_type>) -> ()
  // CHECK:         %[[V1:.*]] = call @[[rootIteratorName:.*]].open.{{[0-9]+}}(%[[V0:.*]]) : ([[rootStateType:.*]]) -> [[rootStateType]]
  // CHECK-NEXT:    %[[V2:.*]]:2 = scf.while (%[[arg0:.*]] = %[[V1]]) : ([[rootStateType]]) -> ([[rootStateType]], !llvm.struct<(i32)>) {
  // CHECK-NEXT:      %[[V4:.*]]:3 = func.call @[[rootIteratorName]].next.{{[0-9]+}}(%[[arg0]]) : ([[rootStateType]]) -> ([[rootStateType]], i1, !llvm.struct<(i32)>)
  // CHECK-NEXT:      scf.condition(%[[V4]]#1) %[[V4]]#0, %[[V4]]#2 : [[rootStateType]], !llvm.struct<(i32)>
  // CHECK-NEXT:    } do {
  // CHECK-NEXT:    ^[[bb0:.*]](%[[arg1:.*]]: [[rootStateType]], %[[arg2:.*]]: !llvm.struct<(i32)>):
  // CHECK-DAG:       %[[V4:.*]] = llvm.mlir.addressof @iterators.frmt_spec{{(\.[0-9]+)?}} : !llvm.ptr
  // CHECK-DAG:       %[[V6:.*]] = llvm.getelementptr %[[V4]][0] : (!llvm.ptr) -> !llvm.ptr, i8
  // CHECK-DAG:       %[[V7:.*]] = llvm.extractvalue %[[arg2:.*]][0] : !llvm.struct<(i32)>
  // CHECK-DAG:       %[[V9:.*]] = arith.extui %[[V7]] : i32 to i64
  // CHECK-NEXT:      %[[V8:.*]] = llvm.call @printf(%[[V6]], %[[V9]]) : (!llvm.ptr, i64) -> i32
  // CHECK-NEXT:      scf.yield %[[arg1]] : [[rootStateType]]
  // CHECK-NEXT:    }
  // CHECK-NEXT:    %[[V3:.*]] = call @[[rootIteratorName]].close.{{[0-9]+}}(%[[V2]]#0) : ([[rootStateType]]) -> [[rootStateType]]
  return
  // CHECK-NEXT:   return
}
// CHECK-NEXT:   }
// CHECK-NEXT: }
