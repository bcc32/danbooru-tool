# v0.3.0 2018-04-15 Cambridge, MA, USA

- Require Jane Street libs version v0.11.0.

# v0.2.2 2018-03-03 Cambridge, MA, USA

- Actually fix the bug I tried to fix in v0.2.1. I hope.
- Bugfix: catch URI resolution errors; should prevent a single URI resolution
  error from causing all downloads to fail (not sure if this is actually
  useful).

# v0.2.1 2018-02-08 Cambridge, MA, USA

- Bugfix: flush log before exiting; fix log messages that were dropped because
  they would have been flushed after all downloads completed.
- Use ```Auto`` manpage format when invoked with no arguments.

# v0.2.0 2018-02-01 Cambridge, MA, USA

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
