//===- DecomposeTuples.h - Pass Utilities -----------------------*- C++ -*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef ITERATORS_DIALECT_TUPLE_TRANSFORMS_DECOMPOSETUPLES_H
#define ITERATORS_DIALECT_TUPLE_TRANSFORMS_DECOMPOSETUPLES_H

namespace mlir {
class RewritePatternSet;
class TypeConverter;
} // namespace mlir

namespace mlir {
namespace iterators {

void populateDecomposeTuplesPatterns(TypeConverter &typeConverter,
                                     RewritePatternSet &patterns);

} // namespace iterators
} // namespace mlir

#endif // ITERATORS_DIALECT_TUPLE_TRANSFORMS_DECOMPOSETUPLES_H
