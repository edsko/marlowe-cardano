{ lib
, sources
, stdenv
, haskell-nix
, buildPackages
, writeShellScript
, checkMaterialization
, gitignore-nix
, R
, libsodium-vrf
, rPackages
, z3
, enableHaskellProfiling
, actus-tests
, source-repo-override
}:
let
  # The Hackage index-state from cabal.project
  index-state =
    let
      parseIndexState = rawCabalProject:
        let
          indexState = lib.lists.concatLists (
            lib.lists.filter (l: l != null)
              (map (l: builtins.match "^index-state: *(.*)" l)
                (lib.splitString "\n" rawCabalProject)));
        in
        lib.lists.head (indexState ++ [ null ]);
    in
    parseIndexState (builtins.readFile ../../../cabal.project);

  # The compiler that we are using.
  compiler-nix-name = "ghc8107";

  # The haskell project created by haskell-nix.stackProject'
  baseProject =
    { deferPluginErrors }:
    import ./haskell.nix {
      inherit lib haskell-nix R libsodium-vrf rPackages z3;
      inherit checkMaterialization compiler-nix-name gitignore-nix;
      inherit enableHaskellProfiling;
      inherit deferPluginErrors;
      inherit actus-tests;
      inherit source-repo-override;
    };
  project = baseProject { deferPluginErrors = false; };
  # The same as above, but this time with we defer plugin errors so that we
  # can build "all" (the interesting) haddocks that would otherwise fail.
  projectAllHaddock = baseProject { deferPluginErrors = true; };

  # All the packages defined by our project, including dependencies
  packages = project.hsPkgs;

  # Just the packages in the project
  projectPackages = haskell-nix.haskellLib.selectProjectPackages packages;
  projectPackagesAllHaddock = (haskell-nix.haskellLib.selectProjectPackages projectAllHaddock.hsPkgs) // {
    inherit (projectAllHaddock.hsPkgs) plutus-core plutus-tx plutus-tx-plugin plutus-ledger-api plutus-pab plutus-contract plutus-chain-index-core plutus-chain-index plutus-ledger;
  };

  extraPackages = import ./extra.nix {
    inherit stdenv lib haskell-nix sources buildPackages writeShellScript;
    inherit index-state checkMaterialization compiler-nix-name;
  };

in
rec {
  inherit index-state compiler-nix-name project projectAllHaddock projectPackages projectPackagesAllHaddock packages;
  inherit extraPackages;
}
