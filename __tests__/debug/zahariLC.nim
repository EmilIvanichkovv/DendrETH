import
  json_serialization, blscurve,
  "/home/Emil/code/repos/metacraft-labs/DendrETH/__tests__/debug/lcw_json_serialization",
  # /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/eth2_apis/eth2_rest_serialization,
  # /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/datatypes/altair,
  # /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/crypto,
  /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/forks,
  # /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/eth2_merkleization,
  /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/spec/signatures,
  /home/Emil/code/repos/metacraft-labs/DendrETH/src/nim-light-client/light_client_utils,
  /home/Emil/code/repos/metacraft-labs/DendrETH/src/nim-light-client/light_client,


  /home/Emil/code/repos/metacraft-labs/DendrETH/vendor/nimbus-eth2/beacon_chain/networking/network_metadata

proc main =
  let
    bootstrap = LCWJson.loadFile(
      "/home/Emil/code/repos/metacraft-labs/DendrETH/vendor/eth2-light-client-updates/mainnet/snapshot.json",
      light_client_utils.LightClientBootstrap)
    u290 = LCWJson.loadFile(
      "/home/Emil/code/repos/metacraft-labs/DendrETH/vendor/eth2-light-client-updates/mainnet/updates/00290.json",
      light_client_utils.LightClientUpdate)
    u291 = LCWJson.loadFile(
      "/home/Emil/code/repos/metacraft-labs/DendrETH/vendor/eth2-light-client-updates/mainnet/updates/00291.json",
      light_client_utils.LightClientUpdate)

  let
    cfg = mainnetMetadata.cfg
    genesisValidatorsRoot = extractGenesisValidatorRootFromSnapshot(
      mainnetMetadata.genesisData)
    # fork = forkAtEpoch(cfg, u291.signature_slot.epoch)

  echo "GENESIS VALIDATORS ROOT ", genesisValidatorsRoot

  # var participant_pubkeys: seq[light_client_utils.ValidatorPubKey]
  # for i in 0 ..< u290.sync_aggregate.sync_committee_bits.len:
  #   if u290.sync_aggregate.sync_committee_bits[i]:
  #     participant_pubkeys.add u290.next_sync_committee.pubkeys.data[i]

  # echo "VERIFIED ", verify_sync_committee_signature(
  #   fork, genesisValidatorsRoot, u291.signature_slot - 1,
  #   hash_tree_root(u291.attested_header), participant_pubkeys,
  #   u291.sync_aggregate.sync_committee_signature)

  var aggregateKey{.noinit.}: AggregatePublicKey
  var initialized = false

  echo "BITS ", u291.sync_aggregate.sync_committee_bits

  # for i in 0 ..< u291.sync_aggregate.sync_committee_bits.len:
  #   echo u291.sync_aggregate.sync_committee_bits[i]
  #   if u291.sync_aggregate.sync_committee_bits[i]:
  #     let key = u290.next_sync_committee.pubkeys.data[i].loadValid
  #     if not initialized:
  #       init(aggregateKey, key)
  #       initialized = true
  #     else:
  #       aggregateKey.aggregate key

  # let aggregated = finish(aggregateKey)
  # echo "AGGREGATED KEY ", aggregated
  # let signingRoot = compute_sync_committee_message_signing_root(
  #   fork, genesisValidatorsRoot, u291.signature_slot - 1,
  #   hash_tree_root(u291.attested_header))

  let trusted_block_root = hash_tree_root(bootstrap.header)

  let store = initialize_light_client_store(trusted_block_root, bootstrap)

  template sync_aggregate(): auto = u290.sync_aggregate
  template sync_committee_bits(): auto = sync_aggregate.sync_committee_bits
  let num_active_participants = countOnes(sync_committee_bits).uint64
  let
    store_period = store.finalized_header.slot.sync_committee_period
    signature_period = u290.signature_slot.sync_committee_period
    is_next_sync_committee_known = store.is_next_sync_committee_known

  # Verify sync committee aggregate signature
  let sync_committee =
    if signature_period == store_period:
      unsafeAddr store.current_sync_committee
    else:
      unsafeAddr store.next_sync_committee
  var participant_pubkeys =
    newSeqOfCap[light_client_utils.ValidatorPubKey](num_active_participants)
  for idx, bit in sync_aggregate.sync_committee_bits:
    if bit:
      participant_pubkeys.add(sync_committee.pubkeys.data[idx])
  let
    fork_version = forkVersionAtEpoch(u290.signature_slot.epoch)
    domain = compute_domain(
      light_client_utils.DOMAIN_SYNC_COMMITTEE, fork_version, genesis_validators_root)
    signing_root = compute_signing_root(u290.attested_header, domain)
  echo 5

  echo "VERIFY2 ",
    blsFastAggregateVerify(participant_pubkeys, signingRoot.data, u290.sync_aggregate.sync_committee_signature)

main()
