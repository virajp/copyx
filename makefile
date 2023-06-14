.PHONY: run build

run:
	@dart run lib/main.dart $(ARGS)

build:
	@echo "Building the dart application ... "
	@dart compile exe lib/main.dart -o bin/xcopy
	