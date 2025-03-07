pragma circom 2.1.5;

include "hash_two.circom";
include "../../../node_modules/circomlib/circuits/comparators.circom";
include "../../../node_modules/circomlib/circuits/bitify.circom";

include "utils/arrays.circom";
include "utils/numerical.circom";

template IsValidMerkleBranchOut(N) {
  signal input branch[N][256];
  signal input leaf[256];
  signal input root[256];
  signal input index;

  signal output out;

  component hashers[N];
  component isZero[N];
  component idx2Bits;  
  idx2Bits = Num2Bits(N+1);
  idx2Bits.in <== index;
  for(var i = 0; i < N; i++) {
    hashers[i] = HashTwo();
    isZero[i] = IsZero();

    isZero[i].in <== idx2Bits.out[i];

    var current[256];

    for(var j = 0; j < 256; j++) {
      current[j] = i == 0 ? leaf[j] : hashers[i - 1].out[j];
    }

    for(var j = 0; j < 256; j++) {
      hashers[i].in[0][j] <== (current[j] - branch[i][j]) * isZero[i].out + branch[i][j];
      hashers[i].in[1][j] <== (branch[i][j] - current[j]) * isZero[i].out + current[j];
    }
  }

  out <== IsEqualArrays(256)([root, hashers[N - 1].out]);
}
