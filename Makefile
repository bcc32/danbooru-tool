all:
	corebuild -pkg async -pkg yojson -pkg cohttp.async -cflags -warn-error,A main.native

clean:
	rm -rf _build
