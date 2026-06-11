.PHONY: demo examples clean

EXAMPLES := $(wildcard examples/*.tex)

demo:
	lualatex -output-directory=examples examples/demo.tex

examples:
	@for file in $(EXAMPLES); do \
		echo "Compiling $$file"; \
		lualatex -output-directory=examples "$$file" || exit 1; \
	done

clean:
	rm -f *.aux *.log *.out *.toc *.synctex.gz *.fls *.fdb_latexmk *.pdf
	rm -f examples/*.aux examples/*.log examples/*.out examples/*.toc examples/*.synctex.gz examples/*.fls examples/*.fdb_latexmk examples/*.pdf
