APP_NAME = idiot
PROJECT_DIR = .
SWIFTFORMAT_VERSION = 0.55.5

.PHONY: install format build run clean all

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

clean:
	@echo "Cleaning build artifacts..."
	rm -rf "$(PROJECT_DIR)/build"
	xcodebuild -project "$(PROJECT_DIR)/$(APP_NAME).xcodeproj" -scheme "$(APP_NAME)" clean

all: install format build
