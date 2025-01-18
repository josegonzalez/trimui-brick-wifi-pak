clean:
	rm -f bin/jq || true

build: bin/jq

bin/jq:
	curl -o bin/jq -sSL https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-arm64

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist
