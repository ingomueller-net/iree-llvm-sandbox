//===-- Tuple.cpp - Tuple dialect -------------------------------*- C++ -*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "iterators/Dialect/Tuple/IR/Tuple.h"

#include "mlir/IR/DialectImplementation.h"
#include "mlir/Support/LogicalResult.h"
#include "mlir/Transforms/InliningUtils.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace mlir::tuple;

//===----------------------------------------------------------------------===//
// Tuple dialect.
//===----------------------------------------------------------------------===//

#include "iterators/Dialect/Tuple/IR/TupleOpsDialect.cpp.inc"

namespace {
/// This class defines the interface for handling inlining for tuple dialect
/// operations.
struct TupleInlinerInterface : public DialectInlinerInterface {
  using DialectInlinerInterface::DialectInlinerInterface;

  /// All Tuple dialect ops can be inlined.
  bool isLegalToInline(Operation *, Region *, bool, IRMapping &) const final {
    return true;
  }
};
} // namespace

void TupleDialect::initialize() {
#define GET_ATTRDEF_LIST
  addAttributes<
#include "iterators/Dialect/Tuple/IR/TupleAttributes.cpp.inc"
      >();
#define GET_OP_LIST
  addOperations<
#include "iterators/Dialect/Tuple/IR/TupleOps.cpp.inc"
      >();
  addTypes<
#define GET_TYPEDEF_LIST
#include "iterators/Dialect/Tuple/IR/TupleOpsTypes.cpp.inc"
      >();
  addInterfaces<TupleInlinerInterface>();
}

//===----------------------------------------------------------------------===//
// Tuple attributes.
//===----------------------------------------------------------------------===//

#define GET_ATTRDEF_CLASSES
#include "iterators/Dialect/Tuple/IR/TupleAttributes.cpp.inc"

/// Extracts the types of the values in the given ArrayAttr and constructs a
/// TupleType from them. Fails and emits an error with the given function if an
/// attribute in the array is not a TypedAttr.
LogicalResult getTupleType(function_ref<InFlightDiagnostic()> emitError,
                           MLIRContext *context, ArrayAttr values,
                           TupleType &result) {
  SmallVector<Type> valueTypes;
  for (auto [idx, attr] : llvm::enumerate(values)) {
    if (!attr.isa<TypedAttr>()) {
      return emitError() << "attribute '" << attr << "' is not a TypedAttr";
    }
    Type type = attr.cast<TypedAttr>().getType();
    valueTypes.push_back(type);
  }
  result = TupleType::get(context, valueTypes);
  return success();
}

TupleAttr TupleAttr::get(MLIRContext *context, ArrayAttr values) {
  // Compute self type and fail if not possible.
  TupleType selfType;
  auto suppressDiagnostics = []() -> InFlightDiagnostic {
    return InFlightDiagnostic();
  };
  LogicalResult result =
      getTupleType(suppressDiagnostics, context, values, selfType);
  assert(succeeded(result));

  // Use get function with self type.
  return TupleAttr::get(context, values, selfType);
}

TupleAttr TupleAttr::getChecked(function_ref<InFlightDiagnostic()> emitError,
                                MLIRContext *context, ArrayAttr values) {
  // Compute self type and call getChecked function with self type.
  TupleType selfType;
  if (failed(getTupleType(emitError, context, values, selfType)))
    return {};
  return getChecked(emitError, context, values, selfType);
}

TupleAttr TupleAttr::get(MLIRContext *context, ArrayAttr values,
                         Type selfType) {
  // If the self type is `none` (which happens if no self type was provided),
  // call the get function without self type (which derives that type).
  if (selfType == NoneType::get(context))
    return TupleAttr::get(context, values);

  // For anything else, build the attribute as is.
  return Base::get(context, values, selfType);
}

TupleAttr TupleAttr::getChecked(function_ref<InFlightDiagnostic()> emitError,
                                MLIRContext *context, ArrayAttr values,
                                Type selfType) {
  // If the self type is `none` (which happens if no self type was provided),
  // call the getChecked function without self type (which derives that type).
  if (selfType == NoneType::get(context))
    return TupleAttr::getChecked(emitError, context, values);

  // For anything else, build the attribute as is.
  return Base::getChecked(emitError, context, values, selfType);
}

TupleAttr TupleAttr::get(ArrayAttr values) {
  return TupleAttr::get(values.getContext(), values);
}

TupleAttr TupleAttr::getChecked(function_ref<InFlightDiagnostic()> emitError,
                                ArrayAttr values) {
  return TupleAttr::getChecked(emitError, values.getContext(), values);
}

LogicalResult
TupleAttr::verify(function_ref<mlir::InFlightDiagnostic()> emitError,
                  ArrayAttr values, Type selfType) {
  // Verify that the provided self type corresponds to the expected self type
  // derived from the attribute values.
  TupleType expectedType;
  if (failed(
          getTupleType(emitError, selfType.getContext(), values, expectedType)))
    return failure();

  if (selfType != expectedType) {
    return emitError() << "attribute type must be " << expectedType << ", not "
                       << selfType;
  }

  return success();
}

//===----------------------------------------------------------------------===//
// Tuple operations.
//===----------------------------------------------------------------------===//

static ParseResult parseTupleElementTypes(AsmParser &parser,
                                          SmallVectorImpl<Type> &elementsTypes,
                                          Type type) {
  assert(type.isa<TupleType>());
  auto tupleType = type.cast<TupleType>();
  elementsTypes.append(tupleType.begin(), tupleType.end());
  return success();
}

static void printTupleElementTypes(AsmPrinter &printer, Operation *op,
                                   TypeRange elementsTypes, Type tupleType) {}

static ParseResult parseTupleElementType(AsmParser &parser, Type &elementType,
                                         Type type, IntegerAttr position) {
  assert(type.isa<TupleType>());
  auto tupleType = type.cast<TupleType>();

  int64_t idx = position.getInt();
  if (static_cast<size_t>(idx) < tupleType.getTypes().size()) {
    elementType = tupleType.getType(idx);
    return success();
  }

  parser.emitError(parser.getNameLoc(),
                   Twine("position ") + std::to_string(idx) + " out of bounds");
  return failure();
}

static void printTupleElementType(AsmPrinter &printer, Operation *op,
                                  Type elementType, Type tupleType,
                                  IntegerAttr position) {}

static ParseResult parseTupleElementTypes(AsmParser &parser, Type &resultType,
                                          Type type,
                                          DenseI32ArrayAttr positions) {
  assert(type.isa<TupleType>());
  auto tupleType = type.cast<TupleType>();

  SmallVector<Type> elementTypes;
  for (auto idx : positions.asArrayRef()) {
    if (static_cast<size_t>(idx) >= tupleType.getTypes().size()) {
      parser.emitError(parser.getNameLoc(), // (force new line)
                       Twine("position ") + std::to_string(idx) +
                           " out of bounds");
      return failure();
    }

    elementTypes.push_back(tupleType.getTypes()[idx]);
  }
  resultType = TupleType::get(type.getContext(), elementTypes);

  return success();
}

static void printTupleElementTypes(AsmPrinter &printer, Operation *op,
                                   TypeRange elementsTypes, Type tupleType,
                                   DenseI32ArrayAttr positions) {}

static ParseResult parseInsertSliceTypes(AsmParser &parser, Type &sliceType,
                                         Type type,
                                         DenseI32ArrayAttr positions) {
  assert(type.isa<TupleType>());
  auto tupleType = type.cast<TupleType>();

  SmallVector<Type> elementTypes;
  for (auto idx : positions.asArrayRef()) {
    if (static_cast<size_t>(idx) >= tupleType.getTypes().size()) {
      parser.emitError(parser.getNameLoc(), // (force new line)
                       Twine("position ") + std::to_string(idx) +
                           " out of bounds");
      return failure();
    }

    elementTypes.push_back(tupleType.getTypes()[idx]);
  }

  sliceType = TupleType::get(type.getContext(), elementTypes);
  return success();
}

static void printInsertSliceTypes(AsmPrinter &printer, Operation *op,
                                  TypeRange elementsTypes, Type tupleType,
                                  DenseI32ArrayAttr positions) {}

#define GET_OP_CLASSES
#include "iterators/Dialect/Tuple/IR/TupleOps.cpp.inc"

mlir::LogicalResult ConcatOp::inferReturnTypes(
    MLIRContext *context, Optional<Location> /*location*/, ValueRange operands,
    DictionaryAttr /*attributes*/, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  SmallVector<Type> elementTypes;
  TypeRange lhsTypes = operands[0].getType().cast<TupleType>().getTypes();
  TypeRange rhsTypes = operands[1].getType().cast<TupleType>().getTypes();
  elementTypes.append(lhsTypes.begin(), lhsTypes.end());
  elementTypes.append(rhsTypes.begin(), rhsTypes.end());
  inferredReturnTypes.push_back(TupleType::get(context, elementTypes));
  return success();
}

//===----------------------------------------------------------------------===//
// Tuple types.
//===----------------------------------------------------------------------===//

#define GET_TYPEDEF_CLASSES
#include "iterators/Dialect/Tuple/IR/TupleOpsTypes.cpp.inc"
