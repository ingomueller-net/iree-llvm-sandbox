add_mlir_dialect(TupleOps tuple)
add_dependencies(MLIRTupleDialect MLIRTupleOpsIncGen)

set(LLVM_TARGET_DEFINITIONS TupleAttributes.td)
mlir_tablegen(TupleAttributes.h.inc -gen-attrdef-decls)
mlir_tablegen(TupleAttributes.cpp.inc -gen-attrdef-defs)
add_public_tablegen_target(MLIRTupleAttributesIncGen)

add_dependencies(mlir-headers
  MLIRTupleAttributesIncGen
  MLIRTupleOpsIncGen
)
