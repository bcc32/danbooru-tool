{ lib, nix-gitignore, buildDunePackage, async, async_ssl, cmdliner, core, cohttp
, cohttp-async, expect_test_helpers_async, expect_test_helpers_core, yojson }:

buildDunePackage {
  pname = "danbooru-tool";
  version = "0.4.1";
  useDune2 = true;
  src = nix-gitignore.gitignoreFilterSource lib.cleanSourceFilter [ ] ./.;
  buildInputs = [
    async
    async_ssl
    cmdliner
    core
    cohttp
    cohttp-async
    expect_test_helpers_async
    expect_test_helpers_core
    yojson
  ];
  meta = { homepage = "https://github.com/bcc32/danbooru-tool"; };
}
