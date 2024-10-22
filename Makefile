
BUILD_DIR=build
BINARY=$(BUILD_DIR)/Plotter.app/Contents/MacOS/Plotter

.PHONY: app
app:
	@xcodebuild clean build CONFIGURATION_BUILD_DIR=$(BUILD_DIR) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -scheme Plotter -project Plotter.xcodeproj
	@echo "Binary is at $(BINARY)"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

