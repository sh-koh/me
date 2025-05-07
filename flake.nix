{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pr-overlay = {
      url = "github:thomashoneyman/purescript-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spago-drv = {
      url = "github:jeslie0/mkSpagoDerivation";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.ps-overlay.follows = "pr-overlay";
      inputs.registry.follows = "pr-registry";
      inputs.registry-index.follows = "pr-registry-index";
    };
    pr-registry = {
      url = "github:purescript/registry";
      flake = false;
    };
    pr-registry-index = {
      url = "github:purescript/registry-index";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          pkgs,
          system,
          self',
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.pr-overlay.overlays.default
              inputs.spago-drv.overlays.default
            ];
          };

          packages = {
            default = pkgs.mkSpagoDerivation {
              pname = "me";
              version = "0.1.0.0";
              src = ./.;
              spagoYaml = ./spago.yaml;
              spagoLock = ./spago.lock;

              nativeBuildInputs = with pkgs; [
                esbuild
                purs-unstable
                spago-unstable
              ];

              buildPhase = ''
                mkdir -p $out
                spago bundle --outfile $out/main.js
              '';

              installPhase = ''
                cp dist/* $out
              '';
            };
          };

          devShells = {
            default = pkgs.mkShell {
              inputsFrom = [ self'.packages.default ];
              packages = with pkgs; [
                purescript-language-server-unstable
              ];
            };
          };
        };
    };
}
