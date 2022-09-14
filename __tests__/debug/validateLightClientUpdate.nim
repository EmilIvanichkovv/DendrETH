when defined(emcc):
  {.emit: "#include <emscripten.h>".}
  {.pragma: wasmPragma, cdecl, exportc, dynlib, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".}
else:
  {.pragma: wasmPragma, cdecl, exportc, dynlib.}

from nimcrypto/hash import MDigest, fromHex

import ../../src/nim-light-client/light_client_utils
import ../nimLightClient/helpers/helpers
from ../../src/nim-light-client/light_client
  import initialize_light_client_store, validate_light_client_update
import "/home/Emil/code/repos/metacraft-labs/DendrETH/__tests__/debug/lcw_json_serialization"
let a = 5
echo a

let
  bootstrapNim = LCWJson.loadFile(
    "/home/Emil/code/repos/metacraft-labs/DendrETH/vendor/eth2-light-client-updates/prater/bootstrap.json",
    light_client_utils.LightClientBootstrap)
  firstUpdate = LCWJson.loadFile(
    "/home/Emil/code/repos/metacraft-labs/DendrETH/vendor/eth2-light-client-updates/prater/updates/00143.json",
    light_client_utils.LightClientUpdate)

import data
proc validateLightClientUpdateTest(
    dataRoot: pointer,
    dataBootstrap: pointer,
    dataUpdate: pointer,
    ): bool {.wasmPragma.} =
  var beaconBlockHeader: BeaconBlockHeader
  beaconBlockHeader.deserializeSSZType(headerrData.unsafeAddr, 112)

  var bootstrap: LightClientBootstrap
  bootstrap.deserializeSSZType(bootstrapData.unsafeAddr, 24896)

  var update: LightClientUpdate
  update.deserializeSSZType(updateData.unsafeAddr, sizeof(LightClientUpdate))

  let genesis_validators_root = MDigest[256].fromHex("4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95")
  let lightClientStore =
   initialize_light_client_store(hash_tree_root(bootstrapNim.header), bootstrapNim)

  echo bootstrapNim == bootstrap
  # echo bootstrapNim
  echo bootstrap

  # echo update == firstUpdate

  validate_light_client_update(lightClientStore,
                               firstUpdate,
                               firstUpdate.signature_slot,
                               genesis_validators_root)
let ressssss =  validateLightClientUpdateTest(a.unsafeAddr, a.unsafeAddr,a.unsafeAddr)
echo ressssss
