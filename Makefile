# ==============================================================================
# Stack Wallet Universal Build Makefile
# Override variables if needed: make build-linux VERSION=3.0.0 BUILD_NUM=300
# ==============================================================================

APP_NAME  ?= stack_wallet
VERSION   ?= 2.1.0
BUILD_NUM ?= 210
FLUTTER   ?= flutter
DART      ?= dart

export PROTOC = $(shell which protoc 2>/dev/null)

.PHONY: help check-reqs check-reqs-windows check-macos-sdk init clean prebuild-unix prebuild-windows deps-linux build-linux build-macos build-ios build-android build-windows

help: ## Shows all available make commands
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- PREREQUISITES CHECK ---

check-reqs: ## Checks if essential build tools (Flutter, Rust, CMake, etc.) are installed
	@echo "Checking core prerequisites..."
	@command -v $(FLUTTER) >/dev/null 2>&1 || { echo >&2 "❌ Flutter is not installed. Aborting."; exit 1; }
	@command -v $(DART) >/dev/null 2>&1 || { echo >&2 "❌ Dart is not installed. Aborting."; exit 1; }
	@command -v cargo >/dev/null 2>&1 || { echo >&2 "❌ Rust (cargo) is not installed. Aborting."; exit 1; }
	@command -v rustup >/dev/null 2>&1 || { echo >&2 "❌ rustup is not installed. Aborting."; exit 1; }
	@command -v cmake >/dev/null 2>&1 || { echo >&2 "❌ CMake is not installed. Aborting."; exit 1; }
	@command -v meson >/dev/null 2>&1 || { echo >&2 "❌ Meson is not installed. Aborting."; exit 1; }
	@command -v pkg-config >/dev/null 2>&1 || { echo >&2 "❌ pkg-config is not installed. Aborting."; exit 1; }
	@echo "✅ All core CLI requirements found!"

check-macos-sdk: ## NEW: Specifically checks for full Xcode installation on macOS
ifeq ($(shell uname), Darwin)
	@echo "Checking macOS SDK requirements..."
	@xcode-select -p | grep -q "Xcode.app" || ( \
		echo "❌ ERROR: Full Xcode installation not detected!"; \
		echo "   The build requires the full Xcode app, not just Command Line Tools."; \
		echo "   Path should be: /Applications/Xcode.app/Contents/Developer"; \
		exit 1)
	@echo "✅ Xcode SDK path looks good."
endif

check-reqs-windows: ## Specific checks for Windows/WSL environments
	@echo "Checking Windows specific prerequisites..."
	@command -v wsl >/dev/null 2>&1 || { echo >&2 "❌ WSL is not installed. Aborting."; exit 1; }
	@echo "✅ Windows/WSL requirements found!"

# --- COMMON SETUP STEPS ---

init: ## Clones the repository and initializes all submodules
	git submodule update --init --recursive

clean: ## Cleans all Flutter, Dart, Rust, and flaky dependency artifacts
	@echo "1. Cleaning local Flutter and Rust artifacts..."
	@chmod -R u+w crypto_plugins/ 2>/dev/null || true
	$(FLUTTER) clean
	@if [ -f "Cargo.toml" ]; then cargo clean; fi
	
	@echo "2. Cleaning local platform specific artifacts..."
	rm -rf macos/Pods macos/Podfile.lock
	rm -rf ios/Pods ios/Podfile.lock
	rm -rf build/
	
	@echo "3. Cleaning flaky external dependency residues (Pub-Cache)..."
	@chmod -R u+w $(HOME)/.pub-cache/git/ 2>/dev/null || true
	@find $(HOME)/.pub-cache/git/ -type d \( -name "build" -o -name "target" \) \
		-path "*flutter_lib*" -exec rm -rf {} + 2>/dev/null || true
	@echo "All clean. You can now run build-macos or build-linux starting from a fresh state."

prebuild-unix: ## Executes the prebuild script (keys/parameters) for Unix systems
	cd scripts && ./prebuild.sh

prebuild-windows: ## Executes the prebuild script for Windows (via PowerShell)
	cd scripts && powershell.exe -ExecutionPolicy Bypass -File prebuild.ps1

patch-submodules: ## Patches non-portable sed calls and version logic in submodules
	@echo "Cleaning up old build artifacts..."
	@chmod -R u+w crypto_plugins/ 2>/dev/null || true
	@rm -rf crypto_plugins/*/scripts/macos/build
	@echo "Patching submodules for portability (Bash & Dart)..."
	@find crypto_plugins -name "build_all.sh" -exec sed -i.bak 's|/\$${OS}_VERSION/c\\.*|s\|/\\\*\$${OSX}_VERSION\\\*/.*\|/\\\*\$${OSX}_VERSION\\\*/ const \$${OSX}_VERSION = \\"$$COMMIT\\";\|g|g' {} \;
	@find crypto_plugins/frostdart -name "build_macos.dart" -type f -exec sed -i.bak 's/\["-i", ".bak",/\["-i.bak",/g' {} +
	@find crypto_plugins -name "*.bak" -delete
	@echo "All submodules patched and ready."

# --- LINUX ---

deps-linux: ## Builds Linux-specific secure storage dependencies
	cd scripts/linux && ./build_secure_storage_deps.sh

build-linux: check-reqs init patch-submodules prebuild-unix deps-linux
	@echo "1. Generating pubspec.yaml and building native crypto plugins..."
	cd scripts && yes yes | BUILD_ISAR_FROM_SOURCE=0 PROTOC=$$(which protoc) \
	bash -c 'rustup() { echo "1.89.0-stable"; echo "1.85.1-stable"; return 0; }; export -f rustup; ./build_app.sh -a $(APP_NAME) -p linux -v $(VERSION) -b $(BUILD_NUM) -f'
	@echo "2. Fetching Dart dependencies..."
	$(FLUTTER) pub get
	@echo "3. Building secp256k1 (coinlib)..."
	$(FLUTTER) pub run coinlib:build_linux
	@echo "4. Compiling Flutter App..."
	$(FLUTTER) build linux --release

# --- MACOS ---

build-macos: check-reqs check-macos-sdk init patch-submodules prebuild-unix ## Complete release build for macOS
	@echo "0. Repairing permissions and healing korrupt Xcode project..."
	@chmod -R u+w $(HOME)/.pub-cache/git/ 2>/dev/null || true
	@chmod -R u+w macos/ 2>/dev/null || true
	rm -rf macos/Runner.xcodeproj macos/Runner.xcworkspace
	$(FLUTTER) create --platforms=macos .
	
	@echo "1. Patching version placeholders..."
	./scripts/app_config/shared/update_version.sh -v $(VERSION) -b $(BUILD_NUM)
	
	@echo "2. Fetching Dart dependencies..."
	$(FLUTTER) pub get
	
	@echo "3. Generating app config and building native crypto plugins..."
	cd scripts && yes yes | BUILD_ISAR_FROM_SOURCE=0 \
	bash -c 'rustup() { echo "1.89.0-stable"; echo "1.85.1-stable"; return 0; }; export -f rustup; ./build_app.sh -a $(APP_NAME) -p macos -v $(VERSION) -b $(BUILD_NUM) -f'	
	@echo "4. Building secp256k1 (coinlib)..."
	$(FLUTTER) pub run coinlib:build_macos
	
	@echo "5. Compiling Flutter App..."
	env -u CXXFLAGS -u CFLAGS -u LDFLAGS -u CPATH -u LIBRARY_PATH $(FLUTTER) build macos --release


# --- IOS ---

build-ios: check-reqs check-macos-sdk init prebuild-unix ## Complete release build for iOS
	@echo "1. Generating pubspec.yaml and building native crypto plugins..."
	cd scripts && ./build_app.sh -a $(APP_NAME) -p ios -v $(VERSION) -b $(BUILD_NUM) -f
	@echo "2. Fetching Dart dependencies..."
	$(FLUTTER) pub get
	@echo "3. Compiling Flutter App..."
	$(FLUTTER) build ios --release --no-codesign

# --- ANDROID ---

build-android: check-reqs init prebuild-unix ## Complete release build for Android (APK)
	@echo "1. Generating pubspec.yaml and building native crypto plugins..."
	cd scripts && ./build_app.sh -a $(APP_NAME) -p android -v $(VERSION) -b $(BUILD_NUM) -f
	@echo "2. Fetching Dart dependencies..."
	$(FLUTTER) pub get
	@echo "3. Compiling Flutter App..."
	$(FLUTTER) build apk --release

# --- WINDOWS ---

build-windows: check-reqs check-reqs-windows init prebuild-windows ## Complete release build for Windows
	@echo "1. Generating pubspec.yaml and building native plugins in WSL..."
	wsl bash -c "cd scripts && ./build_app.sh -a $(APP_NAME) -p windows -v $(VERSION) -b $(BUILD_NUM) -f"
	@echo "2. Fetching Dart dependencies natively..."
	$(FLUTTER) pub get
	@echo "3. Building secp256k1 natively..."
	$(DART) run coinlib:build_windows
	@echo "4. Building frostdart natively..."
	cd crypto_plugins/frostdart && build_all.bat
	@echo "5. Compiling Flutter App..."
	$(FLUTTER) build windows --release
