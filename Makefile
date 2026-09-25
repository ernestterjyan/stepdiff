.PHONY: demo examples test lua-test manual ctan clean

VERSION := 1.1.1

EXAMPLES := $(sort $(wildcard examples/*.tex))
TESTS := $(sort $(wildcard tests/*.tex))

AUX_EXTENSIONS := \
	aux \
	log \
	out \
	toc \
	synctex.gz \
	fls \
	fdb_latexmk \
	nav \
	snm \
	vrb \
	pdf

ROOT_CLEAN_FILES := $(foreach ext,$(AUX_EXTENSIONS),*.$(ext))
EXAMPLE_CLEAN_FILES := $(foreach ext,$(AUX_EXTENSIONS),examples/*.$(ext))
TEST_CLEAN_FILES := $(foreach ext,$(AUX_EXTENSIONS),tests/*.$(ext))

demo:
	lualatex -output-directory=examples examples/demo.tex

examples:
	@for file in $(EXAMPLES); do \
		echo "Compiling $$file"; \
		lualatex -output-directory=examples "$$file" || exit 1; \
	done

test:
	@for file in $(TESTS); do \
		echo "Testing $$file"; \
		lualatex -output-directory=tests "$$file" || exit 1; \
	done
	$(MAKE) lua-test

lua-test:
	texlua lua-tests/run.lua

manual:
	lualatex -interaction=nonstopmode -halt-on-error stepdiff-manual.tex
	lualatex -interaction=nonstopmode -halt-on-error stepdiff-manual.tex

ctan: manual
	rm -rf dist/stepdiff dist/stepdiff-$(VERSION).zip
	mkdir -p dist/stepdiff
	cp README.md CHANGELOG.md LICENSE stepdiff.sty stepdiff.lua stepdiff-manual.tex stepdiff-manual.pdf dist/stepdiff/
	cp examples/demo.tex dist/stepdiff/stepdiff-demo.tex
	mkdir -p dist/stepdiff/docs/assets
	cp docs/assets/demo-preview.png dist/stepdiff/docs/assets/
	cd dist && zip -q -r stepdiff-$(VERSION).zip stepdiff

clean:
	rm -f $(ROOT_CLEAN_FILES)
	rm -f $(EXAMPLE_CLEAN_FILES)
	rm -f $(TEST_CLEAN_FILES)
