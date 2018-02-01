# danbooru-tool

Download posts from Danbooru by ID, pool, or tag search.

## Install instructions

```sh
opam pin add danbooru-tool git://github.com/bcc32/danbooru-tool
```

## Usage

```sh
danbooru-tool post [-v] [-d output-dir] <id> [<id>...]
danbooru-tool pool [-v] [-d output-dir] <id> [-n|-md5]
danbooru-tool tags [-v] [-d output-dir] <tag> [<tag>...]
```

## Build instructions

```sh
# git clone and chdir
jbuilder build
jbuilder exec -- danbooru-tool --help
```
