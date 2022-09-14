import { dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import glob_ from 'glob';
const glob = glob_.sync;
import { ssz } from '@lodestar/types';
import { ArrayType } from '@chainsafe/ssz';

import { compileNimFileToWasm } from '../src/ts-utils/compile-nim-to-wasm';
import {
  loadWasm,
  readJson,
  marshalSzzObjectToWasm,
  marshalArrayToWasm,
  WasmError,
  throwWasmException,
  readMemory,
} from '../src/ts-utils/wasm-utils';
import { hexToArray } from '../src/ts-utils/hex-utils';
import { SSZSpecTypes } from '../src/ts-utils/sszSpecTypes';

import BOOTSTRAP from '../vendor/eth2-light-client-updates/mainnet/bootstrap.json';
import UPDATE from '../vendor/eth2-light-client-updates/mainnet/updates/00290.json';
interface NimTestState<T extends WebAssembly.Exports = {}> {
  exports: T;
  logMessages: string[];
  wasmFilePath: string;
}

describe('Light Client in Nim compiled to Wasm', () => {
  const filesToTest = glob(
    dirname(fileURLToPath(import.meta.url)) + '/nimLightClient/*.nim',
    {
      ignore: '**/panicoverride\\.nim',
    },
  );

  const perFileState: Record<string, NimTestState> = {};

  function testNimToWasmFile<T extends WebAssembly.Exports = {}>(
    testName: string,
    path: string,
    func: (state: NimTestState<T>) => void,
  ) {
    test(`Testing '${path}': '${testName}'`, () =>
      func(perFileState[path] as NimTestState<T>));
  }

  beforeAll(async () => {
    await Promise.all(
      filesToTest.map(async nimFilePath => {
        const wasmFilePath = (await compileNimFileToWasm(nimFilePath))
          .outputFileName;
        const exports = await loadWasm<{}>({
          from: { filepath: wasmFilePath },
          importObject: {},
        });
        perFileState[basename(nimFilePath)] = {
          wasmFilePath,
          logMessages: [],
          exports,
        };
      }),
    );
  }, 20000 /* timeout in milliseconds */);

  // testNimToWasmFile<{
  //   assertLCFailTest: (a: number) => any;
  //   memory: WebAssembly.Memory;
  // }>(
  //   'Test triggering `assertLC` in nim module',
  //   'assertLCTest.nim',
  //   ({ exports, logMessages }) => {
  //     expect(() => {
  //       exports.assertLCFailTest(42);
  //     }).toThrow(new WasmError('Invalid Block'));
  //   },
  // );

  // testNimToWasmFile<{
  //   eth2DigestCompare: (a: Uint8Array) => Boolean;
  //   memory: WebAssembly.Memory;
  // }>('Compare eth2Digests', 'eth2Digest.nim', ({ exports, logMessages }) => {
  //   const correctBlockRoot =
  //     'ca6ddab42853a7aef751e6c2bf38b4ddb79a06a1f971201dcf28b0f2db2c0d61';
  //   const correctBlockRootBuffer = hexToArray(correctBlockRoot);
  //   var blockRootArray = new Uint8Array(exports.memory.buffer, 0, 32);
  //   blockRootArray.set(correctBlockRootBuffer);
  //   const correctTestRes = exports.eth2DigestCompare(blockRootArray);
  //   expect(correctTestRes).toStrictEqual(1);

  //   const incorrectBlockRoot =
  //     'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  //   const incorrectBlockRootBuffer = hexToArray(incorrectBlockRoot);
  //   var blockRootArray = new Uint8Array(exports.memory.buffer, 0, 32);
  //   blockRootArray.set(incorrectBlockRootBuffer);
  //   const incorrectTestRes = exports.eth2DigestCompare(blockRootArray);
  //   expect(incorrectTestRes).toStrictEqual(0);
  // });

  // testNimToWasmFile<{
  //   allocMemory: (a: number) => any;
  //   beaconBlockHeaderCompare: (a: number, b: number) => any;
  //   memory: WebAssembly.Memory;
  // }>(
  //   'Compare Beacon Block Headers',
  //   'beaconBlockHeader.nim',
  //   ({ exports, logMessages }) => {
  //     const testBeaconBlockHeader = ssz.phase0.BeaconBlockHeader.fromJson({
  //       slot: 3566048,
  //       proposer_index: 265275,
  //       parent_root:
  //         '0x6d8394a7292d616d8825f139b09fc4dca581a9c0af44499b3283b2dfda346762',
  //       state_root:
  //         '0x2176c5be4719af3e4ac67e12c55e273468791becc5ee60b4e430a05fd289acdd',
  //       body_root:
  //         '0x916babc5bb75209f7a279ed8dd2545721ea3d6b2b6ab331c74dd4247db172b8b',
  //     });

  //     const { startOffset, length } = marshalSzzObjectToWasm(
  //       exports,
  //       testBeaconBlockHeader,
  //       ssz.phase0.BeaconBlockHeader,
  //     );

  //     expect(
  //       exports.beaconBlockHeaderCompare(startOffset, length),
  //     ).toStrictEqual(1);
  //   },
  // );

  // testNimToWasmFile<{
  //   allocMemory: (a: number) => any;
  //   initializeLightClientStoreTest: (a: number, b: number) => any;
  //   memory: WebAssembly.Memory;
  // }>(
  //   'Test `initialize_light_client_store`',
  //   'initializeLightClientStore.nim',
  //   ({ exports, logMessages }) => {
  //     const header = ssz.phase0.BeaconBlockHeader.fromJson(BOOTSTRAP.header);
  //     const { startOffset: headerStartOffset, length: headerLength } =
  //       marshalSzzObjectToWasm(exports, header, ssz.phase0.BeaconBlockHeader);
  //     const bootstrap = SSZSpecTypes.LightClientBootstrap.fromJson(BOOTSTRAP);
  //     const { startOffset: bootstrapStartOffset, length: bootstrapLength } =
  //       marshalSzzObjectToWasm(
  //         exports,
  //         bootstrap,
  //         SSZSpecTypes.LightClientBootstrap,
  //       );
  //     expect(
  //       exports.initializeLightClientStoreTest(
  //         headerStartOffset,
  //         bootstrapStartOffset,
  //       ),
  //     ).toStrictEqual(1);
  //   },
  // );

  //   testNimToWasmFile<{
  //     allocMemory: (a: number) => any;
  //     validateLightClientUpdateTest: (a: number, b: number, c: number) => any;
  //     memory: WebAssembly.Memory;
  //   }>(
  //     'Test `validate_light_client_update`',
  //     'validateLightClientUpdate.nim',
  //     ({ exports, logMessages }) => {
  //       const header = ssz.phase0.BeaconBlockHeader.fromJson(
  //         BOOTSTRAP.header,
  //       );
  //       const { startOffset: headerStartOffset, length: headerLength } =
  //         marshalSzzObjectToWasm(exports, header, ssz.phase0.BeaconBlockHeader);

  //       const bootstrap = SSZSpecTypes.LightClientBootstrap.fromJson(
  //         BOOTSTRAP,
  //       );
  //       const { startOffset: bootstrapStartOffset, length: bootstrapLength } =
  //         marshalSzzObjectToWasm(
  //           exports,
  //           bootstrap,
  //           SSZSpecTypes.LightClientBootstrap,
  //         );

  //       const update = SSZSpecTypes.LightClientUpdate.fromJson(UPDATE);
  //       const { startOffset: updateStartOffset, length: updateLength } =
  //         marshalSzzObjectToWasm(exports, update, SSZSpecTypes.LightClientUpdate);

  //       expect(
  //         exports.validateLightClientUpdateTest(
  //           headerStartOffset,
  //           bootstrapStartOffset,
  //           updateStartOffset,
  //         ),
  //       ).toStrictEqual(1);
  //     },
  //   );

  // testNimToWasmFile<{
  //   allocMemory: (a: number) => any;
  //   processLightClientUpdateTest: (a: number, b: number, c: number) => any;
  //   memory: WebAssembly.Memory;
  // }>(
  //   'Test `process_light_client_update` with one update',
  //   'processLightClientUpdate.nim',
  //   ({ exports, logMessages }) => {
  //     const header = ssz.phase0.BeaconBlockHeader.fromJson(
  //       BOOTSTRAP.header,
  //     );
  //     const { startOffset: headerStartOffset, length: headerLength } =
  //       marshalSzzObjectToWasm(exports, header, ssz.phase0.BeaconBlockHeader);

  //     const bootstrap = SSZSpecTypes.LightClientBootstrap.fromJson(
  //       BOOTSTRAP,
  //     );
  //     const { startOffset: bootstrapStartOffset, length: bootstrapLength } =
  //       marshalSzzObjectToWasm(
  //         exports,
  //         bootstrap,
  //         SSZSpecTypes.LightClientBootstrap,
  //       );

  //     const update = SSZSpecTypes.LightClientUpdate.fromJson(UPDATE);
  //     const { startOffset: updateStartOffset, length: updateLength } =
  //       marshalSzzObjectToWasm(exports, update, SSZSpecTypes.LightClientUpdate);

  //     expect(
  //       exports.processLightClientUpdateTest(
  //         headerStartOffset,
  //         bootstrapStartOffset,
  //         updateStartOffset,
  //       ),
  //     ).toStrictEqual(1);
  //   },
  // );

  testNimToWasmFile<{
    allocMemory: (a: number) => any;
    processLightClientUpdatesTest: (a: number, b: number, c: number) => any;
    memory: WebAssembly.Memory;
  }>(
    'Test `process_light_client_update` with one update',
    'processLightClientUpdates.nim',
    async ({ exports, logMessages }) => {
      const updates = glob(
        dirname(fileURLToPath(import.meta.url)) +
          '../../vendor/eth2-light-client-updates/mainnet/updates/*.json',
        {
          ignore: '**/panicoverride\\.nim',
        },
      );
      const header = ssz.phase0.BeaconBlockHeader.fromJson(
        BOOTSTRAP.header,
      );
      const { startOffset: headerStartOffset, length: headerLength } =
        marshalSzzObjectToWasm(exports, header, ssz.phase0.BeaconBlockHeader);

      const bootstrap = SSZSpecTypes.LightClientBootstrap.fromJson(BOOTSTRAP);
      const { startOffset: bootstrapStartOffset, length: bootstrapLength } =
        marshalSzzObjectToWasm(
          exports,
          bootstrap,
          SSZSpecTypes.LightClientBootstrap,
        );

      var updatesOffsets: Array<number> = [];
      const curUpdate = await readJson(updates[0]);
      const update = SSZSpecTypes.LightClientUpdate.fromJson(curUpdate);
      const { startOffset: updateStartOffset, length: updateLength } =
      marshalSzzObjectToWasm(
        exports,
        update,
        SSZSpecTypes.LightClientUpdate,
      );


      for (const el of updates) {
        const curUpdate = await readJson(el);
        const update = SSZSpecTypes.LightClientUpdate.fromJson(curUpdate);
        // console.log(update)
        const { startOffset: updateStartOffset, length: updateLength } =
          marshalSzzObjectToWasm(
            exports,
            update,
            SSZSpecTypes.LightClientUpdate,
          );
        updatesOffsets.push(updateStartOffset);
      }

      const { startOffset: updatesArrStartOffset, length: updatesArrLength } =
        marshalArrayToWasm(exports, updatesOffsets);
      console.log(updatesOffsets)
      // console.log(updatesArrStartOffset)


      expect(
        exports.processLightClientUpdatesTest(
          headerStartOffset,
          bootstrapStartOffset,
          headerStartOffset,
        ),
      ).toStrictEqual(1);
    },
  );
});
