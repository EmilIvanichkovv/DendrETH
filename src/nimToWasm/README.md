# Compiling Nim to WebAssembly

## Create `nim` file with some functions. For example [`add.nim`](src/nimToWasm/add.nim) is:

```nim
proc print(value: cdouble) {.importc.}

proc plusAdd*(a,b: float64): float64 {.exportc.} =
  a + b

proc printAdd*(a,b: float64) {.exportc.} =
  print(plusAdd(a, b))

proc start*()  {.exportc.} =
  discard
```

## Run the following command to create the `wasm` file:

```
nim c -o:add.wasm add.nim
```

> Note: You need proper [configuration](src/nimToWasm/config.nims) for the compiler
> and maybe fake some `headers`

## To run the `wasm` file check [index.html](src/nimToWasm/index.html)