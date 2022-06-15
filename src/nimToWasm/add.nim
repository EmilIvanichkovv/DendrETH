proc print(value: cdouble) {.importc.}

proc plusAdd*(a,b: float64): float64 {.exportc.} =
  a + b

proc printAdd*(a,b: float64) {.exportc.} =
  print(plusAdd(a, b))

proc start*()  {.exportc.} =
  discard
