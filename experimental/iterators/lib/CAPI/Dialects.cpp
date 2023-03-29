//===- Dialects.cpp - CAPI for dialects -----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "iterators-c/Dialects.h"

#include "iterators/Dialect/Iterators/IR/Iterators.h"
#include "iterators/Dialect/Tabular/IR/Tabular.h"
#include "iterators/Dialect/Tuple/IR/Tuple.h"
#include "mlir-c/IR.h"
#include "mlir/CAPI/IR.h"
#include "mlir/CAPI/Registration.h"
#include "mlir/IR/Types.h"
#include "llvm/ADT/StringRef.h"

//===----------------------------------------------------------------------===//
// Iterators dialect and types
//===----------------------------------------------------------------------===//

using namespace mlir;
using namespace mlir::iterators;
using namespace mlir::tuple;

MLIR_DEFINE_CAPI_DIALECT_REGISTRATION(Iterators, iterators, IteratorsDialect)

bool mlirTypeIsAIteratorsStreamType(MlirType type) {
  return unwrap(type).isa<StreamType>();
}

MlirType mlirIteratorsStreamTypeGet(MlirContext context, MlirType elementType) {
  return wrap(StreamType::get(unwrap(context), unwrap(elementType)));
}

//===----------------------------------------------------------------------===//
// Tabular dialect and types
//===----------------------------------------------------------------------===//

MLIR_DEFINE_CAPI_DIALECT_REGISTRATION(Tabular, tabular, TabularDialect)

/// Checks whether the given type is a tabular view type.
bool mlirTypeIsATabularView(MlirType type) {
  return unwrap(type).isa<TabularViewType>();
}

/// Creates a tabular view type that consists of the given list of column types.
/// The type is owned by the context.
MlirType mlirTabularViewTypeGet(MlirContext ctx, intptr_t numColumns,
                                MlirType const *columnTypes) {
  SmallVector<Type, 4> types;
  ArrayRef<Type> typesRef = unwrapList(numColumns, columnTypes, types);
  return wrap(TabularViewType::get(unwrap(ctx), typesRef));
}

/// Returns the number of types contained in a tabular view.
intptr_t mlirTabularViewTypeGetNumColumnTypes(MlirType type) {
  return unwrap(type).cast<TabularViewType>().getColumnTypes().size();
}

/// Returns the pos-th type in the tabular view type.
MlirType mlirTabularViewTypeGetColumnType(MlirType type, intptr_t pos) {
  return wrap(unwrap(type)
                  .cast<TabularViewType>()
                  .getColumnTypes()[static_cast<size_t>(pos)]);
}

MlirType mlirTabularViewTypeGetRowType(MlirType type) {
  return wrap(unwrap(type).cast<TabularViewType>().getRowType());
}

//===----------------------------------------------------------------------===//
// Tuple dialect and attributes
//===----------------------------------------------------------------------===//

MLIR_DEFINE_CAPI_DIALECT_REGISTRATION(Tuple, tuple, TupleDialect)

bool mlirAttributeIsATupleAttr(MlirAttribute attr) {
  return unwrap(attr).isa<TupleAttr>();
}

MlirAttribute mlirTupleAttrGet(MlirAttribute values) {
  ArrayAttr valuesArray = unwrap(values).cast<ArrayAttr>();
  return wrap(TupleAttr::get(valuesArray));
}
