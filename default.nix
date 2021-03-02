{ lib, nix-gitignore, buildDunePackage, async, async_ssl, cmdliner, core, cohttp
, cohttp-async, expect_test_helpers_async, expect_test_helpers_core, yojson }:

buildDunePackage rec {
  pname = "danbooru-tool";
  version = "0.4.1";
  useDune2 = true;
  src = nix-gitignore.gitignoreFilterSource lib.cleanSourceFilter [ ] ./.;
  checkInputs = [ expect_test_helpers_async expect_test_helpers_core ];
  buildInputs = [ async async_ssl cmdliner core cohttp cohttp-async yojson ];
  passthru.checkInputs = checkInputs;
  meta = { homepage = "https://github.com/bcc32/danbooru-tool"; };
}
