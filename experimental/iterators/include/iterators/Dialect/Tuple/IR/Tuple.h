//===-- Tuple.h - Tuple dialect header file ---------------------*- C++ -*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef ITERATORS_DIALECT_TUPLE_IR_TUPLE_H
#define ITERATORS_DIALECT_TUPLE_IR_TUPLE_H

#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"

#include "iterators/Dialect/Tuple/IR/TupleOpsDialect.h.inc"

#define GET_ATTRDEF_CLASSES
#include "iterators/Dialect/Tuple/IR/TupleAttributes.h.inc"

#define GET_TYPEDEF_CLASSES
#include "iterators/Dialect/Tuple/IR/TupleOpsTypes.h.inc"

#define GET_OP_CLASSES
#include "iterators/Dialect/Tuple/IR/TupleOps.h.inc"

#endif // ITERATORS_DIALECT_TUPLE_IR_TUPLE_H
