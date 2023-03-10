//===- DecomposeTupless.cpp - Pass Implementation ----------------*- C++
//-*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "iterators/Dialect/Tuple/Transforms/DecomposeTuples.h"

#include "iterators/Dialect/Tuple/IR/Tuple.h"
#include "iterators/Dialect/Tuple/Transforms/Passes.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/Transforms/OneToNFuncConversions.h"
#include "mlir/Dialect/SCF/Transforms/Transforms.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Transforms/OneToNTypeConversion.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
#define GEN_PASS_CLASSES
#include "iterators/Dialect/Tuple/Transforms/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::iterators;
using namespace mlir::tuple;

using InputMapping = OneToNTypeMapping::InputMapping;

class DecomposeTuplesTypeConverter : public OneToNTypeConverter {
public:
  DecomposeTuplesTypeConverter() {
    addConversion([](Type type) { return type; });
    addConversion([](TupleType type, SmallVectorImpl<Type> &results) {
      type.getFlattenedTypes(results);
      return success();
    });
  }
};

class DecomposeConcatOp : public OneToNOpConversionPattern<ConcatOp> {
public:
  using OneToNOpConversionPattern<ConcatOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(ConcatOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping &operandMapping,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    ValueRange lhsElements =
        operandMapping.getConvertedValues(convertedOperands, 0);
    ValueRange rhsElements =
        operandMapping.getConvertedValues(convertedOperands, 1);

    SmallVector<Value> results;
    results.append(lhsElements.begin(), lhsElements.end());
    results.append(rhsElements.begin(), rhsElements.end());

    rewriter.replaceOp(op, results, resultMapping);

    return success();
  }
};

class DecomposeConstantOp : public OneToNOpConversionPattern<ConstantOp> {
public:
  using OneToNOpConversionPattern<ConstantOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(ConstantOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping & /*operandMapping*/,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange /*convertedOperands*/) const override {
    Location loc = op->getLoc();

    // Extract flattened values.
    SmallVector<TypedAttr> flattenedValues;
    getFlattenedValues(op.getValueAttr(), flattenedValues);

    // Create constant op for each of them.
    SmallVector<Value> results;
    for (TypedAttr value : flattenedValues) {
      // XXX: How about types that arith.constant can't build?
      auto constantOp = rewriter.create<arith::ConstantOp>(loc, value);
      results.push_back(constantOp);
    }

    // Replace results with those.
    rewriter.replaceOp(op, results, resultMapping);

    return success();
  }

private:
  void getFlattenedValues(TupleAttr attr,
                          llvm::SmallVectorImpl<TypedAttr> &result) const {
    ArrayAttr values = attr.getValues();
    for (TypedAttr value : values) {
      if (auto tupleValue = value.dyn_cast<TupleAttr>())
        getFlattenedValues(tupleValue, result);
      else
        result.push_back(value);
    }
  }
};

class DecomposeExtractOp : public OneToNOpConversionPattern<ExtractOp> {
public:
  using OneToNOpConversionPattern<ExtractOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(ExtractOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping &operandMapping,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    ValueRange inputValues =
        operandMapping.getConvertedValues(convertedOperands, 0);

    // Create mapping for elements of input tuple.
    auto tupleType = op.getTuple().getType().cast<TupleType>();
    TypeRange originalElementTypes = tupleType.getTypes();
    OneToNTypeMapping elementMapping(originalElementTypes);
    if (failed(typeConverter->convertSignatureArgs(originalElementTypes,
                                                   elementMapping)))
      return failure();

    // Extract elements corresponding to given position.
    int64_t pos = op.getPosition().getSExtValue();
    ValueRange extractedValues =
        elementMapping.getConvertedValues(inputValues, pos);

    // Replace result with those.
    rewriter.replaceOp(op, extractedValues, resultMapping);

    return success();
  }
};

class DecomposeExtractSliceOp
    : public OneToNOpConversionPattern<ExtractSliceOp> {
public:
  using OneToNOpConversionPattern<ExtractSliceOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(ExtractSliceOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping &operandMapping,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    ValueRange inputValues =
        operandMapping.getConvertedValues(convertedOperands, 0);

    // Create mapping for elements of input tuple.
    auto tupleType = op.getTuple().getType().cast<TupleType>();
    TypeRange originalElementTypes = tupleType.getTypes();
    OneToNTypeMapping elementMapping(originalElementTypes);
    if (failed(typeConverter->convertSignatureArgs(originalElementTypes,
                                                   elementMapping)))
      return failure();

    // Extract elements corresponding to given positions.
    SmallVector<Value> extractedValues;
    for (int32_t pos : op.getPositions()) {
      ValueRange elements = elementMapping.getConvertedValues(inputValues, pos);
      extractedValues.append(elements.begin(), elements.end());
    }

    // Replace result with those.
    rewriter.replaceOp(op, extractedValues, resultMapping);

    return success();
  }
};

class DecomposeFromElementsOp
    : public OneToNOpConversionPattern<FromElementsOp> {
public:
  using OneToNOpConversionPattern<FromElementsOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(FromElementsOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping & /*operandMapping*/,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    // Simply forward converted operands.
    rewriter.replaceOp(op, convertedOperands, resultMapping);

    return success();
  }
};

class DecomposeInsertOp : public OneToNOpConversionPattern<InsertOp> {
public:
  using OneToNOpConversionPattern<InsertOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(InsertOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping &operandMapping,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    ValueRange elementValues =
        operandMapping.getConvertedValues(convertedOperands, 0);
    ValueRange tupleValues =
        operandMapping.getConvertedValues(convertedOperands, 1);

    // Create mapping for elements of input tuple.
    auto tupleType = op.getTuple().getType().cast<TupleType>();
    TypeRange originalElementTypes = tupleType.getTypes();
    OneToNTypeMapping elementMapping(originalElementTypes);
    if (failed(typeConverter->convertSignatureArgs(originalElementTypes,
                                                   elementMapping)))
      return failure();

    // Update elements corresponding to given position.
    SmallVector<Value> updatedValues(tupleValues.begin(), tupleValues.end());
    int64_t pos = op.getPosition().getSExtValue();
    std::optional<InputMapping> mapping = elementMapping.getInputMapping(pos);
    if (mapping.has_value()) {
      assert(mapping->size == elementValues.size());
      for (auto [i, elementValue] : llvm::enumerate(elementValues)) {
        int64_t idx = mapping->inputNo + i;
        updatedValues[idx] = elementValue;
      }
    }

    // Replace result with updated values.
    rewriter.replaceOp(op, updatedValues, resultMapping);

    return success();
  }
};

class DecomposeInsertSliceOp : public OneToNOpConversionPattern<InsertSliceOp> {
public:
  using OneToNOpConversionPattern<InsertSliceOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(InsertSliceOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping &operandMapping,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    ValueRange sliceValues =
        operandMapping.getConvertedValues(convertedOperands, 0);
    ValueRange tupleValues =
        operandMapping.getConvertedValues(convertedOperands, 1);

    // Create mapping for elements of slice tuple.
    auto sliceType = op.getSlice().getType().cast<TupleType>();
    TypeRange originalSliceElementTypes = sliceType.getTypes();
    OneToNTypeMapping sliceMapping(originalSliceElementTypes);
    if (failed(typeConverter->convertSignatureArgs(originalSliceElementTypes,
                                                   sliceMapping)))
      return failure();

    // Create mapping for elements of input tuple.
    auto tupleType = op.getTuple().getType().cast<TupleType>();
    TypeRange originalTupleElementTypes = tupleType.getTypes();
    OneToNTypeMapping inputTupleMapping(originalTupleElementTypes);
    if (failed(typeConverter->convertSignatureArgs(originalTupleElementTypes,
                                                   inputTupleMapping)))
      return failure();

    // Update elements corresponding to given positions.
    SmallVector<Value> updatedValues(tupleValues.begin(), tupleValues.end());
    for (auto [slicePos, inputPos] : llvm::enumerate(op.getPositions())) {
      // Look up mapping values at current position.
      std::optional<InputMapping> curSliceMapping =
          sliceMapping.getInputMapping(slicePos);
      std::optional<InputMapping> curInputMapping =
          inputTupleMapping.getInputMapping(inputPos);
      assert(curSliceMapping.has_value() == curInputMapping.has_value());

      // If the element at the current position is an empty tuple, skip.
      if (!curSliceMapping.has_value())
        continue;

      // Co-iterate the mapped values and update the tuple with the slice
      // values.
      assert(curSliceMapping->size == curInputMapping->size);
      for (int64_t i = 0; i < static_cast<int64_t>(curSliceMapping->size);
           i++) {
        int64_t sliceIdx = curSliceMapping->inputNo + i;
        int64_t inputIdx = curInputMapping->inputNo + i;
        updatedValues[inputIdx] = sliceValues[sliceIdx];
      }
    }

    // Replace result with updated values.
    rewriter.replaceOp(op, updatedValues, resultMapping);

    return success();
  }
};

class DecomposeToElementsOp : public OneToNOpConversionPattern<ToElementsOp> {
public:
  using OneToNOpConversionPattern<ToElementsOp>::OneToNOpConversionPattern;

  LogicalResult
  matchAndRewrite(ToElementsOp op, OneToNPatternRewriter &rewriter,
                  const OneToNTypeMapping & /*operandMapping*/,
                  const OneToNTypeMapping &resultMapping,
                  const ValueRange convertedOperands) const override {
    // Simply forward converted operands.
    rewriter.replaceOp(op, convertedOperands, resultMapping);

    return success();
  }
};

void iterators::populateDecomposeTuplesPatterns(TypeConverter &typeConverter,
                                                RewritePatternSet &patterns) {
  patterns.add<
      // clang-format off
      DecomposeConcatOp,
      DecomposeConstantOp,
      DecomposeExtractOp,
      DecomposeExtractSliceOp,
      DecomposeFromElementsOp,
      DecomposeInsertOp,
      DecomposeInsertSliceOp,
      DecomposeToElementsOp
      // clang-format on
      >(typeConverter, patterns.getContext());
}

/// Creates IR that builds FromElementsOps to assemble a value of the given,
/// portentially recursive tuple type from the given range of inputs. This can
/// be used as argument and source materializations for tuple decomposition.
static std::optional<Value> buildFromElementsOp(OpBuilder &builder,
                                                TypeConverter &typeConverter,
                                                Type type, ValueRange inputs,
                                                Location loc) {
  auto tupleType = type.dyn_cast<TupleType>();
  if (!tupleType)
    return {};

  // Create mapping for elements of inputs.
  TypeRange originalInputTypes = tupleType.getTypes();
  OneToNTypeMapping inputMapping(originalInputTypes);
  if (failed(
          typeConverter.convertSignatureArgs(originalInputTypes, inputMapping)))
    return {};

  // Assemble element values at this nesting level.
  SmallVector<Value> operands;
  for (auto [i, elementType] : llvm::enumerate(originalInputTypes)) {
    // Element is a nested tuple: recursively build back the tuple.
    ValueRange elementValues = inputMapping.getConvertedValues(inputs, i);
    if (elementType.isa<TupleType>()) {
      std::optional<Value> createdTuple = buildFromElementsOp(
          builder, typeConverter, elementType, elementValues, loc);
      if (!createdTuple.has_value() || !createdTuple.value())
        return {};
      operands.push_back(createdTuple.value());
      continue;
    }

    // Any other type: take as is.
    assert(elementValues.size() == 1);
    Value operand = elementValues.front();
    operands.push_back(operand);
  }

  // Build the tuple from its elements.
  auto createStateOp = builder.create<FromElementsOp>(loc, type, operands);
  assert(createStateOp->getNumResults() == 1);
  return createStateOp->getResult(0);
}

/// Creates IR that extracts the elements of the given input tuple recursively
/// using ToElementOps. This can be used as target conversion for tuple
/// decomposition.
std::optional<SmallVector<Value>>
buildToElementsOp(OpBuilder &builder, TypeConverter &typeConverter,
                  TypeRange resultTypes, Value input, Location loc) {
  auto tupleType = input.getType().dyn_cast<TupleType>();
  if (!tupleType)
    return {};

  // Create mapping for elements of inputs.
  TypeRange originalElementTypes = tupleType.getTypes();
  OneToNTypeMapping elementMapping(originalElementTypes);
  if (failed(typeConverter.convertSignatureArgs(originalElementTypes,
                                                elementMapping)))
    return {};

  // Extract elements at this level.
  auto toElements =
      builder.create<ToElementsOp>(loc, originalElementTypes, input);

  // Assemble final values, recursing where necessary.
  SmallVector<Value> results;
  for (auto [i, nestedElement] : llvm::enumerate(toElements.getResults())) {
    // Nested element is a tuple: use results of recursive call.
    if (nestedElement.getType().isa<TupleType>()) {
      TypeRange nestedResultTypes = elementMapping.getConvertedTypes(i);
      std::optional<SmallVector<Value>> nestedValues = buildToElementsOp(
          builder, typeConverter, nestedResultTypes, nestedElement, loc);
      if (!nestedValues.has_value())
        return {};
      results.append(nestedValues->begin(), nestedValues->end());
    } else {
      // Any other element: use as is.
      results.push_back(nestedElement);
    }
  }

  return results;
}

struct DecomposeTuplesPass : public DecomposeTuplesBase<DecomposeTuplesPass> {
  void runOnOperation() override {
    ModuleOp module = getOperation();
    MLIRContext *context = &getContext();

    // Assemble type convert with materializations.
    DecomposeTuplesTypeConverter typeConverter;
    auto buildFromElementsOpHelper = [&](OpBuilder &builder, Type type,
                                         ValueRange inputs, Location loc) {
      return buildFromElementsOp(builder, typeConverter, type, inputs, loc);
    };
    typeConverter.addArgumentMaterialization(buildFromElementsOpHelper);
    typeConverter.addSourceMaterialization(buildFromElementsOpHelper);
    auto buildToElementsOpHelper = [&](OpBuilder &builder,
                                       TypeRange resultTypes, Value input,
                                       Location loc) {
      return buildToElementsOp(builder, typeConverter, resultTypes, input, loc);
    };
    typeConverter.addTargetMaterialization(buildToElementsOpHelper);

    // Assemble patterns.
    RewritePatternSet patterns(context);
    populateDecomposeTuplesPatterns(typeConverter, patterns);
    if (convertFuncOps)
      populateFuncTypeConversionPatterns(typeConverter, patterns);
    if (convertSCFOps)
      scf::populateSCFStructuralOneToNTypeConversions(typeConverter, patterns);

    // Run conversion.
    if (failed(applyPartialOneToNConversion(module, typeConverter,
                                            std::move(patterns))))
      return signalPassFailure();
  };
};

std::unique_ptr<Pass> mlir::createDecomposeTuplesPass() {
  return std::make_unique<DecomposeTuplesPass>();
}
