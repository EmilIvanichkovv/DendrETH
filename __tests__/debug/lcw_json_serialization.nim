# beacon_chain
# Copyright (c) 2018-2022 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import std/typetraits
import stew/[assign2, results, base10, byteutils], presto/common,
       libp2p/peerid, serialization, json_serialization,
       json_serialization/std/[options, net, sets],
       chronicles
from /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/crypto import toRaw, fromHex
import /home/Emil/code/repos/metacraft-labs/DendrETH/src/nim-light-client/light_client_utils

# export
#   eth2_ssz_serialization, results, peerid, common, serialization, chronicles,
#   json_serialization, options, net, sets, rest_types, slashing_protection_common
Json.createFlavor LCWJson

from web3/ethtypes import BlockHash
export ethtypes.BlockHash

const
  DecimalSet = {'0' .. '9'}
    # Base10 (decimal) set of chars
  ValidatorKeySize = RawPubKeySize * 2
    # Size of `ValidatorPubKey` hexadecimal value (without 0x)
  ValidatorSigSize = RawSigSize * 2
    # Size of `ValidatorSig` hexadecimal value (without 0x)
  RootHashSize = sizeof(Eth2Digest) * 2
    # Size of `xxx_root` hexadecimal value (without 0x)
  Phase0Version =
    [byte('p'), byte('h'), byte('a'), byte('s'), byte('e'), byte('0')]
  AltairVersion =
    [byte('a'), byte('l'), byte('t'), byte('a'), byte('i'), byte('r')]

  ApplicationJsonMediaType* = MediaType.init("application/json")
  TextPlainMediaType* = MediaType.init("text/plain")
  UrlEncodedMediaType* = MediaType.init("application/x-www-form-urlencoded")

type

  EncodeTypes* =
    Slot

  # EncodeArrays* =
  #   seq[Attestation] |
  #   seq[PrepareBeaconProposer] |
  #   seq[RemoteKeystoreInfo] |
  #   seq[RestCommitteeSubscription] |
  #   seq[RestSignedContributionAndProof] |
  #   seq[RestSyncCommitteeMessage] |
  #   seq[RestSyncCommitteeSubscription] |
  #   seq[SignedAggregateAndProof] |
  #   seq[SignedValidatorRegistrationV1] |
  #   seq[ValidatorIndex]

  DecodeTypes* =
    Slot

when (NimMajor, NimMinor) < (1, 4):
  {.push raises: [Defect].}
else:
  {.push raises: [].}

template hexOriginal(data: openArray[byte]): string =
  to0xHex(data)

## uint64
proc writeValue*(w: var JsonWriter[LCWJson], value: uint64) {.
     raises: [IOError, Defect].} =
  writeValue(w, Base10.toString(value))

proc readValue*(reader: var JsonReader[LCWJson], value: var uint64) {.
     raises: [IOError, SerializationError, Defect].} =
  let svalue = reader.readValue(string)
  let res = Base10.decode(uint64, svalue)
  if res.isOk():
    value = res.get()
  else:
    reader.raiseUnexpectedValue($res.error() & ": " & svalue)

proc writeValue*(w: var JsonWriter[LCWJson], value: uint8) {.
     raises: [IOError, Defect].} =
  writeValue(w, Base10.toString(value))

proc readValue*(reader: var JsonReader[LCWJson], value: var uint8) {.
     raises: [IOError, SerializationError, Defect].} =
  let svalue = reader.readValue(string)
  let res = Base10.decode(uint8, svalue)
  if res.isOk():
    value = res.get()
  else:
    reader.raiseUnexpectedValue($res.error() & ": " & svalue)

## UInt256
proc writeValue*(w: var JsonWriter[LCWJson], value: UInt256) {.
     raises: [IOError, Defect].} =
  writeValue(w, toString(value))

proc readValue*(reader: var JsonReader[LCWJson], value: var UInt256) {.
     raises: [IOError, SerializationError, Defect].} =
  let svalue = reader.readValue(string)
  try:
    value = parse(svalue, UInt256, 10)
  except ValueError:
    raiseUnexpectedValue(reader,
                         "UInt256 value should be a valid decimal string")

## Slot
proc writeValue*(writer: var JsonWriter[LCWJson], value: Slot) {.
     raises: [IOError, Defect].} =
  writeValue(writer, Base10.toString(uint64(value)))

proc readValue*(reader: var JsonReader[LCWJson], value: var Slot) {.
     raises: [IOError, SerializationError, Defect].} =
  let svalue = reader.readValue(string)
  let res = Base10.decode(uint64, svalue)
  if res.isOk():
    value = Slot(res.get())
  else:
    reader.raiseUnexpectedValue($res.error())

## Epoch
proc writeValue*(writer: var JsonWriter[LCWJson], value: Epoch) {.
     raises: [IOError, Defect].} =
  writeValue(writer, Base10.toString(uint64(value)))

proc readValue*(reader: var JsonReader[LCWJson], value: var Epoch) {.
     raises: [IOError, SerializationError, Defect].} =
  let svalue = reader.readValue(string)
  let res = Base10.decode(uint64, svalue)
  if res.isOk():
    value = Epoch(res.get())
  else:
    reader.raiseUnexpectedValue($res.error())

## ValidatorSig
proc writeValue*(writer: var JsonWriter[LCWJson], value: ValidatorSig) {.
     raises: [IOError, Defect].} =
  writeValue(writer, hexOriginal(toRaw(value)))

proc readValue*(reader: var JsonReader[LCWJson], value: var ValidatorSig) {.
     raises: [IOError, SerializationError, Defect].} =
  let hexValue = reader.readValue(string)
  let res = ValidatorSig.fromHex(hexValue)
  if res.isOk():
    value = res.get()
  else:
    reader.raiseUnexpectedValue($res.error())

## ValidatorPubKey
proc writeValue*(writer: var JsonWriter[LCWJson], value: ValidatorPubKey) {.
     raises: [IOError, Defect].} =
  writeValue(writer, hexOriginal(toRaw(value)))

proc readValue*(reader: var JsonReader[LCWJson], value: var ValidatorPubKey) {.
     raises: [IOError, SerializationError, Defect].} =
  let hexValue = reader.readValue(string)
  let res = ValidatorPubKey.fromHex(hexValue)
  if res.isOk():
    value = res.get()
  else:
    reader.raiseUnexpectedValue($res.error())

## BitSeq
proc readValue*(reader: var JsonReader[LCWJson], value: var BitSeq) {.
     raises: [IOError, SerializationError, Defect].} =
  try:
    value = BitSeq hexToSeqByte(reader.readValue(string))
  except ValueError:
    raiseUnexpectedValue(reader, "A BitSeq value should be a valid hex string")

proc writeValue*(writer: var JsonWriter[LCWJson], value: BitSeq) {.
     raises: [IOError, Defect].} =
  writeValue(writer, hexOriginal(value.bytes()))

## BitList
proc readValue*(reader: var JsonReader[LCWJson], value: var BitList) {.
     raises: [IOError, SerializationError, Defect].} =
  type T = type(value)
  value = T readValue(reader, BitSeq)

proc writeValue*(writer: var JsonWriter[LCWJson], value: BitList) {.
     raises: [IOError, Defect].} =
  writeValue(writer, BitSeq value)

## BitArray
proc readValue*(reader: var JsonReader[LCWJson], value: var BitArray) {.
     raises: [IOError, SerializationError, Defect].} =
  try:
    hexToByteArray(readValue(reader, string), value.bytes)
  except ValueError:
    raiseUnexpectedValue(reader,
                         "A BitArray value should be a valid hex string")

proc writeValue*(writer: var JsonWriter[LCWJson], value: BitArray) {.
     raises: [IOError, Defect].} =
  writeValue(writer, hexOriginal(value.bytes))

## BlockHash
proc readValue*(reader: var JsonReader[LCWJson], value: var BlockHash) {.
     raises: [IOError, SerializationError, Defect].} =
  try:
    hexToByteArray(reader.readValue(string), distinctBase(value))
  except ValueError:
    raiseUnexpectedValue(reader,
                         "BlockHash value should be a valid hex string")

proc writeValue*(writer: var JsonWriter[LCWJson], value: BlockHash) {.
     raises: [IOError, Defect].} =
  writeValue(writer, hexOriginal(distinctBase(value)))

## Eth2Digest
proc readValue*(reader: var JsonReader[LCWJson], value: var Eth2Digest) {.
     raises: [IOError, SerializationError, Defect].} =
  try:
    hexToByteArray(reader.readValue(string), value.data)
  except ValueError:
    raiseUnexpectedValue(reader,
                         "Eth2Digest value should be a valid hex string")

proc writeValue*(writer: var JsonWriter[LCWJson], value: Eth2Digest) {.
     raises: [IOError, Defect].} =
  writeValue(writer, hexOriginal(value.data))

## HashArray
proc readValue*(reader: var JsonReader[LCWJson], value: var HashArray) {.
     raises: [IOError, SerializationError, Defect].} =
  readValue(reader, value.data)

proc writeValue*(writer: var JsonWriter[LCWJson], value: HashArray) {.
     raises: [IOError, Defect].} =
  writeValue(writer, value.data)

## HashList
proc readValue*(reader: var JsonReader[LCWJson], value: var HashList) {.
     raises: [IOError, SerializationError, Defect].} =
  readValue(reader, value.data)
  value.resetCache()

proc writeValue*(writer: var JsonWriter[LCWJson], value: HashList) {.
     raises: [IOError, Defect].} =
  writeValue(writer, value.data)
