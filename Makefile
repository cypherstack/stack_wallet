# ==============================================================================
# Stack Wallet build helper (macOS). Wraps scripts/build_app.sh; see docs/building.md
# Usage: make <target> VERSION=x.x.x BUILD_NUM=xxx
# ==============================================================================

APP_NAME     ?= stack_wallet
VERSION      ?= 2.1.0
BUILD_NUM    ?= 210
FLUTTER      ?=
DART         ?=
FLUTTER_BIN  := $(if $(and $(FLUTTER),$(wildcard $(FLUTTER))),$(FLUTTER),$(shell command -v flutter 2>/dev/null))
DART_BIN     := $(if $(and $(DART),$(wildcard $(DART))),$(DART),$(shell command -v dart 2>/dev/null))
FLUTTER      := $(FLUTTER_BIN)
DART         := $(DART_BIN)
APP_PROJECT_ROOT_DIR := $(CURDIR)
# Platform detection from uname.
PLATFORM       ?= $(shell uname -s 2>/dev/null)
PUB_CACHE    ?= $(APP_PROJECT_ROOT_DIR)/.pub-cache
PROTOC_PATH  := $(shell which protoc 2>/dev/null)
# Toolchain installed for host-side checks/targets. Native-assets crates pick their own
# pinned toolchain via rust-toolchain.toml; do not export RUSTUP_TOOLCHAIN globally.
RUST_VERSION ?= 1.99.1
SKIP_NATIVE                  ?= 0
MACOS_ENV_UNSET = -u LD -u LDFLAGS -u NIX_LDFLAGS -u NIX_CFLAGS_LINK \
	-u CFLAGS -u CXXFLAGS -u CPPFLAGS \
	-u SDKROOT -u BINDGEN_EXTRA_CLANG_ARGS \
	-u IPHONEOS_DEPLOYMENT_TARGET -u TVOS_DEPLOYMENT_TARGET -u WATCHOS_DEPLOYMENT_TARGET \
	-u XROS_DEPLOYMENT_TARGET -u XR_DEPLOYMENT_TARGET
MACOS_ENV_SET = MACOSX_DEPLOYMENT_TARGET=12.0

export APP_PROJECT_ROOT_DIR
export PUB_CACHE

.PHONY: help check-reqs check-reqs-macos check-sdk-macos bootstrap-macos bootstrap-xcode bootstrap-xcode-download sccache-setup cache-stats verify-bom clean clean-app clean-native build-macos build-linux build-windows diagnose-env-macos test-mwc build-android android-dev-key build-ios

help: ## Show available commands
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

# --- PREREQUISITES ---

check-reqs: ## Verify essential build tools
	@echo "Checking core prerequisites..."
	@[ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@[ -n "$(DART)" ] && command -v "$(DART)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Dart not installed."; exit 1; }
	@command -v rustup >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup not installed."; exit 1; }
	@rustup which rustc >/dev/null 2>&1 || { echo >&2 "[ERROR] rustc toolchain not available via rustup."; exit 1; }
	@rustup which cargo >/dev/null 2>&1 || { echo >&2 "[ERROR] cargo toolchain not available via rustup."; exit 1; }
	@# `rustup which cargo` resolves a toolchain path even when no shim is on PATH,
	@# but the plugin build scripts invoke bare `cargo` — verify that separately.
	@command -v cargo >/dev/null 2>&1 || [ -x "$$HOME/.cargo/bin/cargo" ] || { echo >&2 "[ERROR] 'cargo' is not on PATH (rustup shims missing from ~/.cargo/bin). Run 'rustup-init -y', then open a new terminal."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo >&2 "[ERROR] Go not installed."; exit 1; }
	@command -v cmake >/dev/null 2>&1 || { echo >&2 "[ERROR] CMake not installed."; exit 1; }
	@command -v meson >/dev/null 2>&1 || { \
		if [ "$(PLATFORM)" = "Darwin" ]; then \
			echo >&2 "[ERROR] Meson not installed. On macOS, run 'make bootstrap-macos' or 'brew install meson'."; \
		elif [ "$(PLATFORM)" = "Linux" ]; then \
			echo >&2 "[ERROR] Meson not installed. On Linux/NixOS, run in 'nix develop' or install meson via your package manager."; \
		else \
			echo >&2 "[ERROR] Meson not installed. Install via your package manager."; \
		fi; \
		exit 1; \
	}
	@command -v ninja >/dev/null 2>&1 || { \
		if [ "$(PLATFORM)" = "Darwin" ]; then \
			echo >&2 "[ERROR] Ninja not installed. On macOS, run 'make bootstrap-macos' or 'brew install ninja'."; \
		elif [ "$(PLATFORM)" = "Linux" ]; then \
			echo >&2 "[ERROR] Ninja not installed. On Linux/NixOS, run in 'nix develop' or install ninja via your package manager."; \
		else \
			echo >&2 "[ERROR] Ninja not installed. Install via your package manager."; \
		fi; \
		exit 1; \
	}
ifneq ($(OS),Windows_NT)
	@command -v pkg-config >/dev/null 2>&1 || { echo >&2 "[ERROR] pkg-config not installed."; exit 1; }
endif
ifeq ($(PLATFORM),Darwin)
	@command -v autoreconf >/dev/null 2>&1 || { echo >&2 "[ERROR] autoconf/autoreconf not installed."; exit 1; }
	@command -v aclocal >/dev/null 2>&1 || { echo >&2 "[ERROR] automake/aclocal not installed."; exit 1; }
endif
	@echo "[OK] All core CLI requirements found!"

check-sdk-macos: ## Verify XCode on macOS
ifeq ($(PLATFORM),Darwin)
	@echo "Checking macOS SDK requirements..."
	@xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1 || ( \
		echo "[ERROR] macOS SDK not available. Install Xcode or run: sudo xcode-select --switch /Applications/Xcode.app"; \
		exit 1)
	@echo "[OK] macOS SDK available at: $$(xcrun --sdk macosx --show-sdk-path)"
endif

check-reqs-macos: check-reqs ## Verify macOS-specific tools are available in PATH
ifeq ($(PLATFORM),Darwin)
	@echo "Checking macOS-specific tools in PATH..."
	@rustup run $(RUST_VERSION) rustc -vV >/dev/null 2>&1 || { echo >&2 "[ERROR] Rust $(RUST_VERSION) toolchain not available. Run 'make bootstrap-macos'."; exit 1; }
	@command -v pod >/dev/null 2>&1 || { echo >&2 "[ERROR] CocoaPods (pod) not installed."; exit 1; }
	@command -v xcodebuild >/dev/null 2>&1 || { echo >&2 "[ERROR] xcodebuild not available."; exit 1; }
	@echo "[OK] macOS-specific toolchain is available."
else
	@echo "[ERROR] check-reqs-macos is macOS-only."
	@exit 1
endif

bootstrap-macos: ## Install required macOS build tools via Homebrew helper script
ifeq ($(PLATFORM),Darwin)
	@if [ -n "$$IN_NIX_SHELL" ] || [ -n "$$NIX_BUILD_TOP" ]; then \
		echo "[WARN] Nix environment detected; skipping the Homebrew package install (use nix/flake-provided toolchain instead)."; \
		echo "[WARN] Xcode itself is never provided by Nix (Apple's license forbids redistributing it), so that part still runs:"; \
		$(MAKE) bootstrap-xcode || exit 1; \
	else \
		bash scripts/install_macos_build_tools.sh || exit 1; \
		rustup target add aarch64-apple-darwin x86_64-apple-darwin aarch64-apple-ios --toolchain $(RUST_VERSION) >/dev/null 2>&1 || true; \
	fi
else
	@echo "[ERROR] bootstrap-macos is macOS-only."
	@exit 1
endif

bootstrap-xcode: ## Install/select full Xcode.app (needed regardless of Homebrew vs Nix for the rest of the toolchain)
ifeq ($(PLATFORM),Darwin)
	@bash scripts/install_xcode.sh
else
	@echo "[ERROR] bootstrap-xcode is macOS-only."
	@exit 1
endif

bootstrap-xcode-download: ## Opt-in: download Xcode from archive.org (SHA-1 + Apple signature checked); XCODE_VERSION=27.1, ARGS=-y for non-interactive
ifeq ($(PLATFORM),Darwin)
	@bash scripts/download_xcode.sh $(if $(XCODE_VERSION),-v $(XCODE_VERSION)) $(ARGS)
else
	@echo "[ERROR] bootstrap-xcode-download is macOS-only."
	@exit 1
endif

SCCACHE_CARGO_CONFIG ?= $(HOME)/.cargo/config.toml

sccache-setup: ## Opt-in: use sccache for the Rust/C builds run by native-asset hooks (writes ~/.cargo/config.toml if absent)
	@command -v sccache >/dev/null 2>&1 || { echo >&2 "[ERROR] sccache not installed (brew install sccache)."; exit 1; }
	@if [ -e "$(SCCACHE_CARGO_CONFIG)" ]; then \
		echo "[INFO] $(SCCACHE_CARGO_CONFIG) already exists, not touching it. Make sure it contains:"; \
		printf '  [build]\n  rustc-wrapper = "sccache"\n'; \
	else \
		mkdir -p "$$(dirname "$(SCCACHE_CARGO_CONFIG)")"; \
		printf '[build]\nrustc-wrapper = "sccache"\n' > "$(SCCACHE_CARGO_CONFIG)"; \
		echo "[OK] Wrote $(SCCACHE_CARGO_CONFIG). Remove the file to turn sccache off."; \
	fi
	@echo "Why a config file: with Flutter 3.47.x (hooks_runner 1.5.0) exported variables such as RUSTC_WRAPPER"
	@echo "never reach the hooks; cargo reads this file via HOME. Flutter versions with hooks_runner >= 1.6.2"
	@echo "also pass CARGO_BUILD_RUSTC_WRAPPER=sccache from the environment. See sccache --show-stats."

verify-bom: ## Check the local toolchain and the pinned plugins against stack-bom.toml
	@dart tool/verify_bom.dart

cache-stats: ## Show sccache statistics (hit rate) after a build
	@command -v sccache >/dev/null 2>&1 || { echo >&2 "[ERROR] sccache not installed."; exit 1; }
	@sccache --show-stats

clean: ## Remove artifacts and fix permissions
	@echo "Cleaning Flutter and Rust artifacts..."
	@chflags -R nouchg build/ macos/ 2>/dev/null || true
	@chmod -R u+w build/ macos/ 2>/dev/null || true
	@if [ -f pubspec.yaml ]; then $(FLUTTER) clean; fi
	@if [ -f "Cargo.toml" ]; then cargo clean; fi
	@rm -rf macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock build/
	@echo "Cleaning local pub cache residues..."
	@chmod -R u+w $(PUB_CACHE)/git/ 2>/dev/null || true
	@find $(PUB_CACHE)/git/ -type d \( -name "build" -o -name "target" \) -path "*flutter_lib*" -exec rm -rf {} + 2>/dev/null || true
	@echo "[OK] Project is now in a pristine state."

# --- PLATFORM BUILDS ---

PREBUILTS ?= 1
# Linux only: SYSTEM_DEPS=1 uses the system libsecret/jsoncpp packages instead of building them (like the CI image).
SYSTEM_DEPS ?= 0

clean-app: ## Remove app build output (build/, Pods) but keep the native-asset build outputs, so the next build is fast
	@chflags -R nouchg build/ macos/ 2>/dev/null || true
	@chmod -R u+w build/ macos/ 2>/dev/null || true
	@rm -rf build/ macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock
	@echo "[OK] Removed build/ and Pods; .dart_tool/hooks_runner is kept."

clean-native: ## Remove only the native-asset build outputs (forces the Rust/Go/C libraries to be rebuilt)
	@chmod -R u+w .dart_tool/hooks_runner build/native_assets 2>/dev/null || true
	@rm -rf .dart_tool/hooks_runner build/native_assets
	@echo "[OK] Removed .dart_tool/hooks_runner and build/native_assets."

build-macos: check-reqs-macos check-sdk-macos ## Build macOS release (same steps as upstream CI; PREBUILTS=0 compiles native assets from source)
	@# pubspec.yaml is generated; build_app.sh only regenerates it from the template when unchanged,
	@# so a previous PREBUILTS setting would otherwise stick.
	@rm -f pubspec.yaml
	@echo "--- Configuring project (scripts/build_app.sh)..."
	@cd scripts && echo yes | env $(MACOS_ENV_UNSET) ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p macos -a stack_wallet -s $(if $(filter 1,$(PREBUILTS)),-d)
	@echo "--- Resolving dependencies..."
	@env $(MACOS_ENV_UNSET) $(FLUTTER) pub get
	@cd scripts && env $(MACOS_ENV_UNSET) bash prebuild.sh
	@echo "--- Final Compilation..."
	@env $(MACOS_ENV_UNSET) $(FLUTTER) build macos --release


test-mwc: ## Run MWC FFI integration test on macOS (assumes prior `make build-macos`)
	@# Flutter's first-launch helper rewrites MACOSX_DEPLOYMENT_TARGET=10.15; reassert 12.0.
	@sed -i.bak -e "s/MACOSX_DEPLOYMENT_TARGET = 10\\.15;/MACOSX_DEPLOYMENT_TARGET = 12.0;/g" -e "s/MACOSX_DEPLOYMENT_TARGET = 11\\.0;/MACOSX_DEPLOYMENT_TARGET = 12.0;/g" macos/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
	@rm -f macos/Runner.xcodeproj/project.pbxproj.bak
	@chmod -R u+w macos/Runner.xcodeproj macos 2>/dev/null || true
	@env $(MACOS_ENV_UNSET) $(MACOS_ENV_SET) \
		$(FLUTTER) test integration_test/mwc_ffi_test.dart -d macos

diagnose-env-macos: ## Print macOS build env and tool resolution
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

build-linux: check-reqs ## Build Linux Release through Flutter native-assets hooks
	@echo "--- Running prebuild bootstrap..."
	@cd scripts && bash prebuild.sh
	@echo "--- Generating config..."
	@if [ -z "$(PROTOC_PATH)" ]; then echo "[ERROR] protoc not found!"; exit 1; fi
	@cd scripts && yes yes | BUILD_ISAR_FROM_SOURCE=0 PROTOC="$(PROTOC_PATH)" ./build_app.sh -a $(APP_NAME) -p linux -v $(VERSION) -b $(BUILD_NUM) $(if $(filter 1,$(PREBUILTS)),-d) $(if $(filter 1,$(SYSTEM_DEPS)),-s)
	@# Flutter 3.47.x hooks only see a filtered environment, so PROTOC (exported by the flake) never
	@# reaches cargo build scripts. Some crates (prost-build 0.7) ship a generic-Linux protoc that cannot
	@# run on NixOS. cargo reads [env] from .cargo/config.toml found from the package dir upwards, which
	@# works because PUB_CACHE is project-local. Existing files are not touched.
	@if [ ! -e .cargo/config.toml ]; then \
		mkdir -p .cargo; \
		printf '[env]\nPROTOC = "%s"\n' "$(PROTOC_PATH)" > .cargo/config.toml; \
		echo "[OK] Wrote .cargo/config.toml (PROTOC=$(PROTOC_PATH))"; \
	else \
		echo "[INFO] .cargo/config.toml exists; make sure it sets [env] PROTOC if protoc fails to run (NixOS)."; \
	fi
	@echo "--- Building app..."
	@$(FLUTTER) pub get
	@mkdir -p scripts/linux/pc
	@printf '%s\n' \
		'prefix=$(CURDIR)/scripts/linux/build/libsecret' \
		'exec_prefix=$${prefix}' \
		'libdir=$${prefix}/_build/libsecret' \
		'includedir=$${prefix}' \
		'' \
		'Name: libsecret-1' \
		'Description: GObject bindings for Secret Service API' \
		'Version: 0.21.4' \
		'Libs: -L$${libdir} -lsecret-1' \
		'Cflags: -I$${includedir} -I$${includedir}/_build' \
		> scripts/linux/pc/libsecret-1.pc
	@if command -v podman >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then \
		: 'coinlib BuildKit git fetch fails on NixOS; scope the legacy-builder workaround here'; \
		DOCKER_BUILDKIT=0 $(FLUTTER) pub run coinlib:build_linux; \
	else \
		echo "[WARN] podman/docker not found; skipping coinlib:build_linux"; \
	fi
	@if [ "$(SYSTEM_DEPS)" = "1" ]; then \
		USE_SYSTEM_SECURE_STORAGE_DEPS=1 PROTOC="$(PROTOC_PATH)" $(FLUTTER) build linux --release; \
	else \
		SYSPROF_PC_DIR=$$(dirname "$$(find /nix/store -path '*/lib/pkgconfig/sysprof-capture-4.pc' 2>/dev/null | head -n1)"); \
		PC_PATH=$$(pkg-config --variable=pc_path pkg-config 2>/dev/null || echo ""); \
		PKG_CONFIG_DISABLE_UNINSTALLED=1 PKG_CONFIG_PATH= \
		PKG_CONFIG_LIBDIR="$(CURDIR)/scripts/linux/pc:$$SYSPROF_PC_DIR:$$PC_PATH" \
		pkg-config --modversion libsecret-1 >/dev/null || \
		{ echo "[ERROR] libsecret-1 not resolvable via pkg-config"; exit 1; }; \
		PKG_CONFIG_DISABLE_UNINSTALLED=1 PKG_CONFIG_PATH= \
		PKG_CONFIG_LIBDIR="$(CURDIR)/scripts/linux/pc:$$SYSPROF_PC_DIR:$$PC_PATH" \
		PROTOC="$(PROTOC_PATH)" $(FLUTTER) build linux --release; \
	fi

# Windows: run from Git Bash. Same steps as the "build-windows" job in .github/workflows/build.yaml.
# WINDOWS_COPY_ASSETS=1 replaces the asset links with copies (needed on runners that cannot create symlinks).
WINDOWS_COPY_ASSETS ?= 0

build-windows: ## Build Windows release (Git Bash; same steps as CI)
	@command -v flutter >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo >&2 "[ERROR] Go not installed."; exit 1; }
	@cd scripts && bash prebuild.sh
	@# link_assets.sh (run by build_app.sh) cannot remove the real directories a previous copy run left behind.
	@if [ "$(WINDOWS_COPY_ASSETS)" = "1" ]; then bash scripts/windows/replace_asset_links.sh --clean; fi
	@cd scripts && echo yes | MWEBD_FETCH=1 ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p windows -a $(APP_NAME) -d -s
	@if [ "$(WINDOWS_COPY_ASSETS)" = "1" ]; then bash scripts/windows/replace_asset_links.sh; fi
	@$(FLUTTER) pub get
	@$(DART) run coinlib:build_windows
	@$(FLUTTER) build windows --release

# Android: same steps as the "build-android" CI job, without the signing secrets. Needs the Android SDK/NDK
# (ANDROID_SDK_ROOT) and Java; the CI image ghcr.io/<owner>/stackwallet-ci:android is built from the Dockerfile
# (docker build --target android). Without android/key.properties a throw-away debug key is created, so the APKs
# are not suitable for distribution.
android-dev-key: ## Create a throw-away debug signing key if android/key.properties is missing (never use for releases)
	@if [ ! -f android/key.properties ]; then \
		echo "[INFO] android/key.properties missing: creating a throw-away debug key (not for releases)"; \
		keytool -genkeypair -keystore android/dev-keystore.jks -storetype pkcs12 -storepass android -keypass android \
			-alias devkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Stack Wallet dev build" -noprompt && \
		printf 'storeFile=../dev-keystore.jks\nstorePassword=android\nkeyPassword=android\nkeyAlias=devkey\n' > android/key.properties; \
	fi

build-android: android-dev-key ## Build Android APKs (same steps as CI; signed with a throw-away key unless android/key.properties exists)
	@command -v flutter >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@[ -n "$$ANDROID_SDK_ROOT$$ANDROID_HOME" ] || { echo >&2 "[ERROR] ANDROID_SDK_ROOT is not set (Android SDK/NDK required)."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && echo yes | ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p android -a $(APP_NAME) -d -s
	@$(FLUTTER) pub get
	@$(FLUTTER) build apk --split-per-abi --release

# iOS: same steps as the "build-ios" CI job (device build, no code signing). Run on macOS with Xcode.
build-ios: check-sdk-macos ## Build iOS Runner.app without code signing (same steps as CI)
	@command -v flutter >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && echo yes | ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p ios -a $(APP_NAME) -d -s
	@$(FLUTTER) pub get
	@$(FLUTTER) build ios --release --no-codesign

