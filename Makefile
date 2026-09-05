BUILD_DIR=build
APP=$(BUILD_DIR)/mac-arm64/Plotter.app
BINARY=$(APP)/Contents/MacOS/Plotter

.PHONY: app
app: node_modules
	@npm run build
	@npx electron-builder --mac --dir
	@echo "Binary is at $(BINARY)"

.PHONY: check
check: node_modules
	@npx tsc --noEmit
	@npx vitest run

.PHONY: run
run: node_modules
	@npm run build
	@npx electron dist/main.js $(FILE)

node_modules: package.json
	@npm install
	@touch node_modules

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) dist
