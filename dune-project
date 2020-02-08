(lang dune 2.0)
(name danbooru-tool)
(generate_opam_files true)
(license MIT)
(authors "Aaron L. Zeng <me@bcc32.com>")
(maintainers "Aaron L. Zeng <me@bcc32.com>")
(source (github bcc32/danbooru-tool))
(package
 (name danbooru-tool)
 (synopsis "A simple tool for downloading posts from danbooru image boards")
 (depends
  (dune (>= 2.0))
  (topkg (and :build (>= 0.9.0)))
  (async (and (>= v0.13.0) (< v0.14.0)))
  (async_ssl (and (>= v0.13.0) (< v0.14.0)))
  cmdliner
  cohttp
  cohttp-async
  (core (and (>= v0.13.0) (< v0.14.0)))
  yojson))
