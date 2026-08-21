# Builds the spicey-display SPICE helper against Homebrew's spice-gtk.
BREW    := /opt/homebrew
PKG     := PKG_CONFIG_PATH=$(BREW)/lib/pkgconfig pkg-config
MODULES := spice-client-gtk-3.0

CFLAGS  := -O2 -Wall -Wextra $(shell $(PKG) --cflags $(MODULES))
LDFLAGS := $(shell $(PKG) --libs $(MODULES))

spicey-display: spicey-display.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f spicey-display

.PHONY: clean
