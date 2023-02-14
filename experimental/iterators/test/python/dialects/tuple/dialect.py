# RUN: %PYTHON %s | FileCheck %s

from mlir_iterators.dialects import tuple as tup
from mlir_iterators.ir import (
    ArrayAttr,
    Context,
    IntegerAttr,
    IntegerType,
    Location,
)


def run(f):
  print("\nTEST:", f.__name__)
  with Context(), Location.unknown():
    tup.register_dialect()
    f()
  return f


# CHECK-LABEL: TEST: testTupleAttr
@run
def testTupleAttr():
  i32 = IntegerType.get_signless(32)
  i = IntegerAttr.get(i32, 42)
  a = ArrayAttr.get([i])
  t = tup.TupleAttr.get(a)
  # CHECK-NEXT: #tuple.tuple<[42 : i32]> : tuple<i32>
  print(t)


# CHECK-LABEL: TEST: testConstantOp
@run
def testConstantOp():
  a = ArrayAttr.get([])
  t = tup.TupleAttr.get(a)
  op = tup.ConstantOp(t)
  # CHECK-NEXT: %tuple = tuple.constant <[]>
  print(op)
