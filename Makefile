EXTRA_FLAGS :=

all:
	corebuild -pkg async -pkg yojson -pkg cohttp.async -cflags -warn-error,A $(EXTRA_FLAGS) main.native

clean:
	rm -rf _build main.native
