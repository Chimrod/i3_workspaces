all:
	dune build @install

clean:
	dune clean

docs:
	dune build @doc

install:
	dune install --prefix "/usr" -p i3_workspaces

deps:
	opam install . --deps-only

.PHONY: all clean
