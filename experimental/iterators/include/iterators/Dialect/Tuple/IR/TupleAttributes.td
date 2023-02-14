//===-- TupleAttributes.td - Tuple attributes --------------*- tablegen -*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef ITERATORS_DIALECT_TUPLE_IR_TUPLEATTRIBUTES
#define ITERATORS_DIALECT_TUPLE_IR_TUPLEATTRIBUTES

include "iterators/Dialect/Tuple/IR/TupleDialect.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"

// Base class for Tuple dialect attributes.
class Tuple_Attr<string name, string attrMnemonic,
                     list<Trait> traits = [],
                     string baseCppClass = "::mlir::Attribute">
    : AttrDef<Tuple_Dialect, name, traits, baseCppClass> {
  let mnemonic = attrMnemonic;
}

def Tuple_TupleAttr : Tuple_Attr<"Tuple", "tuple", [TypedAttrInterface]> {
  let summary = "An attribute containing a tuple value";
  let description = [{
    An attribute that contains a tuple value, i.e., one attribute value for each
    element of the tuple. The attribute values for the elements have to be
    attributes that implement the `TypedAttrInterface`, which is used for
    attributes whose values may be SSA values. The `TupleAttr`, in turn,
    implements the `TypedAttrInterface`, so it may contain values of that type
    (i.e., nested tuple values are possible). The primary objective of this
    attribute is to model constants to `tuple`-typed SSA values.
  }];
  let parameters = (ins
    AttrParameter<"::mlir::ArrayAttr", "attributes">:$values,
    AttributeSelfTypeParameter<"">:$selfType
  );
  let assemblyFormat = "`<` $values `>`";
  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "::mlir::ArrayAttr":$values)>,
    AttrBuilder<(ins "::mlir::ArrayAttr":$values, "::mlir::Type":$selfType)>,
    AttrBuilderWithInferredContext<(ins "::mlir::ArrayAttr":$values)>,
  ];
  let extraClassDeclaration = [{
    /// Implement OpAsmOpInterface.
    TupleType getType() {
      llvm::SmallVector<Type> valueTypes;
      llvm::transform(getValues(), std::back_inserter(valueTypes),
        [](TypedAttr attr) { return attr.getType(); });
      return TupleType::get(getContext(), valueTypes);
    }
  }];
  let genVerifyDecl = 1;
}

#endif // ITERATORS_DIALECT_TUPLE_IR_TUPLEATTRIBUTES
