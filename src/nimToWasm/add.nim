proc print(x: float64) =
  echo x

proc add(a,b: float64): float64 {.exportc.} =
  a + b

proc printAdd(a,b: float64) =
  print(add(a, b))

proc start() =
  discard