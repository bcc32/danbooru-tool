all:
	corebuild -pkg async -pkg yojson -pkg cohttp.async main.native

clean:
	rm -rf _build
