when defined(emcc):
  {.emit: "#include <emscripten.h>".}
  {.pragma: wasmPragma, cdecl, exportc, dynlib, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".}
else:
  {.pragma: wasmPragma, cdecl, exportc, dynlib.}

from nimcrypto/hash import MDigest, fromHex

import light_client_utils
import ./helpers/helpers
from ../../src/nim-light-client/light_client
  import initialize_light_client_store, process_light_client_update
from stew/ranges/ptr_arith import makeOpenArray

proc print(value: any) {.importc, cdecl}

proc processLightClientUpdatesTest(
    dataRoot: pointer,
    dataBootstrap: pointer,
    dataUpdates: pointer,
    ): bool {.wasmPragma.} =
  # print dataUpdates

  for el in makeOpenArray(dataUpdates, byte, 12):
    print el
  var beaconBlockHeader: BeaconBlockHeader
  beaconBlockHeader.deserializeSSZType(dataRoot, sizeof(BeaconBlockHeader))
  var bootstrap: LightClientBootstrap
  bootstrap.deserializeSSZType(dataBootstrap, sizeof(LightClientBootstrap))

  var update: LightClientUpdate
  let genesis_validators_root = MDigest[256].fromHex("4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95")
  var lightClientStore =
   initialize_light_client_store(hash_tree_root(beaconBlockHeader), bootstrap)

  # print 5
  for dataUpdate in makeOpenArray(dataUpdates, pointer, 12):
    update.deserializeSSZType(dataUpdate, sizeof(LightClientUpdate))
    process_light_client_update(lightClientStore,
                                update,
                                update.signature_slot,
                                genesis_validators_root)
  return true
