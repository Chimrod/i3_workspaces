all:
	dune build @install

clean:
	dune clean

docs:
	dune build @doc

.PHONY: all clean
