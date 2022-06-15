# --os:linux
--os:standalone
--cpu:wasm32
--cc:clang
--d:release
--noMain:on
--opt:size
--listCmd
--d:wasm
--d:noSignalHandler
--exceptions:goto
--app:lib

--gc:none
--threads:off
--stackTrace:off
--lineTrace:off
--mm:none

switch("passC", "-nostdinc -fuse-ld=wasm-ld -DNDEBUG -Ofast -std=c99 -D__EMSCRIPTEN__ -D_LIBCPP_ABI_VERSION=2 -fvisibility=hidden -fno-builtin -fno-exceptions -fno-threadsafe-statics -I/home/Emil/code/repos/DendrETH/src/nimToWasm")

--d:nimPreviewFloatRoundtrip # Avoid using sprintf as it's not available in wasm


let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

# switch("passC", "-I/usr/include") # Wouldn't compile without this :(

# switch("passC", "-flto -m32") # Important for code size!

# gc-sections seems to not have any effect
var linkerOptions = " -nostdlib -Wl,--no-entry,--allow-undefined,--export-all"

switch("clang.options.linker", linkerOptions)
switch("clang.cpp.options.linker", linkerOptions)