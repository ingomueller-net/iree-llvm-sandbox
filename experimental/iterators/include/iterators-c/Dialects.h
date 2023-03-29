//===- Dialects.h - CAPI for dialects -----------------------------*- C -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef ITERATORS_C_DIALECTS_H
#define ITERATORS_C_DIALECTS_H

#include "mlir-c/IR.h"
#include "mlir-c/Support.h"

#ifdef __cplusplus
extern "C" {
#endif

//===----------------------------------------------------------------------===//
// Iterators dialect and types
//===----------------------------------------------------------------------===//

MLIR_DECLARE_CAPI_DIALECT_REGISTRATION(Iterators, iterators);

MLIR_CAPI_EXPORTED
bool mlirTypeIsAIteratorsStreamType(MlirType type);

MLIR_CAPI_EXPORTED
MlirType mlirIteratorsStreamTypeGet(MlirContext context, MlirType elementType);

//===----------------------------------------------------------------------===//
// Tabular dialect and types
//===----------------------------------------------------------------------===//

MLIR_DECLARE_CAPI_DIALECT_REGISTRATION(Tabular, tabular);

/// Checks whether the given type is a tabular view type.
MLIR_CAPI_EXPORTED bool mlirTypeIsATabularView(MlirType type);

/// Creates a tabular view type that consists of the given list of column types.
/// The type is owned by the context.
MLIR_CAPI_EXPORTED MlirType mlirTabularViewTypeGet(MlirContext ctx,
                                                   intptr_t numColumns,
                                                   MlirType const *columnTypes);

/// Returns the number of column types contained in a tabular view.
MLIR_CAPI_EXPORTED intptr_t mlirTabularViewTypeGetNumColumnTypes(MlirType type);

/// Returns the pos-th column type in the tabular view type.
MLIR_CAPI_EXPORTED MlirType mlirTabularViewTypeGetColumnType(MlirType type,
                                                             intptr_t pos);

/// Returns tuple type that represents one row of the given tabular view.
MLIR_CAPI_EXPORTED MlirType mlirTabularViewTypeGetRowType(MlirType type);

//===----------------------------------------------------------------------===//
// Tuple dialect and attributes
//===----------------------------------------------------------------------===//

MLIR_DECLARE_CAPI_DIALECT_REGISTRATION(Tuple, tuple);

/// Checks whether the given attribute is a tuple attribute.
MLIR_CAPI_EXPORTED bool mlirAttributeIsATupleAttr(MlirAttribute attr);

/// Checks whether the given attribute is a tuple attribute.
MLIR_CAPI_EXPORTED MlirAttribute mlirTupleAttrGet(MlirAttribute values);

#ifdef __cplusplus
}
#endif

#endif // ITERATORS_C_DIALECTS_H
