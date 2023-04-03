{pkgs}:
with pkgs; let
  nodejs = nodejs-18_x;
  llvm = llvmPackages_13;
  corepack = callPackage ../libs/nix/corepack-shims {inherit nodejs;};
in
  mkShell {
    packages = [
      nodejs
      corepack
      python38
      gmp
      nasm
      libsodium

      redis

      llvm.clang
    ];

    shellHook = ''
      set -e
      export NODE_OPTIONS="--experimental-vm-modules"
      export PATH="$PATH:$PWD/node_modules/.bin";
      export CC=clang

      echo "DendrETH container"
    '';
  }
