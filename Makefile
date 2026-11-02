PYTHON ?= python3
FONT ?= src/JetBrainsMono-Bold.woff2

.PHONY: all paths check clean

all: install.sh assets/preview.svg

install.sh: src/install.sh.in src/paths.json src/icons.py src/build_installer.py
	$(PYTHON) src/build_installer.py

assets/preview.svg: src/paths.json src/icons.py src/build_preview.py
	$(PYTHON) src/build_preview.py

# Needs fonttools, brotli and the font file; not part of the default build.
paths:
	$(PYTHON) src/generate_paths.py $(FONT)

check: install.sh
	bash -n install.sh
	shellcheck install.sh

clean:
	rm -rf src/__pycache__
