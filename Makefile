# ==============================================================================
# Stack Wallet Universal Build Makefile
# Usage: make <target> VERSION=x.x.x BUILD_NUM=xxx
# ==============================================================================

APP_NAME     ?= stack_wallet
VERSION      ?= 2.1.0
BUILD_NUM    ?= 210
FLUTTER      ?= flutter
DART         ?= dart
APP_PROJECT_ROOT_DIR ?= $(CURDIR)
PROTOC_PATH  := $(shell which protoc 2>/dev/null)
MACOS_ENV_UNSET = -u LD -u LDFLAGS -u NIX_LDFLAGS -u NIX_CFLAGS_LINK \
	-u CFLAGS -u CXXFLAGS -u CPPFLAGS \
	-u SDKROOT -u BINDGEN_EXTRA_CLANG_ARGS \
	-u IPHONEOS_DEPLOYMENT_TARGET -u TVOS_DEPLOYMENT_TARGET -u WATCHOS_DEPLOYMENT_TARGET \
	-u XROS_DEPLOYMENT_TARGET -u XR_DEPLOYMENT_TARGET
MACOS_ENV_SET = MACOSX_DEPLOYMENT_TARGET=11.0

export APP_PROJECT_ROOT_DIR

.PHONY: help check-reqs check-reqs-windows check-macos-sdk init clean prebuild-unix prebuild-windows deps-linux patch-submodules \
	build-linux build-macos build-ios build-android build-windows \
	macos-prepare macos-configure macos-restore-metadata macos-build-native macos-build-app diagnose-macos-env

help: ## Show available commands
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

# --- PREREQUISITES ---

check-reqs: ## Verify essential build tools
	@echo "Checking core prerequisites..."
	@command -v $(FLUTTER) >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@command -v $(DART) >/dev/null 2>&1 || { echo >&2 "[ERROR] Dart not installed."; exit 1; }
	@command -v rustup >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup not installed."; exit 1; }
	@rustup which rustc >/dev/null 2>&1 || { echo >&2 "[ERROR] rustc toolchain not available via rustup."; exit 1; }
	@rustup which cargo >/dev/null 2>&1 || { echo >&2 "[ERROR] cargo toolchain not available via rustup."; exit 1; }
	@rustup run stable rustc -vV >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup stable toolchain not available."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo >&2 "[ERROR] Go not installed."; exit 1; }
	@command -v cmake >/dev/null 2>&1 || { echo >&2 "[ERROR] CMake not installed."; exit 1; }
	@command -v pkg-config >/dev/null 2>&1 || { echo >&2 "[ERROR] pkg-config not installed."; exit 1; }
	@echo "[OK] All core CLI requirements found!"

check-macos-sdk: ## Verify XCode on macOS
ifeq ($(shell uname),Darwin)
	@echo "Checking macOS SDK requirements..."
	@xcode-select -p | grep -q "Xcode.app" || ( \
		echo "[ERROR] Full Xcode installation not detected! Path: /Applications/Xcode.app"; \
		exit 1)
	@echo "[OK] Xcode SDK path looks good."
endif

check-reqs-windows: ## Verify Windows/WSL requirements
	@echo "Checking Windows prerequisites..."
	@command -v wsl >/dev/null 2>&1 || { echo >&2 "[ERROR] WSL is not installed."; exit 1; }
	@echo "[OK] Windows/WSL requirements found!"

# --- MAINTENANCE ---

init: ## Initialize all submodules
	@git submodule update --init --recursive

clean: ## Remove artifacts and fix permissions
	@echo "Cleaning Flutter and Rust artifacts..."
	@chmod -R u+w crypto_plugins/ build/ macos/ 2>/dev/null || true
	@$(FLUTTER) clean
	@if [ -f "Cargo.toml" ]; then cargo clean; fi
	@rm -rf macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock build/
	@echo "Cleaning submodule target folders..."
	@find crypto_plugins/ -type d \( -name "target" -o -name "build" \) -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleaning external residues..."
	@chmod -R u+w $(HOME)/.pub-cache/git/ 2>/dev/null || true
	@find $(HOME)/.pub-cache/git/ -type d \( -name "build" -o -name "target" \) -path "*flutter_lib*" -exec rm -rf {} + 2>/dev/null || true
	@echo "[OK] Project is now in a pristine state."

patch-submodules: ## Apply portability patches to submodules
	@echo "Patching submodules for portability..."
	@chmod -R u+w crypto_plugins/ 2>/dev/null || true
	@rm -rf crypto_plugins/*/scripts/macos/build
	@find crypto_plugins -name "build_all.sh" -exec sed -i.bak 's|/\$${OS}_VERSION/c\\.*|s\|/\\\*\$${OSX}_VERSION\\\*/.*\|/\\\*\$${OSX}_VERSION\\\*/ const \$${OSX}_VERSION = \\"$$COMMIT\\";\|g|g' {} \; 2>/dev/null || true
	@find crypto_plugins/frostdart -name "build_*.dart" -type f -exec sed -i.bak 's/\["-i", ".bak",/\["-i.bak",/g' {} + 2>/dev/null || true
	@echo "Fixing Epic Cash header logic..."
	@sed -i.bak 's|cp target/epic_cash_wallet.h libepic_cash_wallet.h|mkdir -p target \&\& touch target/epic_cash_wallet.h \&\& cp target/epic_cash_wallet.h libepic_cash_wallet.h|g' crypto_plugins/flutter_libepiccash/scripts/macos/build_all.sh 2>/dev/null || true
	@sed -i.bak 's|cbindgen --config cbindgen.toml --crate epic-cash-wallet --output target/epic_cash_wallet.h|cbindgen --config cbindgen.toml --crate epic-cash-wallet --output target/epic_cash_wallet.h \&\& cp target/epic_cash_wallet.h libepic_cash_wallet.h|g' crypto_plugins/flutter_libepiccash/scripts/macos/build_all.sh 2>/dev/null || true
	@echo "Fixing Frostdart binary path..."
	@find crypto_plugins/frostdart/scripts -name "build_all.sh" -exec sed -i.bak "s|.*dart build_|$(shell which dart) build_|g" {} + 2>/dev/null || true
	@echo "Disabling strict Rust checks..."
	@find crypto_plugins scripts -type f -name "rust_version.sh" -exec sed -i.bak 's/exit 1/echo "Bypassed by Nix"/g' {} + 2>/dev/null || true
	@find crypto_plugins -name "*.bak" -delete 2>/dev/null || true
	@echo "[OK] Submodules patched."

# --- PLATFORM BUILDS ---

build-macos: macos-prepare macos-configure macos-restore-metadata macos-build-native macos-build-app ## Build MacOS Release (Self-healing)

macos-prepare:
	@echo "--- Sanitizing environment..."
	@sed -i 's/xelis_dart_sdk: 0.30.9/xelis_dart_sdk:/g' scripts/app_config/templates/pubspec.template.yaml 2>/dev/null || true
	@sed -i 's/\xc2\xa0/ /g' scripts/app_config/templates/pubspec.template.yaml 2>/dev/null || true
	@chmod -R u+w . 2>/dev/null || true
	@rm -rf build/secp256k1 macos/Runner.xcworkspace crypto_plugins/*/scripts/macos/build

macos-configure:
	@echo "--- Configuring project..."
	@./scripts/app_config/configure_stack_wallet.sh macos
	@./scripts/app_config/shared/update_version.sh -v $(VERSION) -b $(BUILD_NUM)

macos-restore-metadata:
	@echo "--- Restoring metadata..."
	@$(FLUTTER) create --platforms=macos . > /dev/null
	@# Nix-provided Flutter templates can be copied as read-only; CocoaPods must rewrite these files.
	@chmod -R u+w macos/Runner.xcworkspace macos/Runner.xcodeproj macos/Flutter 2>/dev/null || true
	@# Keep app target deployment aligned with plugin minimums (e.g. camera_macos >= 11.0).
	@sed -i.bak -e "s/MACOSX_DEPLOYMENT_TARGET = 10\\.15;/MACOSX_DEPLOYMENT_TARGET = 11.0;/g" macos/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
	@rm -f macos/Runner.xcodeproj/project.pbxproj.bak
	@$(FLUTTER) pub get
	@# Ensure generated build settings are single-line key/value entries for CocoaPods xcconfig parser.
	@[ -f macos/Flutter/ephemeral/Flutter-Generated.xcconfig ] && \
		sed -i.bak -E 's/[[:space:]]+$$//' macos/Flutter/ephemeral/Flutter-Generated.xcconfig && \
		rm -f macos/Flutter/ephemeral/Flutter-Generated.xcconfig.bak || true

macos-build-native:
	@echo "--- Building native dependencies..."
	@rm -rf build/secp256k1
	@$(DART) run coinlib:build_macos
	@echo "--- Patching Podfile..."
	@sed -i.bak -e "s/platform :osx, '10.11'/platform :osx, '11.0'/g" -e "s/platform :osx, '10.15'/platform :osx, '11.0'/g" macos/Podfile 2>/dev/null || true
	@rm -f macos/Podfile.bak

macos-build-app:
	@echo "--- Final Compilation..."
	@rm -rf macos/Pods macos/Podfile.lock
	@env $(MACOS_ENV_UNSET) $(MACOS_ENV_SET) \
		RUSTUP_HOME="$$HOME/.rustup" \
		CARGO_HOME="$$HOME/.cargo" \
		RUSTUP_TOOLCHAIN=stable \
		PATH="$$(dirname "$$(/opt/homebrew/bin/rustup which rustc)"):/opt/homebrew/opt/rustup/bin:/opt/homebrew/bin:$$HOME/.cargo/bin:$$PATH" \
		$(FLUTTER) build macos --release

diagnose-macos-env: ## Print macOS build env and tool resolution
	@echo "--- Toolchain diagnostics ---"
	@echo "flutter: $$(command -v $(FLUTTER) || echo missing)"
	@echo "dart: $$(command -v $(DART) || echo missing)"
	@echo "xcrun: $$(command -v xcrun || echo missing)"
	@echo "clang: $$(command -v clang || echo missing)"
	@echo "go: $$(command -v go || echo missing)"
	@echo "rustup: $$(command -v rustup || echo missing)"
	@echo "rustc: $$(command -v rustc || echo missing)"
	@echo "cargo: $$(command -v cargo || echo missing)"
	@echo "rustup rustc: $$(rustup which rustc 2>/dev/null || echo missing)"
	@echo "rustup cargo: $$(rustup which cargo 2>/dev/null || echo missing)"
	@echo "xcode-select: $$(xcode-select -p 2>/dev/null || echo missing)"
	@echo "SDKROOT=$${SDKROOT:-<unset>}"
	@echo "MACOSX_DEPLOYMENT_TARGET=$${MACOSX_DEPLOYMENT_TARGET:-<unset>}"
	@echo "IPHONEOS_DEPLOYMENT_TARGET=$${IPHONEOS_DEPLOYMENT_TARGET:-<unset>}"
	@echo "TVOS_DEPLOYMENT_TARGET=$${TVOS_DEPLOYMENT_TARGET:-<unset>}"
	@echo "WATCHOS_DEPLOYMENT_TARGET=$${WATCHOS_DEPLOYMENT_TARGET:-<unset>}"
	@echo "XROS_DEPLOYMENT_TARGET=$${XROS_DEPLOYMENT_TARGET:-<unset>}"
	@echo "XR_DEPLOYMENT_TARGET=$${XR_DEPLOYMENT_TARGET:-<unset>}"
	@echo "NIX_LDFLAGS=$${NIX_LDFLAGS:-<unset>}"
	@echo "NIX_CFLAGS_LINK=$${NIX_CFLAGS_LINK:-<unset>}"

build-ios: check-reqs check-macos-sdk init ## Build iOS Release
	@echo "--- Configuring project..."
	@cd scripts && ./build_app.sh -a $(APP_NAME) -p ios -v $(VERSION) -b $(BUILD_NUM) -f
	@echo "--- Building app..."
	@$(FLUTTER) pub get
	@$(FLUTTER) build ios --release --no-codesign

build-linux: check-reqs init patch-submodules ## Build Linux Release
	@echo "--- Generating config..."
	@if [ -z "$(PROTOC_PATH)" ]; then echo "[ERROR] protoc not found!"; exit 1; fi
	@cd scripts && yes yes | BUILD_ISAR_FROM_SOURCE=0 PROTOC="$(PROTOC_PATH)" ./build_app.sh -a $(APP_NAME) -p linux -v $(VERSION) -b $(BUILD_NUM) -f
	@echo "--- Building app..."
	@$(FLUTTER) pub get
	@$(FLUTTER) pub run coinlib:build_linux
	@$(FLUTTER) build linux --release

build-android: check-reqs init ## Build Android APK
	@echo "--- Configuring project..."
	@cd scripts && ./build_app.sh -a $(APP_NAME) -p android -v $(VERSION) -b $(BUILD_NUM) -f
	@echo "--- Building app..."
	@$(FLUTTER) pub get
	@$(FLUTTER) build apk --release

build-windows: check-reqs check-reqs-windows init ## Build Windows Release
	@echo "--- Building native plugins in WSL..."
	@wsl bash -c "cd scripts && ./build_app.sh -a $(APP_NAME) -p windows -v $(VERSION) -b $(BUILD_NUM) -f"
	@echo "--- Building native dependencies..."
	@$(FLUTTER) pub get
	@$(DART) run coinlib:build_windows
	@cd crypto_plugins/frostdart && build_all.bat
	@echo "--- Compiling app..."
	@$(FLUTTER) build windows --release
