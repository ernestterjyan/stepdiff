.PHONY: demo examples test lua-test clean

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

clean:
	rm -f $(ROOT_CLEAN_FILES)
	rm -f $(EXAMPLE_CLEAN_FILES)
	rm -f $(TEST_CLEAN_FILES)
