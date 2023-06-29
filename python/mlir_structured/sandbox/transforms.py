from mlir_structured.ir import *
from mlir_structured.passmanager import PassManager
import mlir_structured.dialects.transform as transform
import mlir_structured.dialects.transform.bufferization
from mlir_structured.dialects import pdl

from mlir_structured.sandbox.variables import *
from mlir_structured.sandbox.transform import Transform

import typing as tp


def make_pattern_name(fun_name: str, op_name: str):
  return "match_" + op_name.replace('.', '_') + "_in_" + fun_name


def emit_transform_matcher(fun_name: str, op_name: str):
  pattern = pdl.PatternOp(benefit=1, name=make_pattern_name(fun_name, op_name))
  with InsertionPoint(pattern.body):
    operands = pdl.OperandsOp()
    result_types = pdl.TypesOp()
    pdl_op = pdl.OperationOp(op_name, args=[operands], types=[result_types])
    pdl_attr = pdl.AttributeOp(value=FlatSymbolRefAttr.get(fun_name))
    pdl.ApplyNativeConstraintOp('nestedInFunc', args=[pdl_op, pdl_attr])
    pdl.RewriteOp(pdl_op, 'transform.dialect')


def emit_pattern_if_not_present(fun_name: str, op_name: str):
  parent = InsertionPoint.current.block.owner.operation
  while not isinstance(parent.opview, transform.WithPDLPatternsOp) and parent:
    parent = parent.parent
  assert parent, "Expected to find a transform.WithPDLPatternsOp as parent"
  symbol_table = SymbolTable(parent)
  pattern_name = make_pattern_name(fun_name, op_name)
  if pattern_name not in symbol_table:
    with InsertionPoint(parent.opview.body.blocks[0]):
      emit_transform_matcher(fun_name, op_name)
  return pattern_name


class Inject(Transform):
  """Inject intermediate IR.

  Replace the module by the provided IR. The transform can be configured as
  follows:
  * `ir_to_inject`: Textual IR to inject.
  """

  def __init__(self, ir_to_inject: str, **kwargs):
    self.ir_to_inject = ir_to_inject

  def __call__(self, module: Module, fun_name: str, **kwargs):
    return Module.parse(self.ir_to_inject)


class Fuse(Transform):
  """Tile a linalg op and fuse its producers.

  This transform can be configured as follows:
  * `tile_sizes`: Tile sizes used for tiling.
  * `tile_interchange`: Interchange used for tiling.
  * `peel`: Peel the specified loops generated by tiling.
  """

  variables = {
      'tile_sizes': (TilingSizesVariable, []),
      'tile_interchange': (InterchangeVariable, []),
      'peel': (PeelingVariable, []),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    tiled = transform.FuseOp(target,
                             tile_sizes=self.tile_sizes,
                             tile_interchange=self.tile_interchange)
    for loop_index in self.peel:
      transform.PeelLoopOp(tiled.results[1 + loop_index])


class Tile(Transform):
  """Tile a linalg op with `tile_sizes`.

  This transform can be configured as follows:
  * `tile_sizes`: Tile sizes used for tiling.
  * `tile_interchange`: Interchange used for tiling.
  * `peel`: Peel the specified loops generated by the tiling pattern.
  * `scalarize_dyn_dims`: Scalarize all dimensions of the main tiled op that
    have statically unknown size.
  """

  variables = {
      'tile_sizes': (TilingSizesVariable, []),
      'tile_interchange': (InterchangeVariable, []),
      'peel': (PeelingVariable, []),
      'scalarize_dyn_dims': (BoolVariable, False),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    tiled = transform.TileOp(target,
                             sizes=self.tile_sizes,
                             interchange=self.tile_interchange)
    for loop_index in self.peel:
      transform.PeelLoopOp(tiled.results[1 + loop_index])
    if self.scalarize_dyn_dims:
      transform.ScalarizeOp(tiled.results[0])


class Pad(Transform):
  """Pad a linalg op.

  This transform can be configured as follows:
  * `padding_values`: Pad the operands with the specified values.
  * `padding_dimensions`: Pad the operand shape dimensions matching the
    specified loops.
  * `pack_paddings`: Pack the padded operand if the packing flag is set.
  * `hoist_paddings`: Hoist the padded operand by the specified number of loops.
  * `transpose_paddings`: Transpose the padded operands by the specified
    interchange vectors:
    transpose_paddings=[[1, 0, 2], [0, 1], [0, 1]]
    It defines the interchange [1, 0, 2] for operand one and the
    interchange [0, 1] (no transpose) for the remaining operands.
    An interchange vector has to be a permutation matching the
    operand rank.
  """

  variables = {
      'padding_values': (PaddingValueVariable, []),
      'padding_dimensions': (PaddingDimensionVariable, []),
      'pack_paddings': (PackPaddingVariable, []),
      'hoist_paddings': (HoistPaddingVariable, []),
      'transpose_paddings': (TransposePaddingVariable, []),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    transform.PadOp(target,
                    padding_values=self.padding_values,
                    padding_dimensions=self.padding_dimensions,
                    pack_paddings=self.pack_paddings,
                    hoist_paddings=self.hoist_paddings,
                    transpose_paddings=self.transpose_paddings)


class Vectorize(Transform):
  """Vectorize named operations.

  This transform can be configured as follows:
  * `vectorize_paddings`: Vectorize pad tensor operations.
  * `vectorize_only_tiled`: Vectorize only tiled operations.
  """

  variables = {
      'vectorize_paddings': (BoolVariable, True),
      'vectorize_only_tiled': (BoolVariable, False),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    # Emit the untargeted version if requested.
    if not self.op_name:
      transform.VectorizeOp(vectorize_padding=self.vectorize_paddings)
      return

    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    transform.VectorizeOp(target, vectorize_padding=self.vectorize_paddings)


class Generalize(Transform):
  """Transform a named operation to its generic form.

  This transform can be configured as follows:
  * `iterator_interchange`: Interchange the iterators of the generic operation.

  Note: After generalization the anchor op name changes to 'linalg.generic'.
  """

  variables = {
      'iterator_interchange': (InterchangeVariable, []),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    transform.GeneralizeOp(target)


class Interchange(Transform):
  """Transform a named operation to its generic form.

  This transform can be configured as follows:
  * `iterator_interchange`: Interchange the iterators of the generic operation.

  Note: After generalization the anchor op name changes to 'linalg.generic'.
  """

  variables = {
      'iterator_interchange': (InterchangeVariable, []),
  }

  def __init__(self, fun_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, 'generic')
    target = transform.PDLMatchOp(target, match_symbol)
    transform.InterchangeOp(target,
                            iterator_interchange=self.iterator_interchange)


class DecomposeToLowerDimensionalNamedOp(Transform):
  """Rewrite all known named ops to a lower-dimensional form suitable for
  vectorization.

  TODO: atm this is applied to all supported ops, add finer-grained control.
  """

  def __init__(self, **kwargs):
    pass

  def build_transform_ir(self, target):
    transform.DecomposeOp()


class Bufferize(Transform):
  """Trigger one-shot bufferization on the whole module.
  """

  def __init__(self, **kwargs):
    pass

  def build_transform_ir(self, target):
    transform.bufferization.OneShotBufferizeOp()


class LowerVectors(Transform):

  class ContractionLoweringChoice(ChoiceVariableBase):
    options = ("outerproduct", "dot", "matrixintrinsics")

  class MultiReductionLoweringChoice(ChoiceVariableBase):
    options = ("innerparallel", "innerreduction")

  class TransposeLoweringChoice(ChoiceVariableBase):
    options = ("eltwise", "flat_transpose", "shuffle")

  class VectorTransferSplitChoice(ChoiceVariableBase):
    options = ("none", "linalg-copy", "vector-transfers")

  variables = {
      'contraction_lowering': (ContractionLoweringChoice, 'outerproduct'),
      'max_transfer_rank': (IntVariable, 1),
      'multi_reduction_lowering':
          (MultiReductionLoweringChoice, 'innerparallel'),
      'split_transfers': (VectorTransferSplitChoice, 'linalg-copy'),
      'transpose_lowering': (TransposeLoweringChoice, 'eltwise'),
      'transpose_avx2_lowering': (BoolVariable, False),
      'unroll_vector_transfers': (BoolVariable, True),
      'print_after_all': (BoolVariable, False),
  }

  def __init__(self,
               stages: tp.Union[int, tp.Sequence[int]] = range(7),
               **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    if isinstance(stages, int):
      stages = [stages]

    self.stages = stages

  def build_transform_ir(self, target):
    for name in ('max_transfer_rank', 'print_after_all'):
      if getattr(self, name) != LowerVectors.variables[name][1]:
        raise NotImplementedError(name +
                                  " not supported by the transform dialect")

    for stage in sorted(self.stages):
      transform.LowerVectorsOp(
          stages=[s + 1 for s in range(stage + 1)],
          contraction_lowering=self.contraction_lowering,
          multireduction_lowering=self.multi_reduction_lowering,
          split_transfers=self.split_transfers,
          unroll_vector_transfers=self.unroll_vector_transfers,
          transpose_lowering=self.transpose_lowering,
          transpose_avx2_lowering=self.transpose_avx2_lowering)


class LowerToLLVM(Transform):
  """Trigger lowering to LLVM on the whole module.
  """

  variables = {
      'reassociate_fp_reductions': (BoolVariable, False),
      'enable_index_optimizations': (BoolVariable, False),
      'enable_arm_neon': (BoolVariable, False),
      'enable_arm_sve': (BoolVariable, False),
      'enable_amx': (BoolVariable, False),
      'enable_x86vector': (BoolVariable, False),
      'enable_async': (BoolVariable, False),
  }

  def __init__(self, **kwargs):
    self._parse_variables_in_kwargs(kwargs)

  def build_transform_ir(self, target):
    transform.LowerToLLVMOp(
        reassociate_fp_reductions=self.reassociate_fp_reductions,
        enable_index_optimizations=self.enable_index_optimizations,
        enable_arm_neon=self.enable_arm_neon,
        enable_arm_sve=self.enable_arm_sve,
        enable_amx=self.enable_amx,
        enable_x86vector=self.enable_x86vector,
        enable_async=self.enable_async)


class UnrollOneParentLoop(Transform):

  variables = {
      'parent_loop_num': (IntVariable, 1),
      'unroll_factor': (IntVariable, 1),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    loop = transform.GetParentLoopOp(target, num_loops=self.parent_loop_num)
    transform.UnrollLoopOp(loop, factor=self.unroll_factor)


class PipelineOneParentLoop(Transform):

  variables = {
      'parent_loop_num': (IntVariable, 1),
      'II': (IntVariable, 1),
      'read_latency': (IntVariable, 10),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    loop = transform.GetParentLoopOp(target, num_loops=self.parent_loop_num)
    transform.PipelineLoopOp(loop,
                             iteration_interval=self.II,
                             read_latency=self.read_latency)


class OutlineOneParentLoop(Transform):

  variables = {
      'parent_loop_num': (IntVariable, 1),
  }

  def __init__(self, fun_name: str, op_name: str, result_func_name: str,
               **kwargs):
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    loop = transform.GetParentLoopOp(target, num_loops=self.parent_loop_num)
    transform.OutlineLoopOp(loop, func_name=self.result_func_name)


class ApplySchedule(Transform):

  def __init__(self):
    pass

  def __call__(self, module: Module, **kwargs):
    # Passing a file path to SANDBOX_DUMP_MODULE_TO dumps the module to the file.
    # This is useful for further debugging with iree-dialects-opt via:
    # ```
    #   cmake --build ${IREE_BUILD_DIR} --target iree-dialects-opt && \
    #   ${IREE_BUILD_DIR}/third_party/llvm-project/llvm/bin/iree-dialects-opt \
    #     ${SANDBOX_DUMP_MODULE_TO}
    # ```
    from os import environ
    module_file = environ.get('SANDBOX_DUMP_MODULE_TO')
    if module_file is not None:
      with open(module_file, "w") as f:
        f.write(str(module))
    PassManager.parse('linalg-transform-interp').run(module)
    PassManager.parse('linalg-drop-schedule').run(module)
    return module


##===----------------------------------------------------------------------===##
## LinalgExt specific transforms
##===----------------------------------------------------------------------===##


class LinalgExtTile(Transform):
  """Tile a linalg op with using the iree_linalg_ext.tile op and a single
  entry tile_sizes.

  This transform can be configured as follows:
  * `tile_sizes`: The 1-D tile size used for tiling.
  """

  variables = {
      'tile_sizes': (TilingSizesVariable, []),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    self._parse_variables_in_kwargs(kwargs)
    self.fun_name = fun_name
    self.op_name = op_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name, self.op_name)
    target = transform.PDLMatchOp(target, match_symbol)
    transform.TileToLinalgExtTileOp(target, sizes=self.tile_sizes)


class LinalgExtTileToScfFor(Transform):
  """Rewrite iree_linalg_ext.tile op to scf.for.
  """

  variables = {}

  def __init__(self, fun_name: str, **kwargs):
    self.fun_name = fun_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name,
                                               'iree_linalg_ext.tile')
    target = transform.PDLMatchOp(target, match_symbol)
    transform.RewriteLinalgExtTileToScfForOp(target)


class LinalgExtTileToInParallel(Transform):
  """Rewrite iree_linalg_ext.tile op to iree_linalg_ext.in_parallel.
  """

  variables = {}

  def __init__(self, fun_name: str, **kwargs):
    self.fun_name = fun_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name,
                                               'iree_linalg_ext.tile')
    target = transform.PDLMatchOp(target, match_symbol)
    transform.RewriteLinalgExtTileToInParallelOp(target)


class LinalgExtInParallelToScfFor(Transform):
  """Rewrite iree_linalg_ext.in_parallel op to scf.for.
  """

  variables = {}

  def __init__(self, fun_name: str, **kwargs):
    self.fun_name = fun_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name,
                                               'iree_linalg_ext.in_parallel')
    target = transform.PDLMatchOp(target, match_symbol)
    transform.RewriteLinalgExtInParallelToScfForOp(target)


class LinalgExtInParallelToAsync(Transform):
  """Rewrite iree_linalg_ext.in_parallel op to async.
  """

  variables = {}

  def __init__(self, fun_name: str, **kwargs):
    self.fun_name = fun_name

  def build_transform_ir(self, target):
    match_symbol = emit_pattern_if_not_present(self.fun_name,
                                               'iree_linalg_ext.in_parallel')
    target = transform.PDLMatchOp(target, match_symbol)
    transform.RewriteLinalgExtInParallelToAsyncOp(target)


###############################################################################
# TODO: Port to the transform dialect
###############################################################################
class UnrollOneVectorOp(Transform):

  variables = {
      # Vector unrolling is similar to tiling but using unrolling instead of
      # loops. Use TilingSizesVariable as a searchable type.
      'source_shape': (TilingSizesVariable, []),
      'target_shape': (TilingSizesVariable, []),
  }

  def __init__(self, fun_name: str, op_name: str, **kwargs):
    pass
