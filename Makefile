TAG ?= latest
PAK_NAME := $(shell jq -r .label config.json)

clean:
	rm -f bin/jq || true
	rm -f bin/sdl2imgshow || true
	rm -f bin/minui-keyboard-tg5040 || true
	rm -f bin/minui-list-tg5040 || true
	rm -f res/fonts/BPreplayBold.otf || true

build: bin/jq bin/minui-keyboard-tg5040 bin/minui-list-tg5040 bin/sdl2imgshow res/fonts/BPreplayBold.otf

bin/jq:
	curl -o bin/jq -sSL https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-arm64

bin/minui-keyboard-tg5040:
	curl -o bin/minui-keyboard-tg5040 -sSL https://github.com/josegonzalez/minui-keyboard/releases/download/0.1.0/minui-keyboard-tg5040
	chmod +x bin/minui-keyboard-tg5040

bin/minui-list-tg5040:
	curl -o bin/minui-list-tg5040 -sSL https://github.com/josegonzalez/minui-list/releases/download/0.1.0/minui-list-tg5040
	chmod +x bin/minui-list-tg5040

bin/sdl2imgshow:
	docker buildx build --platform linux/arm64 --load -f Dockerfile.sdl2imgshow --progress plain -t app/sdl2imgshow:$(TAG) .
	docker container create --name extract app/sdl2imgshow:$(TAG)
	docker container cp extract:/go/src/github.com/kloptops/sdl2imgshow/build/sdl2imgshow bin/sdl2imgshow
	docker container rm extract
	chmod +x bin/sdl2imgshow

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist

res/fonts/BPreplayBold.otf:
	mkdir -p res/fonts
	curl -sSL -o res/fonts/BPreplayBold.otf "https://raw.githubusercontent.com/shauninman/MinUI/refs/heads/main/skeleton/SYSTEM/res/BPreplayBold-unhinted.otf"
