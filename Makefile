BUILD_DIR=build
APP=$(BUILD_DIR)/mac-arm64/Plotter.app
BINARY=$(APP)/Contents/MacOS/Plotter
ICNS=icon/Plotter.icns

.PHONY: app
app: node_modules
	@test -f $(ICNS) || { echo "Missing $(ICNS). Run 'make icon'."; exit 1; }
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

# The icon is generated but committed, so building never has to run this. Run it
# by hand after changing icon/draw-icon.ts, and commit the result.
.PHONY: icon
icon: node_modules
	@npm run icon

node_modules: package.json
	@npm install
	@touch node_modules

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) dist icon/Plotter.iconset icon/*.js icon/*.js.map
