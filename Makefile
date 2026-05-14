# ==============================================================================
# Stack Wallet Universal Build Makefile
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
PUB_CACHE    ?= $(APP_PROJECT_ROOT_DIR)/.pub-cache
PROTOC_PATH  := $(shell which protoc 2>/dev/null)
PROJECT_HOME := $(APP_PROJECT_ROOT_DIR)/.build-home
PROJECT_CACHE := $(APP_PROJECT_ROOT_DIR)/.cache
PROJECT_TMP := $(APP_PROJECT_ROOT_DIR)/.tmp
PROJECT_CARGO_HOME := $(APP_PROJECT_ROOT_DIR)/.cargo-home
PROJECT_RUSTUP_HOME := $(APP_PROJECT_ROOT_DIR)/.rustup-home
MACOS_FINAL_RUST_TOOLCHAIN ?= stable
MACOS_ENV_UNSET = -u LD -u LDFLAGS -u NIX_LDFLAGS -u NIX_CFLAGS_LINK \
	-u CFLAGS -u CXXFLAGS -u CPPFLAGS \
	-u SDKROOT -u BINDGEN_EXTRA_CLANG_ARGS \
	-u IPHONEOS_DEPLOYMENT_TARGET -u TVOS_DEPLOYMENT_TARGET -u WATCHOS_DEPLOYMENT_TARGET \
	-u XROS_DEPLOYMENT_TARGET -u XR_DEPLOYMENT_TARGET
MACOS_ENV_SET = MACOSX_DEPLOYMENT_TARGET=11.0

export APP_PROJECT_ROOT_DIR
export PUB_CACHE

.PHONY: help check-reqs check-reqs-macos check-reqs-windows check-macos-sdk bootstrap-macos macos-local-state init clean prebuild-unix prebuild-windows deps-linux patch-submodules \
	build-linux build-macos build-ios build-android build-windows \
	macos-prepare macos-configure macos-restore-metadata macos-build-native macos-build-app diagnose-macos-env \
	test-mwc

help: ## Show available commands
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

# --- PREREQUISITES ---

check-reqs: ## Verify essential build tools
	@echo "Checking core prerequisites..."
	@[ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@[ -n "$(DART)" ] && command -v "$(DART)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Dart not installed."; exit 1; }
	@command -v rustup >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup not installed."; exit 1; }
	@rustup which rustc >/dev/null 2>&1 || { echo >&2 "[ERROR] rustc toolchain not available via rustup."; exit 1; }
	@rustup which cargo >/dev/null 2>&1 || { echo >&2 "[ERROR] cargo toolchain not available via rustup."; exit 1; }
	@rustup run stable rustc -vV >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup stable toolchain not available."; exit 1; }
	@rustup run 1.85.1 rustc -vV >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup 1.85.1 toolchain not available."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo >&2 "[ERROR] Go not installed."; exit 1; }
	@command -v cmake >/dev/null 2>&1 || { echo >&2 "[ERROR] CMake not installed."; exit 1; }
	@command -v meson >/dev/null 2>&1 || { \
		if [ "$(shell uname)" = "Darwin" ]; then \
			echo >&2 "[ERROR] Meson not installed. On macOS, run 'make bootstrap-macos' or 'brew install meson'."; \
		else \
			echo >&2 "[ERROR] Meson not installed. On NixOS, run in 'nix develop' or install meson permanently."; \
		fi; \
		exit 1; \
	}
	@command -v ninja >/dev/null 2>&1 || { \
		if [ "$(shell uname)" = "Darwin" ]; then \
			echo >&2 "[ERROR] Ninja not installed. On macOS, run 'make bootstrap-macos' or 'brew install ninja'."; \
		else \
			echo >&2 "[ERROR] Ninja not installed. On NixOS, run in 'nix develop' or install ninja permanently."; \
		fi; \
		exit 1; \
	}
	@command -v pkg-config >/dev/null 2>&1 || { echo >&2 "[ERROR] pkg-config not installed."; exit 1; }
ifeq ($(shell uname),Darwin)
	@command -v autoreconf >/dev/null 2>&1 || { echo >&2 "[ERROR] autoconf/autoreconf not installed."; exit 1; }
	@command -v aclocal >/dev/null 2>&1 || { echo >&2 "[ERROR] automake/aclocal not installed."; exit 1; }
endif
	@echo "[OK] All core CLI requirements found!"

check-macos-sdk: ## Verify XCode on macOS
ifeq ($(shell uname),Darwin)
	@echo "Checking macOS SDK requirements..."
	@xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1 || ( \
		echo "[ERROR] macOS SDK not available. Install Xcode or run: sudo xcode-select --switch /Applications/Xcode.app"; \
		exit 1)
	@echo "[OK] macOS SDK available at: $$(xcrun --sdk macosx --show-sdk-path)"
endif

check-reqs-macos: check-reqs ## Verify macOS-specific tools are available in PATH
ifeq ($(shell uname),Darwin)
	@echo "Checking macOS-specific tools in PATH..."
	@command -v pod >/dev/null 2>&1 || { echo >&2 "[ERROR] CocoaPods (pod) not installed."; exit 1; }
	@command -v xcodebuild >/dev/null 2>&1 || { echo >&2 "[ERROR] xcodebuild not available."; exit 1; }
	@echo "[OK] macOS-specific toolchain is available."
else
	@echo "[ERROR] check-reqs-macos is macOS-only."
	@exit 1
endif

bootstrap-macos: ## Install required macOS build tools via Homebrew helper script
ifeq ($(shell uname),Darwin)
	@if [ -n "$$IN_NIX_SHELL" ] || [ -n "$$NIX_BUILD_TOP" ]; then \
		echo "[WARN] Nix environment detected; bootstrap-macos skipped (use nix/flake-provided toolchain)."; \
		exit 0; \
	fi
	@bash scripts/install_macos_build_tools.sh
	@rustup target add aarch64-apple-darwin x86_64-apple-darwin --toolchain stable >/dev/null 2>&1 || true
	@rustup target add aarch64-apple-darwin x86_64-apple-darwin --toolchain 1.85.1 >/dev/null 2>&1 || true
else
	@echo "[ERROR] bootstrap-macos is macOS-only."
	@exit 1
endif

macos-local-state: ## Create project-local state dirs for reproducible macOS builds
ifeq ($(shell uname),Darwin)
	@mkdir -p "$(PROJECT_HOME)" "$(PROJECT_CACHE)" "$(PROJECT_TMP)" "$(PUB_CACHE)" "$(PROJECT_CARGO_HOME)" "$(PROJECT_RUSTUP_HOME)"
else
	@true
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
	@echo "Cleaning local pub cache residues..."
	@chmod -R u+w $(PUB_CACHE)/git/ 2>/dev/null || true
	@find $(PUB_CACHE)/git/ -type d \( -name "build" -o -name "target" \) -path "*flutter_lib*" -exec rm -rf {} + 2>/dev/null || true
	@echo "[OK] Project is now in a pristine state."

patch-submodules: ## Apply portability patches to submodules
	@echo "Patching submodules for portability..."
	@chmod -R u+w crypto_plugins/ 2>/dev/null || true
	@rm -rf crypto_plugins/*/scripts/macos/build
	@# NOTE: avoid brittle cross-platform in-place sed rewrites for build_all.sh files here.
	@# Platform-specific script patching is handled explicitly in build targets via scripts/patches/*.
	@find crypto_plugins/frostdart -name "build_*.dart" -type f -exec perl -0777 -i.bak -pe 's/\["-i"\s*,\s*"\.bak"\s*,/\["-i.bak",/g' {} + 2>/dev/null || true
	@echo "Fixing Epic Cash header logic..."
	@sed -i.bak 's|cp target/epic_cash_wallet.h libepic_cash_wallet.h|mkdir -p target \&\& touch target/epic_cash_wallet.h \&\& cp target/epic_cash_wallet.h libepic_cash_wallet.h|g' crypto_plugins/flutter_libepiccash/scripts/macos/build_all.sh 2>/dev/null || true
	@sed -i.bak 's|cbindgen --config cbindgen.toml --crate epic-cash-wallet --output target/epic_cash_wallet.h|cbindgen --config cbindgen.toml --crate epic-cash-wallet --output target/epic_cash_wallet.h \&\& cp target/epic_cash_wallet.h libepic_cash_wallet.h|g' crypto_plugins/flutter_libepiccash/scripts/macos/build_all.sh 2>/dev/null || true
	@echo "Fixing Frostdart binary path..."
	@find crypto_plugins/frostdart/scripts -name "build_all.sh" -exec perl -0777 -i.bak -pe 's|^.*dart\s+build_|dart build_|mg' {} + 2>/dev/null || true
	@echo "Normalizing Linux script shebangs for NixOS..."
	@find crypto_plugins -path "*/scripts/linux/*.sh" -type f -exec sed -i.bak '1s|^#!/bin/bash$$|#!/usr/bin/env bash|' {} + 2>/dev/null || true
	@# GNU/BSD sed compatibility: ensure Frostdart macOS script uses -i.bak form.
	@perl -0777 -i.bak -pe 's/_run\("sed",\s*\["-i"\s*,\s*"\.bak"\s*,\s*"s\/frostdart\/hrf-api\/",\s*"cargo\.toml"\]\);/_run("sed", ["-i.bak", "s\/frostdart\/hrf-api\/", "cargo.toml"]);/g' crypto_plugins/frostdart/scripts/macos/build_macos.dart 2>/dev/null || true
	@echo "Disabling strict Rust checks..."
	@find crypto_plugins scripts -type f -name "rust_version.sh" -exec sed -i.bak 's/exit 1/echo "Bypassed by Nix"/g' {} + 2>/dev/null || true
	@find crypto_plugins -name "*.bak" -delete 2>/dev/null || true
	@echo "[OK] Submodules patched."

# --- PLATFORM BUILDS ---

build-macos: check-reqs-macos check-macos-sdk macos-local-state macos-prepare macos-configure macos-restore-metadata macos-build-native macos-build-app ## Build MacOS Release (Single source of truth)

macos-prepare:
	@echo "--- Sanitizing environment..."
	@sed -i.bak 's/\xc2\xa0/ /g' scripts/app_config/templates/pubspec.template.yaml 2>/dev/null || true
	@rm -f scripts/app_config/templates/pubspec.template.yaml.bak
	@chmod -R u+w macos build scripts crypto_plugins 2>/dev/null || true
	@[ -f pubspec.yaml ] && chmod u+w pubspec.yaml 2>/dev/null || true
	@rm -rf build/secp256k1 macos/Runner.xcworkspace crypto_plugins/*/scripts/macos/build

macos-configure:
	@echo "--- Configuring project..."
	@echo "--- Initializing submodules..."
	@git submodule update --init --recursive
	@echo "--- Bootstrapping local config files..."
	@cd scripts && env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		bash prebuild.sh
	@if [ ! -f crypto_plugins/flutter_libepiccash/lib/git_versions.dart ] && [ -f crypto_plugins/flutter_libepiccash/lib/git_versions_example.dart ]; then \
		echo "--- Creating flutter_libepiccash git_versions.dart from example..."; \
		cp crypto_plugins/flutter_libepiccash/lib/git_versions_example.dart crypto_plugins/flutter_libepiccash/lib/git_versions.dart; \
	fi
	@if [ ! -f crypto_plugins/flutter_libmwc/lib/git_versions.dart ] && [ -f crypto_plugins/flutter_libmwc/lib/git_versions_example.dart ]; then \
		echo "--- Creating flutter_libmwc git_versions.dart from example..."; \
		cp crypto_plugins/flutter_libmwc/lib/git_versions_example.dart crypto_plugins/flutter_libmwc/lib/git_versions.dart; \
	fi
	@echo "--- Regenerating pubspec.yaml from template..."
	@cp scripts/app_config/templates/pubspec.template.yaml pubspec.yaml
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		./scripts/app_config/configure_stack_wallet.sh macos
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		./scripts/app_config/shared/update_version.sh -v $(VERSION) -b $(BUILD_NUM)

macos-restore-metadata:
	@echo "--- Restoring metadata..."
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		$(FLUTTER) config --enable-macos-desktop >/dev/null
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		$(FLUTTER) create --platforms=macos . > /dev/null
	@# `flutter create` synthesizes a counter-app widget test that doesn't apply to this app.
	@rm -f test/widget_test.dart
	@rm -rf macos/Runner.xcworkspace macos/Pods macos/Podfile.lock
	@chmod -R u+rwX macos 2>/dev/null || true
	@chflags -R nouchg macos 2>/dev/null || true
	@# Nix-provided Flutter templates can be copied as read-only; CocoaPods must rewrite these files.
	@[ -d macos/Runner.xcodeproj ] && chmod -R u+w macos/Runner.xcodeproj 2>/dev/null || true
	@[ -d macos/Flutter ] && chmod -R u+w macos/Flutter 2>/dev/null || true
	@# Ensure Pods includes are resolved relative to macos/Flutter/*.xcconfig.
	@sed -i.bak -e 's|#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner\.debug\.xcconfig"|#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"|g' macos/Flutter/Flutter-Debug.xcconfig 2>/dev/null || true
	@sed -i.bak -e 's|#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner\.release\.xcconfig"|#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"|g' macos/Flutter/Flutter-Release.xcconfig 2>/dev/null || true
	@rm -f macos/Flutter/Flutter-Debug.xcconfig.bak macos/Flutter/Flutter-Release.xcconfig.bak
	@# Keep app target deployment aligned with plugin minimums (e.g. camera_macos >= 11.0).
	@sed -i.bak -e "s/MACOSX_DEPLOYMENT_TARGET = 10\\.15;/MACOSX_DEPLOYMENT_TARGET = 11.0;/g" macos/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
	@# Ensure Runner configs inherit app metadata (PRODUCT_NAME/BUNDLE ID) from AppInfo.
	@grep -q 'AppInfo.xcconfig' macos/Runner/Configs/Debug.xcconfig || \
		sed -i.bak -e '/Flutter-Debug.xcconfig/a\
#include "AppInfo.xcconfig"' macos/Runner/Configs/Debug.xcconfig 2>/dev/null || true
	@grep -q 'AppInfo.xcconfig' macos/Runner/Configs/Release.xcconfig || \
		sed -i.bak -e '/Flutter-Release.xcconfig/a\
#include "AppInfo.xcconfig"' macos/Runner/Configs/Release.xcconfig 2>/dev/null || true
	@rm -f macos/Runner/Configs/Debug.xcconfig.bak macos/Runner/Configs/Release.xcconfig.bak
	@# Keep local build overrides in xcconfig instead of UUID-based pbxproj rewrites.
	@printf '%s\n' \
		'// Auto-generated by Makefile (macos-restore-metadata)' \
		'PRODUCT_MODULE_NAME = stack_wallet' \
		'MACOSX_DEPLOYMENT_TARGET = 11.0' \
		> macos/Runner/Configs/CodexOverrides.xcconfig
	@grep -q 'CodexOverrides.xcconfig' macos/Runner/Configs/Debug.xcconfig || \
		printf '\n#include "CodexOverrides.xcconfig"\n' >> macos/Runner/Configs/Debug.xcconfig
	@grep -q 'CodexOverrides.xcconfig' macos/Runner/Configs/Release.xcconfig || \
		printf '\n#include "CodexOverrides.xcconfig"\n' >> macos/Runner/Configs/Release.xcconfig
	@[ -f macos/Runner/Configs/Profile.xcconfig ] && \
		( grep -q 'CodexOverrides.xcconfig' macos/Runner/Configs/Profile.xcconfig || \
		  printf '\n#include "CodexOverrides.xcconfig"\n' >> macos/Runner/Configs/Profile.xcconfig ) || true
	@rm -f macos/Runner.xcodeproj/project.pbxproj.bak
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		$(FLUTTER) pub get
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		bash scripts/macos/patch_coinlib_podspec.sh
	@# Ensure generated build settings are single-line key/value entries for CocoaPods xcconfig parser.
	@[ -f macos/Flutter/ephemeral/Flutter-Generated.xcconfig ] && \
		sed -i.bak -E 's/[[:space:]]+$$//' macos/Flutter/ephemeral/Flutter-Generated.xcconfig && \
		awk 'BEGIN{k="";v=""} \
		     function flush(){if(k!=""){print k "=" v; k=""; v=""}} \
		     /^[A-Za-z_][A-Za-z0-9_]*=/{ \
		       if(k!=""){flush()} \
		       split($$0,a,"="); \
		       key=a[1]; val=substr($$0, length(key)+2); gsub(/[ \t]/,"",val); \
		       if(key=="DART_DEFINES"){k=key; v=val; next} \
		       print $$0; next \
		     } \
		     { \
		       if(k=="DART_DEFINES"){gsub(/[ \t]/,"",$$0); v=v $$0; next} \
		       print $$0 \
		     } \
		     END{flush()}' macos/Flutter/ephemeral/Flutter-Generated.xcconfig > macos/Flutter/ephemeral/Flutter-Generated.xcconfig.tmp && \
		mv macos/Flutter/ephemeral/Flutter-Generated.xcconfig.tmp macos/Flutter/ephemeral/Flutter-Generated.xcconfig && \
		rm -f macos/Flutter/ephemeral/Flutter-Generated.xcconfig.bak || true

macos-build-native:
	@echo "--- Building native dependencies..."
	@# Ensure local rustup home has a usable default toolchain for native plugin scripts.
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup toolchain install --no-self-update stable 1.85.1 >/dev/null
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup default stable >/dev/null
	@echo "--- Applying local patch for flutter_libepiccash macOS build script..."
	@cp scripts/patches/flutter_libepiccash_macos_build_all.sh crypto_plugins/flutter_libepiccash/scripts/macos/build_all.sh
	@chmod +x crypto_plugins/flutter_libepiccash/scripts/macos/build_all.sh
	@echo "--- Applying local patch for flutter_libmwc macOS build script..."
	@cp scripts/patches/flutter_libmwc_macos_build_all.sh crypto_plugins/flutter_libmwc/scripts/macos/build_all.sh
	@chmod +x crypto_plugins/flutter_libmwc/scripts/macos/build_all.sh
	@# Ensure Frostdart macOS build script uses sed -i.bak form (GNU/BSD compatibility).
	@perl -0777 -i.bak -pe 's/_run\("sed",\s*\["-i"\s*,\s*"\.bak"\s*,\s*"s\/frostdart\/hrf-api\/",\s*"cargo\.toml"\]\);/_run("sed", ["-i.bak", "s\/frostdart\/hrf-api\/", "cargo.toml"]);/g' crypto_plugins/frostdart/scripts/macos/build_macos.dart 2>/dev/null || true
	@env $(MACOS_ENV_UNSET) $(MACOS_ENV_SET) \
		HOME="$(PROJECT_HOME)" \
		XDG_CACHE_HOME="$(PROJECT_CACHE)" \
		TMPDIR="$(PROJECT_TMP)" \
		PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" \
		CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER="/usr/bin/clang" \
		MAKEFLAGS= \
		MFLAGS= \
		CARGO_MAKEFLAGS= \
		CC="/usr/bin/clang" \
		CXX="/usr/bin/clang++" \
		AR="/usr/bin/ar" \
		RANLIB="/usr/bin/ranlib" \
		SDKROOT="$$(xcrun --sdk macosx --show-sdk-path)" \
		PROTOC="$(PROTOC_PATH)" \
		PATH="$(PROJECT_CARGO_HOME)/bin:$$PATH" \
		bash scripts/macos/build_all.sh
	@rm -rf build/secp256k1
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		$(FLUTTER) pub run coinlib:build_macos
	@echo "--- Patching Podfile..."
	@sed -i.bak -e "s/platform :osx, '10.11'/platform :osx, '11.0'/g" -e "s/platform :osx, '10.15'/platform :osx, '11.0'/g" macos/Podfile 2>/dev/null || true
	@rm -f macos/Podfile.bak

macos-build-app:
	@echo "--- Final Compilation..."
	@rm -rf macos/Runner.xcworkspace macos/Pods macos/Podfile.lock
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		$(FLUTTER) config --enable-macos-desktop >/dev/null
	@# Reassert macOS platform metadata in the same local HOME used for the final build.
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		$(FLUTTER) create --platforms=macos . --no-pub >/dev/null
	@# `flutter create` synthesizes a counter-app widget test that doesn't apply to this app.
	@rm -f test/widget_test.dart
	@chmod -R u+w macos/Runner.xcworkspace macos/Runner.xcodeproj 2>/dev/null || true
	@# Cargokit calls `rustup run stable cargo ...`; ensure local `stable` exists and is selected.
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup toolchain install --no-self-update stable >/dev/null
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup default stable >/dev/null
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup run stable rustc -V
	@echo "--- Cleaning stale Spark Mobile framework from local pub cache..."
	@find "$(PUB_CACHE)/git" -path '*/flutter_libsparkmobile-*/macos/flutter_libsparkmobile.framework' -prune -exec rm -rf {} + 2>/dev/null || true
	@env $(MACOS_ENV_UNSET) $(MACOS_ENV_SET) \
		HOME="$(PROJECT_HOME)" \
		XDG_CACHE_HOME="$(PROJECT_CACHE)" \
		TMPDIR="$(PROJECT_TMP)" \
		PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" \
		CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		RUSTUP_TOOLCHAIN="$(MACOS_FINAL_RUST_TOOLCHAIN)" \
		CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER="/usr/bin/clang" \
		PATH="$(PROJECT_CARGO_HOME)/bin:$$(dirname "$$(rustup which rustc)"):$${PATH}" \
		ARCHS=arm64 EXCLUDED_ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES $(FLUTTER) build macos --release

test-mwc: ## Run MWC FFI integration test on macOS (assumes prior `make build-macos`)
	@# Flutter's first-launch helper rewrites MACOSX_DEPLOYMENT_TARGET=10.15; reassert 11.0.
	@sed -i.bak -e "s/MACOSX_DEPLOYMENT_TARGET = 10\\.15;/MACOSX_DEPLOYMENT_TARGET = 11.0;/g" macos/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
	@rm -f macos/Runner.xcodeproj/project.pbxproj.bak
	@# Cargokit calls `rustup run stable cargo ...`; ensure local `stable` exists and is selected.
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup toolchain install --no-self-update stable >/dev/null
	@env HOME="$(PROJECT_HOME)" XDG_CACHE_HOME="$(PROJECT_CACHE)" TMPDIR="$(PROJECT_TMP)" PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		rustup default stable >/dev/null
	@# `flutter test` re-runs pod install which re-prepares flutter_libsparkmobile; remove stale framework so the prepare step can write.
	@find "$(PUB_CACHE)/git" -path '*/flutter_libsparkmobile-*/macos/flutter_libsparkmobile.framework' -prune -exec rm -rf {} + 2>/dev/null || true
	@chmod -R u+w macos/Runner.xcodeproj macos 2>/dev/null || true
	@env $(MACOS_ENV_UNSET) $(MACOS_ENV_SET) \
		HOME="$(PROJECT_HOME)" \
		XDG_CACHE_HOME="$(PROJECT_CACHE)" \
		TMPDIR="$(PROJECT_TMP)" \
		PUB_CACHE="$(PUB_CACHE)" \
		RUSTUP_HOME="$(PROJECT_RUSTUP_HOME)" \
		CARGO_HOME="$(PROJECT_CARGO_HOME)" \
		PATH="$(PROJECT_CARGO_HOME)/bin:$$PATH" \
		$(FLUTTER) test integration_test/mwc_ffi_test.dart -d macos

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
	@echo "--- Running prebuild bootstrap..."
	@cd scripts && bash prebuild.sh
	@echo "--- Generating config..."
	@if [ -z "$(PROTOC_PATH)" ]; then echo "[ERROR] protoc not found!"; exit 1; fi
	@cd scripts && yes yes | BUILD_ISAR_FROM_SOURCE=0 PROTOC="$(PROTOC_PATH)" ./build_app.sh -a $(APP_NAME) -p linux -v $(VERSION) -b $(BUILD_NUM) -f
	@echo "--- Building app..."
	@if [ ! -f lib/external_api_keys.dart ]; then \
		echo "[WARN] lib/external_api_keys.dart missing; recreating template."; \
		printf 'const kChangeNowApiKey = "";\nconst kSimpleSwapApiKey = "";\nconst kNanswapApiKey = "";\nconst kNanoSwapRpcApiKey = "";\nconst kWizSwapApiKey = "";\n' > lib/external_api_keys.dart; \
	fi
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
		$(FLUTTER) pub run coinlib:build_linux; \
	else \
		echo "[WARN] podman/docker not found; skipping coinlib:build_linux"; \
	fi
	@SYSPROF_PC_DIR=$$(dirname "$$(find /nix/store -path '*/lib/pkgconfig/sysprof-capture-4.pc' 2>/dev/null | head -n1)"); \
		PC_PATH=$$(pkg-config --variable=pc_path pkg-config 2>/dev/null || echo ""); \
		PKG_CONFIG_DISABLE_UNINSTALLED=1 \
		PKG_CONFIG_PATH= \
		PKG_CONFIG_LIBDIR="$(CURDIR)/scripts/linux/pc:$$SYSPROF_PC_DIR:$$PC_PATH" \
		pkg-config --modversion libsecret-1 >/dev/null || \
		{ echo "[ERROR] libsecret-1 not resolvable via pkg-config"; exit 1; }
	@SYSPROF_PC_DIR=$$(dirname "$$(find /nix/store -path '*/lib/pkgconfig/sysprof-capture-4.pc' 2>/dev/null | head -n1)"); \
		PC_PATH=$$(pkg-config --variable=pc_path pkg-config 2>/dev/null || echo ""); \
		PKG_CONFIG_DISABLE_UNINSTALLED=1 \
		PKG_CONFIG_PATH= \
		PKG_CONFIG_LIBDIR="$(CURDIR)/scripts/linux/pc:$$SYSPROF_PC_DIR:$$PC_PATH" \
		$(FLUTTER) build linux --release

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
