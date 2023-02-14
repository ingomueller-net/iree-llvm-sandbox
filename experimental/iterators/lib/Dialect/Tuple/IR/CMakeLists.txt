add_mlir_library(MLIRTupleDialect
  Tuple.cpp

  LINK_LIBS PUBLIC
  MLIRInferTypeOpInterface
  MLIRIR

  DEPENDS
  MLIRTupleAttributesIncGen
  MLIRTupleOpsIncGen
)
