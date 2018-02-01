# v0.2.0 2018-01-31 Cambridge, MA, USA

- Package using [topkg][topkg].
- Migrate from `Core.Command` to a [cmdliner][cmdliner]-based CLI.
- Bugfix: make URI resolution more robust; fix incorrect requests due to
  relative file URLs and URLs with hosts.
- Bugfix: make _--max-connections_ consider the entire lifetime of an HTTP
  request, including reading the response body.
- Performance: don't buffer file contents in memory before writing to file.

# v0.1.2 2018-01-09

- Add _-d_ flag to set the output directory; will be created if it does not
  exist yet.
- Fix compatibility with Jane Street libs version 0.10.0.

# v0.1.1 2017-04-17

- Implement downloading by tag search.
- Add _-v_ verbose flag.
- Rename `AUTH` environment variable to `DANBOORU_AUTH`.

# v0.1 2017-03-27

- First release using [jbuilder][jbuilder].

[cmdliner]: https://github.com/dbuenzli/cmdliner
[jbuilder]: https://github.com/ocaml/dune
[topkg]: https://github.com/dbuenzli/topkg