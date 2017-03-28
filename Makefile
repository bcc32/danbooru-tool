EXTRA_FLAGS :=
PKGS := core,async,cohttp.async,yojson
SRC_DIR := src

all: $(SRC_DIR)/main.native

%.native: %.ml
	corebuild -pkgs $(PKGS) -cflags -warn-error,A $(EXTRA_FLAGS) $@

clean:
	rm -rf _build main.native

.PHONY: all clean
