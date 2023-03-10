// RUN: iterators-opt %s -decompose-tuples \
// RUN: | FileCheck --enable-var-scope %s

// RUN: iterators-opt %s -decompose-tuples="convert-func-ops=false" \
// RUN: | FileCheck --enable-var-scope --check-prefix=CHECK-NO-FUNC %s

// RUN: iterators-opt %s -decompose-tuples="convert-scf-ops=false" \
// RUN: | FileCheck --enable-var-scope --check-prefix=CHECK-NO-SCF %s

!nested_tuple = tuple<tuple<>, i32, tuple<i64>>

// CHECK-LABEL: func.func @concat(
// CHECK-SAME:                    %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                    %[[ARG1:[^:]*]]: i64,
// CHECK-SAME:                    %[[ARG2:[^:]*]]: i32,
// CHECK-SAME:                    %[[ARG3:[^:]*]]: i64) -> (i32, i64, i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]], %[[ARG2]], %[[ARG3]] : i32, i64, i32, i64
func.func @concat(%lhs: !nested_tuple, %rhs: !nested_tuple)
      -> tuple<tuple<>, i32, tuple<i64>, tuple<>, i32, tuple<i64>> {
  %tuple = tuple.concat %lhs + %rhs : !nested_tuple + !nested_tuple
  return %tuple : tuple<tuple<>, i32, tuple<i64>, tuple<>, i32, tuple<i64>>
}

// CHECK-LABEL: func.func @emptyConstant() {
// CHECK-NEXT:    return
// CHECK-NO-FUNC-LABEL: func.func @emptyConstant() -> tuple<> {
// CHECK-NO-FUNC-NEXT:    %[[V0:.*]] = tuple.from_elements  : tuple<>
// CHECK-NO-FUNC-NEXT:    return %[[V0]] : tuple<>
func.func @emptyConstant() -> tuple<> {
  %tuple = tuple.constant <[]>
  return %tuple : tuple<>
}

// CHECK-LABEL: func.func @nestedConstant() -> (i32, i64) {
// CHECK-DAG:     %[[V0:.*]] = arith.constant 1 : i32
// CHECK-DAG:     %[[V1:.*]] = arith.constant 2 : i64
// CHECK-NEXT:    return %[[V0]], %[[V1]] : i32, i64
func.func @nestedConstant() -> !nested_tuple {
  %tuple = tuple.constant <[#tuple.tuple<[]>, 1 : i32, #tuple.tuple<[2]>]>
  return %tuple : !nested_tuple
}

// CHECK-LABEL: func.func @extractEmpty(
// CHECK-SAME:                          %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                          %[[ARG1:[^:]*]]: i64) {
// CHECK-NEXT:    return
func.func @extractEmpty(%input: !nested_tuple) -> tuple<> {
  %element = tuple.extract %input[0] : !nested_tuple
  return %element : tuple<>
}

// CHECK-LABEL: func.func @extractNested(
// CHECK-SAME:                           %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                           %[[ARG1:[^:]*]]: i64) -> i64 {
// CHECK-NEXT:    return %[[ARG1]] : i64
func.func @extractNested(%input: !nested_tuple) -> tuple<i64> {
  %element = tuple.extract %input[2] : !nested_tuple
  return %element : tuple<i64>
}

// CHECK-LABEL: func.func @extractAll(
// CHECK-SAME:                        %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                        %[[ARG1:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]] : i32, i64
func.func @extractAll(%input: !nested_tuple) -> !nested_tuple {
  %slice = tuple.extract_slice %input[0, 1, 2] : !nested_tuple
  return %slice : !nested_tuple
}

// CHECK-LABEL: func.func @extractNone(
// CHECK-SAME:                         %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                         %[[ARG1:[^:]*]]: i64) {
// CHECK-NEXT:    return
func.func @extractNone(%input: !nested_tuple) -> tuple<> {
  %slice = tuple.extract_slice %input[] : !nested_tuple
  return %slice : tuple<>
}

// CHECK-LABEL: func.func @extractRepeated(
// CHECK-SAME:                             %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                             %[[ARG1:[^:]*]]: i64) -> (i32, i64, i32) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]], %[[ARG0]] : i32, i64, i32
func.func @extractRepeated(%input: !nested_tuple) -> tuple<i32, tuple<i64>, i32> {
  %slice = tuple.extract_slice %input[1, 2, 1] : !nested_tuple
  return %slice : tuple<i32, tuple<i64>, i32>
}

// CHECK-LABEL: func.func @fromElements(
// CHECK-SAME:                          %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                          %[[ARG1:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]] : i32, i64
func.func @fromElements(%arg0 : tuple<>, %arg1 : i32, %arg2 : tuple<i64>) -> !nested_tuple {
  %tuple = tuple.from_elements %arg0, %arg1, %arg2 : !nested_tuple
  return %tuple : !nested_tuple
}

// CHECK-LABEL: func.func @toElements(
// CHECK-SAME:                        %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                        %[[ARG1:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]] : i32, i64
func.func @toElements(%input : !nested_tuple) -> (tuple<>, i32, tuple<i64>) {
  %elements:3 = tuple.to_elements %input : !nested_tuple
  return %elements#0, %elements#1, %elements#2 : tuple<>, i32, tuple<i64>
}

// CHECK-LABEL: func.func @insert(
// CHECK-SAME:                    %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                    %[[ARG1:[^:]*]]: i32,
// CHECK-SAME:                    %[[ARG2:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG2]] : i32, i64
func.func @insert(%element : i32, %tuple: !nested_tuple) -> !nested_tuple {
  %updated = tuple.insert %element into %tuple[1] : !nested_tuple
  return %updated : !nested_tuple
}

// CHECK-LABEL: func.func @insertEmpty(
// CHECK-SAME:                         %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                         %[[ARG1:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]] : i32, i64
func.func @insertEmpty(%element : tuple<>, %tuple: !nested_tuple) -> !nested_tuple {
  %updated = tuple.insert %element into %tuple[0] : !nested_tuple
  return %updated : !nested_tuple
}

// CHECK-LABEL: func.func @insertOne(
// CHECK-SAME:                       %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                       %[[ARG1:[^:]*]]: i32,
// CHECK-SAME:                       %[[ARG2:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG2]] : i32, i64
func.func @insertOne(%slice : tuple<i32>, %tuple: !nested_tuple) -> !nested_tuple {
  %updated = tuple.insert_slice %slice into %tuple[1] : !nested_tuple
  return %updated : !nested_tuple
}

// CHECK-LABEL: func.func @insertAll(
// CHECK-SAME:                       %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                       %[[ARG1:[^:]*]]: i64,
// CHECK-SAME:                       %[[ARG2:[^:]*]]: i32,
// CHECK-SAME:                       %[[ARG3:[^:]*]]: i64) -> (i32, i64) {
// CHECK-NEXT:    return %[[ARG0]], %[[ARG1]] : i32, i64
func.func @insertAll(%slice : !nested_tuple, %tuple: !nested_tuple) -> !nested_tuple {
  %updated = tuple.insert_slice %slice into %tuple[0, 1, 2] : !nested_tuple
  return %updated : !nested_tuple
}

// CHECK-LABEL: func.func @argumentMaterialization(
// CHECK-SAME:                                     %[[ARG0:[^:]*]]: i32,
// CHECK-SAME:                                     %[[ARG1:[^:]*]]: i64) -> i32 {
// CHECK-DAG:     %[[V0:.*]] = tuple.from_elements  : tuple<>
// CHECK-DAG:     %[[V1:.*]] = tuple.from_elements %[[ARG1]] : tuple<i64>
// CHECK-NEXT:    %[[V2:.*]] = tuple.from_elements %[[V0]], %[[ARG0]], %[[V1]] : tuple<tuple<>, i32, tuple<i64>>
// CHECK-NEXT:    %[[V3:.*]] = builtin.unrealized_conversion_cast %[[V2]] : tuple<tuple<>, i32, tuple<i64>> to i32
func.func @argumentMaterialization(%input : !nested_tuple) -> i32 {
  %0 = builtin.unrealized_conversion_cast %input : !nested_tuple to i32
  return %0 : i32
}

// CHECK-LABEL: func.func @sourceMaterialization() -> i32 {
// CHECK-DAG:     %[[V0:.*]] = arith.constant 1 : i32
// CHECK-DAG:     %[[V1:.*]] = arith.constant 2 : i64
// CHECK-DAG:     %[[V2:.*]] = tuple.from_elements  : tuple<>
// CHECK-DAG:     %[[V3:.*]] = tuple.from_elements %[[V1]] : tuple<i64>
// CHECK-NEXT:    %[[V4:.*]] = tuple.from_elements %[[V2]], %[[V0]], %[[V3]] : tuple<tuple<>, i32, tuple<i64>>
// CHECK-NEXT:    %[[V5:.*]] = builtin.unrealized_conversion_cast %[[V4]] : tuple<tuple<>, i32, tuple<i64>> to i32
func.func @sourceMaterialization() -> i32 {
  %tuple = tuple.constant <[#tuple.tuple<[]>, 1 : i32, #tuple.tuple<[2]>]>
  %0 = builtin.unrealized_conversion_cast %tuple : !nested_tuple to i32
  return %0 : i32
}

// CHECK-LABEL: func.func @targetMaterialization() -> (i32, i64) {
// CHECK-DAG:     %[[V0:.*]] = builtin.unrealized_conversion_cast to tuple<tuple<>, i32, tuple<i64>>
// CHECK-DAG:     %[[V1:.*]]:3 = tuple.to_elements %[[V0]] : tuple<tuple<>, i32, tuple<i64>>
// CHECK-DAG:     tuple.to_elements %[[V1]]#0 : tuple<>
// CHECK-DAG:     %[[V2:.*]] = tuple.to_elements %elements#2 : tuple<i64>
// CHECK-NEXT:    return %[[V1]]#1, %[[V2]] : i32, i64
func.func @targetMaterialization() -> !nested_tuple {
  %tuple = builtin.unrealized_conversion_cast to !nested_tuple
  return %tuple : !nested_tuple
}

// CHECK-LABEL: func.func @scfIf(
// CHECK-SAME:                   %[[ARG0:[^:]*]]: i1) -> (i32, i64) {
// CHECK:         %[[V0:.*]]:2 = scf.if %[[ARG0]] -> (i32, i64) {
// CHECK-NEXT:      scf.yield %[[V1:.*]], %[[V2:.*]] : i32, i64
// CHECK-NEXT:    } else {
// CHECK-NEXT:      scf.yield %[[V3:.*]], %[[V4:.*]] : i32, i64
// CHECK-NEXT:    }
// CHECK-NO-SCF-LABEL: func.func @scfIf(
// CHECK-NO-SCF-SAME:                   %[[ARG0:[^:]*]]: i1) -> (i32, i64) {
// CHECK-NO-SCF:         %[[V0:.*]] = scf.if %[[ARG0]] -> (tuple<tuple<>, i32, tuple<i64>>) {
// CHECK-NO-SCF:         %[[V1:.*]]:3 = tuple.to_elements %[[V0]] : tuple<tuple<>, i32, tuple<i64>>
func.func @scfIf(%cmp : i1) -> !nested_tuple {
  %result = scf.if %cmp -> !nested_tuple {
    %tuple = tuple.constant <[#tuple.tuple<[]>, 1 : i32, #tuple.tuple<[2]>]>
    scf.yield %tuple : !nested_tuple
  } else {
    %tuple = tuple.constant <[#tuple.tuple<[]>, -1 : i32, #tuple.tuple<[-2]>]>
    scf.yield %tuple : !nested_tuple
  }
  return %result : !nested_tuple
}
