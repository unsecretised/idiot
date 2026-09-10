APP_NAME = idiot
PROJECT_DIR = .
BUNDLE_ID = com.umangsurana.idiot
SIMULATOR_NAME = iPhone 17 Pro
DEVICE_NAME ?= iPhone
SWIFTFORMAT_VERSION = 0.55.5

.PHONY: install format build run build-ios run-ios build-device run-device clean all

install:
	@echo "Installing SwiftFormat $(SWIFTFORMAT_VERSION)..."
	@if ! command -v swiftformat &> /dev/null; then \
		brew install swiftformat || \
		mint install nicklockwood/SwiftFormat@$(SWIFTFORMAT_VERSION); \
	fi

format:
	@echo "Formatting Swift files..."
	swiftformat .

build: format
	@echo "Building $(APP_NAME)..."
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" build

run: format
	@echo "Running $(APP_NAME)..."
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" build
	open "$(PROJECT_DIR)/build/Release/$(APP_NAME).app" 2>/dev/null || \
		xcrun xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" -derivedDataPath "$(PROJECT_DIR)/build" build && \
		open "$(PROJECT_DIR)/build/Build/Products/Debug/$(APP_NAME).app"

build-ios: format
	@echo "Building $(APP_NAME) for iOS Simulator..."
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" \
		-destination "platform=iOS Simulator,name=$(SIMULATOR_NAME)" build

run-ios: format
	@echo "Running $(APP_NAME) on iOS Simulator..."
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" \
		-destination "platform=iOS Simulator,name=$(SIMULATOR_NAME)" \
		-derivedDataPath "$(PROJECT_DIR)/build" build
	open -a Simulator
	xcrun simctl boot $(SIMULATOR_NAME) 2>/dev/null || true
	xcrun simctl install booted "$(PROJECT_DIR)/build/Build/Products/Debug-iphonesimulator/$(APP_NAME).app"
	xcrun simctl launch booted $(BUNDLE_ID)

build-device: format
	@echo "Building $(APP_NAME) for physical iPhone..."
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" \
		-destination "generic/platform=iOS" -derivedDataPath "$(PROJECT_DIR)/build" \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration build

run-device: format
	@echo "Building and installing $(APP_NAME) on $(DEVICE_NAME)..."
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" \
		-destination "generic/platform=iOS" -derivedDataPath "$(PROJECT_DIR)/build" \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration build
	xcrun devicectl device install app --device "$(DEVICE_NAME)" \
		"$(PROJECT_DIR)/build/Build/Products/Debug-iphoneos/$(APP_NAME).app"
	xcrun devicectl device process launch --device "$(DEVICE_NAME)" $(BUNDLE_ID)

clean:
	@echo "Cleaning build artifacts..."
	rm -rf "$(PROJECT_DIR)/build"
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" clean

all: install format build
