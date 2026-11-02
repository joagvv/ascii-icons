PYTHON ?= python3
FONT ?= src/JetBrainsMono-Bold.woff2

.PHONY: all glyphs names check test clean

all: install.sh assets/preview.svg

install.sh: src/install.sh.in src/glyphs.json src/names.txt src/icons.py \
		src/labels.py src/catalog.py src/build_installer.py
	$(PYTHON) src/build_installer.py

assets/preview.svg: src/glyphs.json src/render.py src/build_preview.py
	$(PYTHON) src/build_preview.py

# Needs fonttools, brotli and the font file; not part of the default build.
glyphs:
	$(PYTHON) src/generate_glyphs.py $(FONT)

# Refreshes the application list from Papirus and elementary-xfce.
names:
	$(PYTHON) src/fetch_names.py

check: install.sh
	bash -n install.sh
	shellcheck install.sh

test: install.sh
	tests/install.sh

clean:
	rm -rf src/__pycache__
