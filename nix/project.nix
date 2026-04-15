{ CHaP, indexState, pkgs, mkdocs, ... }:

let
  indexTool = { index-state = indexState; };
  fix-libs = { lib, pkgs, ... }: {
    packages.cardano-crypto-praos.components.library.pkgconfig =
      lib.mkForce [ [ pkgs.libsodium-vrf ] ];
    packages.cardano-crypto-class.components.library.pkgconfig =
      lib.mkForce [[ pkgs.libsodium-vrf pkgs.secp256k1 pkgs.libblst ]];
    packages.cardano-lmdb.components.library.pkgconfig =
      lib.mkForce [ [ pkgs.lmdb ] ];
    packages.blockio-uring.components.library.pkgconfig =
      lib.mkForce [ [ pkgs.liburing ] ];
  };
  shell = { pkgs, ... }: {
    tools = {
      cabal = indexTool;
      # cabal-fmt doesn't support base-4.21 (GHC 9.12) yet
      # cabal-fmt = indexTool;
      haskell-language-server = {
        index-state = indexState;
        version = "latest";
        modules = [{
          packages.ghc-lib-parser.postPatch = ''
            if [ -f compiler/cbits/genSym.c ] \
                && grep -q 'atomic_inc64' \
                   compiler/cbits/genSym.c; then
              substituteInPlace compiler/cbits/genSym.c \
                --replace-fail 'atomic_inc64' 'atomic_inc'
            fi
          '';
        }];
      };
      hoogle = indexTool;
      fourmolu = indexTool;
      hlint = indexTool;
    };
    # GHC 9.12.2 tyConStupidTheta haddock panic on several deps
    withHoogle = false;
    buildInputs = with pkgs; [
      just
      nixfmt-classic
      pkgs.mkdocs
      mkdocs.from-nixpkgs
      mkdocs.markdown-callouts
      lmdb
      liburing
    ];
    shellHook = ''
      echo "cardano-ledger-read dev shell"
    '';
  };
  mkProject = ctx@{ lib, pkgs, ... }: {
    name = "cardano-ledger-read";
    src = ./..;
    compiler-nix-name = "ghc9122";

    modules = [
      fix-libs
      {
        packages.cardano-ledger-read.ghcOptions = [ "-Wno-deriving-typeable" ];
      }
    ];
    inputMap = { "https://chap.intersectmbo.org/" = CHaP; };
  };

  project = pkgs.haskell-nix.cabalProject' mkProject;

  quality-shell = { pkgs, ... }: {
    tools = {
      # cabal-fmt doesn't support base-4.21 (GHC 9.12) yet
      # cabal-fmt = indexTool;
      fourmolu = indexTool;
      hlint = indexTool;
    };
    withHoogle = false;
    buildInputs = [ pkgs.nixfmt-classic pkgs.just ];
  };

in {
  devShells = {
    default = project.shellFor shell;
    quality = project.shellFor quality-shell;
  };
  packages.cardano-ledger-read-tests =
    project.hsPkgs.cardano-ledger-read.components.tests.unit-tests;
  inherit project;
}
