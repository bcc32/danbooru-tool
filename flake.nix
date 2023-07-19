{
  description =
    "A simple tool for downloading posts from danbooru image boards";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlays.url = "github:nix-ocaml/nix-overlays";
    ocaml-overlays.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, nixpkgs, ocaml-overlays }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ocaml-overlays.overlays.default ];
        };
      in with pkgs; rec {
        devShells.default = mkShell {
          inputsFrom = [ packages.default ];
          buildInputs = packages.default.checkInputs
            ++ lib.optional stdenv.isLinux inotify-tools ++ [
              ocamlPackages.merlin
              ocamlformat
              ocamlPackages.ocp-indent
              ocamlPackages.utop
            ];
        };

        packages.default = ocamlPackages.buildDunePackage rec {
          pname = "danbooru-tool";
          version = "0.4.1";
          useDune2 = true;
          src = ./.;
          buildInputs = with ocamlPackages; [
            async
            async_ssl
            cmdliner
            core
            cohttp
            cohttp-async
            yojson
          ];
          checkInputs = with ocamlPackages; [
            expect_test_helpers_async
            expect_test_helpers_core
          ];
          passthru.checkInputs = checkInputs;
          meta = { homepage = "https://github.com/bcc32/danbooru-tool"; };
        };
      });
}
