//===-- TupleOps.td - Tuple operations definitions ---------*- tablegen -*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef ITERATORS_DIALECT_TUPLE_IR_TUPLEOPS
#define ITERATORS_DIALECT_TUPLE_IR_TUPLEOPS

include "iterators/Dialect/Tuple/IR/TupleAttributes.td"
include "iterators/Dialect/Tuple/IR/TupleDialect.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/OpBase.td"

class Tuple_Op<string mnemonic, list<Trait> traits = []> :
    Op<Tuple_Dialect, mnemonic, traits> {
}

def Tuple_ConstantOp : Tuple_Op<"constant", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>,
    AllTypesMatch<["value", "tuple"]>,
    ]> {
  let summary = "Builds a tuple literal from the given attribute";
  let description = [{
    Returns a `tuple` with the value given as attribute, i.e., the elements of
    the returned `tuple` consist of the elements of the provided `value`
    attribute.

    Example:

    ```mlir
    %tuple = tuple.constant <[42]>  // contains a tuple<i64> with the value 42
    ```
  }];
  let arguments = (ins Tuple_TupleAttr:$value);
  let results = (outs AnyTuple:$tuple);
  let assemblyFormat = "$value attr-dict";
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "tuple");
    }
  }];
}

def Tuple_FromElementsOp : Tuple_Op<"from_elements", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>
    ]> {
  let summary = "Builds a tuple from the given elements";
  let description = [{
    Returns a `tuple` with the elements assembled from the operands, i.e., the
    elements of the returned `tuple` consist of the values provided as operands.

    Example:

    ```mlir
    %0 = arith.constant 42 : i32
    %tuple = tuple.from_elements %0, %0 : tuple<i32, i32>  // contains (42, 42)
    ```
  }];
  let arguments = (ins Variadic<AnyType>:$elements);
  let results = (outs AnyTuple:$tuple);
  let assemblyFormat = [{
    $elements attr-dict `:` qualified(type($tuple))
    custom<TupleElementTypes>(type($elements), ref(type($tuple)))
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "tuple");
    }
  }];
}

def Tuple_ToElementsOp : Tuple_Op<"to_elements", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>
    ]> {
  let summary = "Produces all elements of a given tuple";
  let description = [{
    Produces one result value for each field of the provided tuple. Note that
    this does not "flatten" the tuple, i.e., a tuple-typed element produces
    exactly one result value, which may itself have zero, one, or more elements.

    Example:

    ```mlir
    %0 = ...
    %first_element, %second_element = tuple.to_elements %0 : tuple<i32, tuple<>>
    // %first_element is a i32, %second_element is a tuple<>
    ```
  }];
  let arguments = (ins AnyTuple:$tuple);
  let results = (outs Variadic<AnyType>:$elements);
  let assemblyFormat = [{
    $tuple attr-dict `:` qualified(type($tuple))
    custom<TupleElementTypes>(type($elements), ref(type($tuple)))
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      if (getNumResults() > 0)
        setNameFn(getResult(0), "elements");
    }
  }];
}

def Tuple_ExtractOp : Tuple_Op<"extract", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>
    ]> {
  let summary = "Extracts the element at the given position as a single value";
  let description = [{
    Returns the element at the given position as a single value.

    Example:

    ```mlir
    %tuple = tuple.constant <[0, 1, 2]>
    %element = tuple.extract %tuple[1] : tuple<i64, i64, i64>  // returns 1 : i64
    ```
  }];
  let arguments = (ins AnyTuple:$tuple, IndexAttr:$position);
  let results = (outs AnyType:$element);
  let assemblyFormat = [{
    $tuple `[` $position `]` attr-dict `:` qualified(type($tuple))
    custom<TupleElementType>(type($element), ref(type($tuple)), ref($position))
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "element");
    }
  }];
}

def Tuple_ExtractSliceOp : Tuple_Op<"extract_slice", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>
    ]> {
  let summary = "Extracts the elements at the given positions as a new tuple";
  let description = [{
    Returns a new tuple built from the elements at the given indices, i.e., the
    return tuple consists of one element of the input tuple for each provided
    position, namely the element at that position. Positions may be repeated and
    each occurrence of that position will create a new element in the output
    with the same element from the input.

    Example:

    ```mlir
    %tuple = tuple.constant <[4, 2]>
    %element = tuple.extract_slice %tuple[1, 0, 1] : tuple<i64, i64>  // (2, 4, 2)
    ```
  }];
  let arguments = (ins AnyTuple:$tuple, DenseI32ArrayAttr:$positions);
  let results = (outs AnyTuple:$result);
  let assemblyFormat = [{
    $tuple $positions attr-dict `:` qualified(type($tuple))
    custom<TupleElementTypes>(type($result), ref(type($tuple)), ref($positions))
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "tuple");
    }
  }];
}

def Tuple_InsertOp : Tuple_Op<"insert", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>,
    AllTypesMatch<["tuple", "result"]>
    ]> {
  let summary = "Updates the tuple at the given position with the given element";
  let description = [{
    Updates the tuple at the given position with the provided value, i.e.,
    creates a new tuple whose elements consists of the elements of the original
    tuple, except for the element at the provided position, which consists of
    the replacement element instead.

    Example:

    ```mlir
    %0 = arith.constant 42 : i32
    %tuple = tuple.constant <[4, 2]>
    %element = tuple.insert %tuple[0] : tuple<i64, i64>  // return (42, 2)
    ```
  }];
  let arguments = (ins AnyType:$element, AnyTuple:$tuple, IndexAttr:$position);
  let results = (outs AnyType:$result);
  let assemblyFormat = [{
    $element `into` $tuple `[` $position `]` attr-dict `:` qualified(type($tuple))
    custom<TupleElementType>(type($element), ref(type($tuple)), ref($position))
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "tuple");
    }
  }];
}

def Tuple_InsertSliceOp : Tuple_Op<"insert_slice", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>,
    AllTypesMatch<["tuple", "result"]>,
    PredOpTrait<"provided positions must be all distinct",
        CPred<[{[&]() {
            llvm::SmallSetVector<int32_t, 4> uniquePositions(
                $positions.begin(), $positions.end());
            return uniquePositions.size() == $positions.size();
          }()}]>>
    ]> {
  let summary = "Updates the tuple at the given positions with the elements in the given tuple";
  let description = [{
    Updates the tuple at the given positions using the elements from the
    provided tuple slice, i.e., creates a new tuple whose elements consists of
    the elements of the original tuple, except for the elements at the provided
    positions, which consist of the elements of the provided tuple slice (where
    the i-th position says where the i-th tuple from the slice should be
    inserted). Each position may be occur only once.

    Example:

    ```mlir
    %tuple = tuple.constant <[1, 2, 3]>
    %slice = tuple.constant <[4, 0]>
    %element = tuple.insert_slice %slice into %tuple[2, 0] : tuple<i64, i64, i64>
    // %element contains (0, 2, 4)
    ```
  }];
  let arguments = (ins AnyTuple:$slice, AnyTuple:$tuple, DenseI32ArrayAttr:$positions);
  let results = (outs AnyTuple:$result);
  let assemblyFormat = [{
    $slice `into` $tuple $positions attr-dict `:` qualified(type($tuple))
    custom<InsertSliceTypes>(type($slice), ref(type($tuple)), ref($positions))
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "tuple");
    }
  }];
}

def Tuple_ConcatOp : Tuple_Op<"concat", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
    ]> {
  let summary = "Creates a new tuple from the concatenation of the lhs and rhs elements";
  let description = [{
    Concatenates two tuples, i.e., creates a new tuple whose elements consist of
    the lhs elements and then the rhs elements.

    Example:

    ```mlir
    %lhs = tuple.constant <[1, 2, 3]>
    %rhs = tuple.constant <[4, 5]>
    %tuple =  tuple.concat %lhs + %rhs : tuple<i64, i64, i64> + tuple<i64, i64>
    // %tuple contains (1, 2, 3, 4, 5)
    ```
  }];
  let arguments = (ins AnyTuple:$lhs, AnyTuple:$rhs);
  let results = (outs AnyTuple:$result);
  let assemblyFormat = [{
    $lhs `+` $rhs attr-dict `:` type($lhs) `+` type($rhs)
  }];
  let extraClassDefinition = [{
    /// Implement OpAsmOpInterface.
    void $cppClass::getAsmResultNames(
        llvm::function_ref<void(mlir::Value, llvm::StringRef)> setNameFn) {
      setNameFn(getResult(), "tuple");
    }
  }];
}

#endif // ITERATORS_DIALECT_TUPLE_IR_TUPLEOPS
