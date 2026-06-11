demo:
	lualatex -output-directory=examples examples/demo.tex

clean:
	rm -f examples/*.aux examples/*.log examples/*.pdf
