// RUN: structured-opt %s \
// RUN:   -convert-triton-to-llvm -split-input-file \
// RUN: | FileCheck %s

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: !llvm.ptr<i32, 1>) -> i32 {
// CHECK-NEXT:    %[[V0:.*]] = llvm.load %[[ARG0]] : !llvm.ptr<i32, 1>
// CHECK-NEXT:    return %[[V0]] : i32
func.func public @kernel(%arg0: !tt.ptr<i32>) -> i32 {
  %0 = tt.load %arg0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : i32
  return %0 : i32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: !llvm.ptr<f32, 1>) -> f32 {
// CHECK-NEXT:    %[[V0:.*]] = llvm.load %[[ARG0]] : !llvm.ptr<f32, 1>
// CHECK-NEXT:    return %[[V0]] : f32
func.func public @kernel(%arg0: !tt.ptr<f32>) -> f32 {
  %0 = tt.load %arg0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : f32
  return %0 : f32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: !llvm.ptr<ptr<f32, 1>, 1>) -> f32 {
// CHECK-NEXT:    %[[V0:.*]] = llvm.load %[[ARG0]] : !llvm.ptr<ptr<f32, 1>, 1>
// CHECK-NEXT:    %[[V1:.*]] = llvm.load %[[V0]] : !llvm.ptr<f32, 1>
// CHECK-NEXT:    return %[[V1]] : f32
func.func public @kernel(%arg0: !tt.ptr<!tt.ptr<f32>>) -> f32 {
  %0 = tt.load %arg0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : !tt.ptr<f32>
  %1 = tt.load %0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : f32
  return %1 : f32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: !llvm.ptr<i32, 1>,
// CHECK-SAME:      %[[ARG1:.*]]: i1) -> i32 {
// CHECK:         %[[V0:.*]] = scf.if %[[ARG1]] -> (i32) {
// CHECK-DAG:       %[[V1:.*]] = llvm.load %[[ARG0]] : !llvm.ptr<i32, 1>
// CHECK-DAG:       scf.yield %[[V1]] : i32
// CHECK-NEXT:    } else {
// CHECK-DAG:       %[[V2:.*]] = llvm.mlir.undef : i32
// CHECK-DAG:       scf.yield %[[V2]] : i32
// CHECK-NEXT:    }
// CHECK-NEXT:    return
func.func public @kernel(%arg0: !tt.ptr<i32>, %arg1: i1) -> i32 {
  %1 = tt.load %arg0, %arg1 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : i32
  return %1 : i32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: !llvm.ptr<i32, 1>,
// CHECK-SAME:      %[[ARG1:.*]]: i1,
// CHECK-SAME:      %[[ARG2:.*]]: i32) -> i32 {
// CHECK-NEXT:    %[[V1:.*]] = scf.if %[[ARG1]] -> (i32) {
// CHECK-DAG:       %[[V2:.*]] = llvm.load %[[ARG0]] : !llvm.ptr<i32, 1>
// CHECK-DAG:       scf.yield %[[V2]] : i32
// CHECK-NEXT:    } else {
// CHECK-DAG:       scf.yield %[[ARG2]] : i32
// CHECK-NEXT:    }
// CHECK-NEXT:    return
func.func public @kernel(%arg0: !tt.ptr<i32>, %arg1: i1, %arg2: i32) -> i32 {
  %2 = tt.load %arg0, %arg1, %arg2 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : i32
  return %2 : i32
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]:  tensor<2xindex>) -> tensor<2xi32> {
// CHECK-DAG:     %[[V1:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[V2:.*]] = arith.constant 2 : index
// CHECK-DAG:     %[[V3:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[V4:.*]] = tensor.empty() : tensor<2xi32>
// CHECK-NEXT:    %[[V5:.*]] = scf.for %[[ARG1:.*]] = %[[V1]] to %[[V2]] step %[[V3]] iter_args(%[[ARG2:.*]] = %[[V4]]) -> (tensor<2xi32>) {
// CHECK-DAG:       %[[V6:.*]] = tensor.extract %[[ARG0]][%[[ARG1]]] : tensor<2xindex>
// CHECK-DAG:       %[[V7:.*]] = arith.index_cast %[[V6]] : index to i64
// CHECK-DAG:       %[[V8:.*]] = llvm.inttoptr %[[V7]] : i64 to !llvm.ptr<i32, 1>
// CHECK-DAG:       %[[V9:.*]] = llvm.load %[[V8]] : !llvm.ptr<i32, 1>
// CHECK-DAG:       %[[Va:.*]] = tensor.insert %[[V9]] into %[[ARG2]][%[[ARG1]]] : tensor<2xi32>
// CHECK-NEXT:      scf.yield %[[Va]] : tensor<2xi32>
// CHECK-NEXT:    }
// CHECK-NEXT:    return
func.func public @kernel(%arg0: tensor<2x!tt.ptr<i32>>) -> tensor<2xi32> {
  %0 = tt.load %arg0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : tensor<2xi32>
  return %0 : tensor<2xi32>
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: tensor<2xindex>) -> tensor<2xindex> {
// CHECK-DAG:     %[[V1:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[V2:.*]] = arith.constant 2 : index
// CHECK-DAG:     %[[V3:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[V4:.*]] = tensor.empty() : tensor<2xindex>
// CHECK-NEXT:    %[[V5:.*]] = scf.for %[[ARG1:.*]] = %[[V1]] to %[[V2]] step %[[V3]] iter_args(%[[ARG2:.*]] = %[[V4]]) -> (tensor<2xindex>) {
// CHECK-DAG:       %[[V6:.*]] = tensor.extract %[[ARG0]][%[[ARG1]]] : tensor<2xindex>
// CHECK-DAG:       %[[V7:.*]] = arith.index_cast %[[V6]] : index to i64
// CHECK-DAG:       %[[V8:.*]] = llvm.inttoptr %[[V7]] : i64 to !llvm.ptr<ptr<i32, 1>, 1>
// CHECK-DAG:       %[[V9:.*]] = llvm.load %[[V8]] : !llvm.ptr<ptr<i32, 1>, 1>
// CHECK-DAG:       %[[Va:.*]] = llvm.ptrtoint %[[V9]] : !llvm.ptr<i32, 1> to i64
// CHECK-DAG:       %[[Vb:.*]] = arith.index_cast %[[Va]] : i64 to index
// CHECK-DAG:       %[[Vc:.*]] = tensor.insert %[[Vb]] into %[[ARG2]][%[[ARG1]]] : tensor<2xindex>
// CHECK-NEXT:      scf.yield %[[Vc]] : tensor<2xindex>
// CHECK-NEXT:    }
// CHECK-NEXT:    return %[[V5]] : tensor<2xindex>
func.func public @kernel(%arg0: tensor<2x!tt.ptr<!tt.ptr<i32>>>) -> tensor<2x!tt.ptr<i32>> {
  %0 = tt.load %arg0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : tensor<2x!tt.ptr<i32>>
  return %0 : tensor<2x!tt.ptr<i32>>
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: tensor<2xindex>,
// CHECK-SAME:      %[[ARG1:.*]]: tensor<2xi1>) -> tensor<2xindex> {
// CHECK-DAG:     %[[V2:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[V3:.*]] = arith.constant 2 : index
// CHECK-DAG:     %[[V4:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[V5:.*]] = tensor.empty() : tensor<2xindex>
// CHECK-NEXT:    %[[V6:.*]] = scf.for %[[ARG2:.*]] = %[[V2]] to %[[V3]] step %[[V4]] iter_args(%[[ARG3:.*]] = %[[V5]]) -> (tensor<2xindex>) {
// CHECK-DAG:       %[[V7:.*]] = tensor.extract %[[ARG0]][%[[ARG2]]] : tensor<2xindex>
// CHECK-DAG:       %[[V8:.*]] = arith.index_cast %[[V7]] : index to i64
// CHECK-DAG:       %[[V9:.*]] = llvm.inttoptr %[[V8]] : i64 to !llvm.ptr<ptr<i32, 1>, 1>
// CHECK-DAG:       %[[Va:.*]] = tensor.extract %[[ARG1]][%[[ARG2]]] : tensor<2xi1>
// CHECK-NEXT:      %[[Vb:.*]] = scf.if %[[Va]] -> (!llvm.ptr<i32, 1>) {
// CHECK-DAG:         %[[Vc:.*]] = llvm.load %[[V9]] : !llvm.ptr<ptr<i32, 1>, 1>
// CHECK-DAG:         scf.yield %[[Vc]] : !llvm.ptr<i32, 1>
// CHECK-NEXT:      } else {
// CHECK-DAG:         %[[Vd:.*]] = llvm.mlir.undef : !llvm.ptr<i32, 1>
// CHECK-DAG:         scf.yield %[[Vd]] : !llvm.ptr<i32, 1>
// CHECK-NEXT:      }
// CHECK-NEXT:      %[[Ve:.*]] = llvm.ptrtoint %[[Vb]] : !llvm.ptr<i32, 1> to i64
// CHECK-NEXT:      %[[Vf:.*]] = arith.index_cast %[[Ve]] : i64 to index
// CHECK-DAG:       %[[Vg:.*]] = tensor.insert %[[Vf]] into %[[ARG3]][%[[ARG2]]] : tensor<2xindex>
// CHECK-NEXT:      scf.yield %[[Vg]] : tensor<2xindex>
// CHECK-NEXT:    }
// CHECK-NEXT:    return
func.func public @kernel(%arg0: tensor<2x!tt.ptr<!tt.ptr<i32>>>, %arg1: tensor<2xi1>) -> tensor<2x!tt.ptr<i32>> {
  %0 = tt.load %arg0, %arg1 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : tensor<2x!tt.ptr<i32>>
  return %0 : tensor<2x!tt.ptr<i32>>
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: tensor<2xindex>,
// CHECK-SAME:      %[[ARG1:.*]]: tensor<2xi1>,
// CHECK-SAME:      %[[ARG2:.*]]: tensor<2xindex>) -> tensor<2xindex> {
// CHECK-DAG:     %[[V2:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[V3:.*]] = arith.constant 2 : index
// CHECK-DAG:     %[[V4:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[V5:.*]] = tensor.empty() : tensor<2xindex>
// CHECK-NEXT:    %[[V6:.*]] = scf.for %[[ARG3:.*]] = %[[V2]] to %[[V3]] step %[[V4]] iter_args(%[[ARG4:.*]] = %[[V5]]) -> (tensor<2xindex>) {
// CHECK-DAG:       %[[V7:.*]] = tensor.extract %[[ARG0]][%[[ARG3]]] : tensor<2xindex>
// CHECK-DAG:       %[[V8:.*]] = arith.index_cast %[[V7]] : index to i64
// CHECK-DAG:       %[[V9:.*]] = llvm.inttoptr %[[V8]] : i64 to !llvm.ptr<ptr<i32, 1>, 1>
// CHECK-DAG:       %[[Va:.*]] = tensor.extract %[[ARG1]][%[[ARG3]]] : tensor<2xi1>
// CHECK-NEXT:      %[[Vb:.*]] = scf.if %[[Va]] -> (!llvm.ptr<i32, 1>) {
// CHECK-DAG:         %[[Vc:.*]] = llvm.load %[[V9]] : !llvm.ptr<ptr<i32, 1>, 1>
// CHECK-DAG:         scf.yield %[[Vc]] : !llvm.ptr<i32, 1>
// CHECK-NEXT:      } else {
// CHECK-DAG:         %[[Vd:.*]] = tensor.extract %[[ARG2]][%[[ARG3]]] : tensor<2xindex>
// CHECK-DAG:         %[[Ve:.*]] = arith.index_cast %[[Vd]] : index to i64
// CHECK-DAG:         %[[Vf:.*]] = llvm.inttoptr %[[Ve]] : i64 to !llvm.ptr<i32, 1>
// CHECK-DAG:         scf.yield %[[Vf]] : !llvm.ptr<i32, 1>
// CHECK-NEXT:      }
// CHECK-NEXT:      %[[Vg:.*]] = llvm.ptrtoint %[[Vb]] : !llvm.ptr<i32, 1> to i64
// CHECK-NEXT:      %[[Vh:.*]] = arith.index_cast %[[Vg]] : i64 to index
// CHECK-DAG:       %[[Vi:.*]] = tensor.insert %[[Vh]] into %[[ARG4]][%[[ARG3]]] : tensor<2xindex>
// CHECK-NEXT:      scf.yield %[[Vi]] : tensor<2xindex>
// CHECK-NEXT:    }
// CHECK-NEXT:    return
func.func public @kernel(%arg0: tensor<2x!tt.ptr<!tt.ptr<i32>>>, %arg1: tensor<2xi1>, %arg2: tensor<2x!tt.ptr<i32>>) -> tensor<2x!tt.ptr<i32>> {
  %0 = tt.load %arg0, %arg1, %arg2 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : tensor<2x!tt.ptr<i32>>
  return %0 : tensor<2x!tt.ptr<i32>>
}

// -----

// CHECK-LABEL: func.func public @kernel(
// CHECK-SAME:      %[[ARG0:.*]]: tensor<2x8xindex>) -> tensor<2x8xi32> {
// CHECK-DAG:     %[[V1:.*]] = arith.constant 2 : index
// CHECK-DAG:     %[[V2:.*]] = arith.constant 8 : index
// CHECK-DAG:     %[[V3:.*]] = tensor.empty() : tensor<2x8xi32>
// CHECK-NEXT:    %[[V6:.*]] = scf.for %[[ARG1:.*]] = %{{.*}} to %[[V1]] step %{{.*}} iter_args(%[[ARG2:.*]] = %[[V3]]) -> (tensor<2x8xi32>) {
// CHECK-NEXT:      %[[V7:.*]] = scf.for %[[ARG3:.*]] = %{{.*}} to %[[V2]] step %{{.*}} iter_args(%[[ARG4:.*]] = %[[ARG2]]) -> (tensor<2x8xi32>) {
// CHECK-DAG:         %[[V8:.*]] = tensor.extract %[[ARG0]][%[[ARG1]], %[[ARG3]]] : tensor<2x8xindex>
// CHECK-DAG:         %[[V9:.*]] = arith.index_cast %[[V8]] : index to i64
// CHECK-DAG:         %[[Va:.*]] = llvm.inttoptr %[[V9]] : i64 to !llvm.ptr<i32, 1>
// CHECK-DAG:         %[[Vb:.*]] = llvm.load %[[Va]] : !llvm.ptr<i32, 1>
// CHECK-DAG:         %[[Vc:.*]] = tensor.insert %[[Vb]] into %[[ARG4]][%[[ARG1]], %arg3] : tensor<2x8xi32>
// CHECK-NEXT:        scf.yield %[[Vc]] : tensor<2x8xi32>
// CHECK-NEXT:      }
// CHECK-NEXT:      scf.yield %[[V7]] : tensor<2x8xi32>
// CHECK-NEXT:    }
// CHECK-NEXT:    return
func.func public @kernel(%arg0: tensor<2x8x!tt.ptr<i32>>) -> tensor<2x8xi32> {
  %0 = tt.load %arg0 {cache = 1 : i32, evict = 1 : i32, isVolatile = false} : tensor<2x8xi32>
  return %0 : tensor<2x8xi32>
}
