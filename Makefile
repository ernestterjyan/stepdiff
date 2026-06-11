.PHONY: demo examples test clean

EXAMPLES := $(wildcard examples/*.tex)
TESTS := $(wildcard tests/*.tex)

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

clean:
	rm -f *.aux *.log *.out *.toc *.synctex.gz *.fls *.fdb_latexmk *.pdf
	rm -f examples/*.aux examples/*.log examples/*.out examples/*.toc examples/*.synctex.gz examples/*.fls examples/*.fdb_latexmk examples/*.nav examples/*.snm examples/*.vrb examples/*.pdf
	rm -f tests/*.aux tests/*.log tests/*.out tests/*.toc tests/*.synctex.gz tests/*.fls tests/*.fdb_latexmk tests/*.nav tests/*.snm tests/*.vrb tests/*.pdf
