//===-- Passes.td - Conversion pass definition file --------*- tablegen -*-===//
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef STRUCTURED_CONVERSION_PASSES
#define STRUCTURED_CONVERSION_PASSES

include "mlir/Pass/PassBase.td"

//===----------------------------------------------------------------------===//
// IteratorsToLLVM
//===----------------------------------------------------------------------===//

def ConvertIteratorsToLLVM : Pass<"convert-iterators-to-llvm", "ModuleOp"> {
  let summary = "Convert the operations from the iterators dialect into the "
                "LLVM dialect";
  let description = [{
    This lowering pass converts iterators, i.e., operation that have operands
    and results of type `Stream`, to control-flow that co-executes all iterators
    connected via use-def chains of `Stream`s as well as the state that is
    required for each iterator to do so. This is achieved by having each
    iterator *consumes* the elements in its operand `Stream`s in order to
    produce the elements of its result `Stream`. Since consuming an element is
    destructive (i.e., each element can only be consumed once), the lowering
    currently only works if the use-def chains of `Stream`s form a tree, i.e.,
    every `Stream` is used as an operand by exactly one subsequent iterator.

    More precisely, for each iterator, the lowering produces a state with a
    number of typed fields, including any local state that the iterator might
    require **plus the states of all iterators in the transitive use-def chain**
    of its operands. The computations are expressed as three functions, `Open`,
    `Next`, and `Close`, which operate on that state and which continuously pass
    control-flow between the logic of the different iterators:

    * `Open` initializes the computations, typically calling `Open` on the
      nested states of the current iterator;
    * `Next` produces the next element in the stream or signals "end of stream",
      making zero, one, or more calls to `Next` on any of the nested states as
      required by the logic of the current iterator; and
    * `Close` cleans up the state if necessary, typically calling `Close` on the
      nested states of the current iterator.

    The three functions take the current iterator state as an input and return
    the updated state. (Subsequent bufferization within LLVM presumably converts
    this to in-place updates.) `Next` also returns the next element in the
    stream, plus a Boolean that signals whether the element is valid or the end
    of the stream was reached.
  }];
  let constructor = "mlir::createConvertIteratorsToLLVMPass()";
  let dependentDialects = [
    "func::FuncDialect",
    "LLVM::LLVMDialect",
    "scf::SCFDialect",
    "tuple::TupleDialect"
  ];
}

//===----------------------------------------------------------------------===//
// StatesToLLVM
//===----------------------------------------------------------------------===//

def ConvertStatesToLLVM : Pass<"convert-states-to-llvm", "ModuleOp"> {
  let summary = "Convert the operations on iterator states into the LLVM "
                "dialect";
  let description = [{
    This lowering pass converts operations on iterator states into equivalent
    operations of the LLVM dialect. Currently, the ops on iterator states are
    essentially equivalent to the LLVM ops dealing with structs (but allow
    arbitrary types), so the lowering only consists of straightforward,
    one-to-one patterns.
  }];
  let constructor = "mlir::createConvertStatesToLLVMPass()";
  let dependentDialects = [
    "LLVM::LLVMDialect"
  ];
}

//===----------------------------------------------------------------------===//
// TabularToLLVM
//===----------------------------------------------------------------------===//

def ConvertTabularToLLVM : Pass<"convert-tabular-to-llvm", "ModuleOp"> {
  let summary = "Convert the tabular dialect to the LLVM dialect";
  let description = [{
    Convert the data types and ops from the tabular dialect to the LLVM dialect.
    The data types are typically variations of LLVM's structs and pointers; the
    ops, thus, translate to the LLVM ops handling structs and pointers.
  }];
  let constructor = "mlir::createConvertTabularToLLVMPass()";
  let dependentDialects = ["LLVM::LLVMDialect"];
}

//===----------------------------------------------------------------------===//
// TritonFuncToFunc
//===----------------------------------------------------------------------===//

def ConvertTritonFuncToFunc : Pass<"convert-triton-func-to-func", "ModuleOp"> {
  let summary = "Convert func-related ops from the Triton to the func dialect";
  let description = [{
    Converts the func-related operations from Triton's `tt` dialect to their
    equivalents from the upstream `func` dialect.

    Triton's `tt` dialect contains copies of the `call`, `func`, and `return`
    ops from the `func` dialect for finer control of the inlining behaviour of
    these ops. This pass converts instances of these three ops to the original
    ops in the `func` dialect while preserving all types, operands, attributes,
    successors, regions, and its location.
  }];
  let constructor = "mlir::createConvertTritonFuncToFuncPass()";
  let dependentDialects = [
    "func::FuncDialect"
  ];
}

//===----------------------------------------------------------------------===//
// TritonSPMDToFuncArgs
//===----------------------------------------------------------------------===//

def ConvertTritonSPMDToFuncArgs :
    Pass<"convert-triton-spmd-to-func-args", "ModuleOp"> {
  let summary = "Convert Triton's SPMD ops to function arguments";
  let description = [{
    Converts the SPMD-operations from Triton's `tt` dialect, namely `program_id`
    and `num_programs`, which provide the grid coordinates and grid size,
    respectively, into accesses to function arguments that provide these values.
    This allows to run the grid explicitly, for example, in a nested `scf.for`
    loop, and provide the grid coordinate and size explicitly.
  }];
  let constructor = "mlir::createConvertTritonSPMDToFuncArgsPass()";
  let dependentDialects = [
    "arith::ArithDialect",
    "scf::SCFDialect"
  ];
}

//===----------------------------------------------------------------------===//
// TritonToLLVM
//===----------------------------------------------------------------------===//

def ConvertTritonToLLVM : Pass<"convert-triton-to-llvm", "ModuleOp"> {
  let summary = "Convert the operations from Triton dialect to LLVM";
  let description = [{
    Converts the operations from Triton's `tt` dialect to the LLVM dialect such
    that they can run on a CPU.

    For now, only a subset of the tt dialect is supported. The plan is to extend
    the coverage progressively. Some of the conversions may go through upstream
    dialects, which are then lowered to LLVM using upstream pattersn; another
    possibility is to use a subset of Triton's pattern if they happen to work.
  }];
  let constructor = "mlir::createConvertTritonToLLVMPass()";
  let dependentDialects = [
    "arith::ArithDialect",
    "linalg::LinalgDialect",
    "LLVM::LLVMDialect",
    "scf::SCFDialect",
    "tensor::TensorDialect"
  ];
}

#endif // STRUCTURED_CONVERSION_PASSES
