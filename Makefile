# ==============================================================================
# Stack Wallet build helper. Wraps scripts/build_app.sh; see docs/building.md
# Usage: make <target> VERSION=x.x.x BUILD_NUM=xxx
# ==============================================================================

APP_NAME     ?= stack_wallet
# Build targets require these explicitly: a stale default silently produces an
# app numbered below the current release line. See `require-version`.
VERSION      ?=
BUILD_NUM    ?=
FLUTTER      ?=
DART         ?=
FLUTTER_BIN  := $(if $(and $(FLUTTER),$(wildcard $(FLUTTER))),$(FLUTTER),$(shell command -v flutter 2>/dev/null))
DART_BIN     := $(if $(and $(DART),$(wildcard $(DART))),$(DART),$(shell command -v dart 2>/dev/null))
FLUTTER      := $(FLUTTER_BIN)
DART         := $(DART_BIN)
APP_PROJECT_ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# Platform detection from uname.
PLATFORM       ?= $(shell uname -s 2>/dev/null)
# Toolchain source. Nix (nix develop or direnv) is the primary path; Homebrew
# and manual installs use the host tools already on PATH. The build steps are
# identical in every mode: only the prerequisite check and the Nix environment
# sanitising differ. Override with TOOLCHAIN=nix|direnv|brew|manual|host.
TOOLCHAIN      ?= auto
DIRENV_ACTIVE  := $(if $(DIRENV_DIR),1,)
NIX_ACTIVE     := $(if $(or $(IN_NIX_SHELL),$(NIX_STORE)),1,)
ifneq ($(filter $(TOOLCHAIN),auto nix direnv brew manual host),$(TOOLCHAIN))
  $(error TOOLCHAIN must be auto, nix, direnv, brew, manual or host)
endif
ifeq ($(TOOLCHAIN),auto)
  ifeq ($(DIRENV_ACTIVE),1)
    ifeq ($(NIX_ACTIVE),1)
      TOOLCHAIN_EFFECTIVE := direnv
    else
      TOOLCHAIN_EFFECTIVE := host
    endif
  else
    ifeq ($(NIX_ACTIVE),1)
      TOOLCHAIN_EFFECTIVE := nix
    else
      TOOLCHAIN_EFFECTIVE := host
    endif
  endif
else
  TOOLCHAIN_EFFECTIVE := $(TOOLCHAIN)
endif
# Linux builds use a project-local pub cache so cargo finds the repo-local
# .cargo/config.toml that carries PROTOC through Flutter's filtered hook environment.
# Other targets leave PUB_CACHE unset, so Flutter uses its normal per-user cache
# and `make` and the IDE share native-asset outputs instead of rebuilding them.
LINUX_PUB_CACHE ?= $(APP_PROJECT_ROOT_DIR)/.pub-cache
PUB_CACHE    ?=
PROTOC_PATH  := $(shell which protoc 2>/dev/null)
# Toolchain installed for host-side checks/targets. Native-assets crates pick their own
# pinned toolchain via rust-toolchain.toml; do not export RUSTUP_TOOLCHAIN globally.
BOM_FILE     := $(APP_PROJECT_ROOT_DIR)/stack-bom.toml
BOM_RUST     := $(shell sed -n 's/^rust[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$(BOM_FILE)" 2>/dev/null | head -n1)
RUST_VERSION ?= $(if $(BOM_RUST),$(BOM_RUST),1.99.1)
# Only strip Nix/Apple variables when a Nix shell actually supplied them. In a
# Homebrew or manual shell these are the user's own settings and are kept.
ifeq ($(NIX_ACTIVE),1)
MACOS_ENV_UNSET = -u LD -u LDFLAGS -u NIX_LDFLAGS -u NIX_CFLAGS_LINK \
	-u CFLAGS -u CXXFLAGS -u CPPFLAGS \
	-u SDKROOT -u BINDGEN_EXTRA_CLANG_ARGS \
	-u IPHONEOS_DEPLOYMENT_TARGET -u TVOS_DEPLOYMENT_TARGET -u WATCHOS_DEPLOYMENT_TARGET \
	-u XROS_DEPLOYMENT_TARGET -u XR_DEPLOYMENT_TARGET
else
MACOS_ENV_UNSET =
endif

export APP_PROJECT_ROOT_DIR
ifneq ($(strip $(PUB_CACHE)),)
export PUB_CACHE
endif

.PHONY: help toolchain toolchain-check bootstrap bootstrap-brew require-version check-reqs check-reqs-macos check-sdk-macos check-linux check-windows bootstrap-macos bootstrap-xcode bootstrap-xcode-download sccache-setup cache-stats verify-bom clean clean-app clean-native build-macos build-linux build-windows diagnose-env-macos build-android android-dev-key build-ios

help: ## Show available commands
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

# --- TOOLCHAIN ---

toolchain: ## Show the active toolchain and tool paths
	@echo "requested : $(TOOLCHAIN)"
	@echo "effective : $(TOOLCHAIN_EFFECTIVE)"
	@echo "NIX_STORE : $${NIX_STORE:-<unset>}"
	@echo "DIRENV_DIR: $${DIRENV_DIR:-<unset>}"
	@echo "flutter   : $(if $(FLUTTER),$(FLUTTER),missing)"
	@echo "dart      : $(if $(DART),$(DART),missing)"
	@echo "rustup    : $$(command -v rustup || echo missing)"
ifeq ($(PLATFORM),Darwin)
	@echo "brew      : $$(command -v brew || echo missing)"
	@echo "xcode     : $$(xcode-select -p 2>/dev/null || echo missing)"
endif

toolchain-check: ## Fail when the requested toolchain is not active
ifeq ($(TOOLCHAIN_EFFECTIVE),nix)
	@[ -n "$$NIX_STORE$$IN_NIX_SHELL" ] || { echo >&2 "[ERROR] TOOLCHAIN=nix but this is not a Nix dev shell. Run 'nix develop' (or 'make bootstrap')."; exit 1; }
endif
ifeq ($(TOOLCHAIN_EFFECTIVE),direnv)
	@[ -n "$$NIX_STORE$$IN_NIX_SHELL" ] || { echo >&2 "[ERROR] TOOLCHAIN=direnv but the flake is not loaded. Run 'direnv allow', or use 'nix develop'."; exit 1; }
endif
ifeq ($(TOOLCHAIN_EFFECTIVE),brew)
	@command -v brew >/dev/null 2>&1 || { echo >&2 "[ERROR] TOOLCHAIN=brew but brew is not on PATH. Run 'make bootstrap-macos'."; exit 1; }
endif

bootstrap: ## Enter the Nix dev shell (primary toolchain; no-op when already inside)
	@if [ -n "$$NIX_STORE$$IN_NIX_SHELL" ]; then \
		echo "[OK] Already inside a Nix dev shell ($(TOOLCHAIN_EFFECTIVE))."; \
	elif ! command -v nix >/dev/null 2>&1; then \
		echo >&2 "[ERROR] Nix is not installed. Install it from https://nixos.org/download/, or use the Homebrew fallback: make bootstrap-macos"; \
		exit 1; \
	else \
		echo "Entering the Nix dev shell. Run 'make build-macos VERSION=... BUILD_NUM=...' inside it."; \
		exec nix develop; \
	fi

bootstrap-brew: bootstrap-macos ## Alias for the Homebrew fallback toolchain

check-linux: ## Fail unless the host is Linux
ifeq ($(PLATFORM),Linux)
	@:
else
	@echo >&2 "[ERROR] build-linux is Linux-only."
	@exit 1
endif

check-windows: ## Fail unless running from Git Bash on Windows
ifeq ($(filter MINGW% MSYS% CYGWIN%,$(PLATFORM)),)
	@echo >&2 "[ERROR] build-windows must run from Git Bash on Windows."
	@exit 1
else
	@:
endif

# --- PREREQUISITES ---

require-version: ## Fail unless VERSION and BUILD_NUM are set explicitly
	@[ -n "$(VERSION)" ] || { echo >&2 "[ERROR] VERSION is not set. Pass VERSION=x.y.z (latest release tag: $$(git tag -l 'build_*' --sort=-v:refname 2>/dev/null | head -n1))."; exit 1; }
	@[ -n "$(BUILD_NUM)" ] || { echo >&2 "[ERROR] BUILD_NUM is not set. Pass a build number above the latest release tag ($$(git tag -l 'build_*' --sort=-v:refname 2>/dev/null | head -n1))."; exit 1; }

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
			echo >&2 "[ERROR] Meson not installed. Use 'nix develop' (recommended) or run 'make bootstrap-macos'."; \
		elif [ "$(PLATFORM)" = "Linux" ]; then \
			echo >&2 "[ERROR] Meson not installed. On Linux/NixOS, run in 'nix develop' or install meson via your package manager."; \
		else \
			echo >&2 "[ERROR] Meson not installed. Install via your package manager."; \
		fi; \
		exit 1; \
	}
	@command -v ninja >/dev/null 2>&1 || { \
		if [ "$(PLATFORM)" = "Darwin" ]; then \
			echo >&2 "[ERROR] Ninja not installed. Use 'nix develop' (recommended) or run 'make bootstrap-macos'."; \
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
ifeq ($(PLATFORM),Linux)
	@command -v python3 >/dev/null 2>&1 || { echo >&2 "[ERROR] python3 not installed (needed to prepare the Linux release bundle)."; exit 1; }
	@command -v patchelf >/dev/null 2>&1 || { echo >&2 "[ERROR] patchelf not installed (Ubuntu 24.04: apt-get install patchelf binutils)."; exit 1; }
	@command -v readelf >/dev/null 2>&1 || { echo >&2 "[ERROR] readelf not installed (apt-get install binutils)."; exit 1; }
endif
	@echo "[OK] All core CLI requirements found!"

check-sdk-macos: ## Verify XCode on macOS
ifeq ($(PLATFORM),Darwin)
	@echo "Checking macOS SDK requirements..."
	@xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1 || ( \
		echo "[ERROR] macOS SDK not available. Install Xcode or run: sudo xcode-select --switch /Applications/Xcode.app"; \
		exit 1)
	@echo "[OK] macOS SDK available at: $$(xcrun --sdk macosx --show-sdk-path)"
else
	@echo >&2 "[ERROR] check-sdk-macos is macOS-only."
	@exit 1
endif

check-reqs-macos: check-reqs ## Verify macOS-specific tools are available in PATH
ifeq ($(PLATFORM),Darwin)
	@echo "Checking macOS-specific tools in PATH..."
	@rustup run $(RUST_VERSION) rustc -vV >/dev/null 2>&1 || { echo >&2 "[ERROR] Rust $(RUST_VERSION) toolchain not available. Run 'nix develop' (recommended) or 'make bootstrap-macos'."; exit 1; }
	@command -v pod >/dev/null 2>&1 || { echo >&2 "[ERROR] CocoaPods (pod) not installed."; exit 1; }
	@command -v xcodebuild >/dev/null 2>&1 || { echo >&2 "[ERROR] xcodebuild not available."; exit 1; }
	@echo "[OK] macOS-specific toolchain is available."
else
	@echo "[ERROR] check-reqs-macos is macOS-only."
	@exit 1
endif

bootstrap-macos: ## Install the Homebrew fallback toolchain (Nix is the primary path)
ifeq ($(PLATFORM),Darwin)
# Call install_xcode.sh directly instead of `$(MAKE) bootstrap-xcode`: a recipe
# line containing $(MAKE) is executed even under `make -n`, which would make a
# dry run accept the Xcode license and run first-launch setup for real.
	@if [ -n "$$IN_NIX_SHELL$$NIX_BUILD_TOP$$NIX_STORE" ]; then \
		echo "[WARN] Nix environment detected; skipping the Homebrew package install (use nix/flake-provided toolchain instead)."; \
		echo "[WARN] Xcode itself is never provided by Nix (Apple's license forbids redistributing it), so that part still runs:"; \
		bash scripts/install_xcode.sh || exit 1; \
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
	@[ -n "$(DART)" ] || { echo >&2 "[ERROR] Dart not installed (needed for verify-bom). Install Flutter or pass DART=/path/to/dart."; exit 1; }
	@FLUTTER="$(FLUTTER)" $(DART) tool/verify_bom.dart

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
	@chmod -R u+w $(LINUX_PUB_CACHE)/git/ 2>/dev/null || true
	@find $(LINUX_PUB_CACHE)/git/ -type d \( -name "build" -o -name "target" \) -path "*flutter_lib*" -exec rm -rf {} + 2>/dev/null || true
	@echo "[OK] Project is now in a pristine state."

# --- PLATFORM BUILDS ---

# dnix mode. macOS and Linux build the pinned native libraries from source by
# default (the Nix-primary developer path). Windows and CI use verified
# prebuilts. PREBUILTS=1 passes -d and needs no Nix for those four libraries;
# PREBUILTS=0 builds them with Nix and verifies the hashes.
ifeq ($(PLATFORM),Darwin)
PREBUILTS ?= 0
else
  ifeq ($(PLATFORM),Linux)
    PREBUILTS ?= 0
  else
    PREBUILTS ?= 1
  endif
endif
# Android source builds through dnix need an x86_64 Linux host.
ANDROID_PREBUILTS ?= $(if $(filter Darwin,$(PLATFORM)),1,$(PREBUILTS))
# Linux only: SYSTEM_DEPS=1 uses the system libsecret/jsoncpp packages instead of building them (like the CI image).
SYSTEM_DEPS ?= 0
LINUX_ARCH   := $(shell uname -m | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')
LINUX_BUNDLE ?= build/linux/$(LINUX_ARCH)/release/bundle

clean-app: ## Remove app build output (build/, Pods) but keep the native-asset build outputs, so the next build is fast
	@chflags -R nouchg build/ macos/ 2>/dev/null || true
	@chmod -R u+w build/ macos/ 2>/dev/null || true
	@rm -rf build/ macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock
	@echo "[OK] Removed build/ and Pods; .dart_tool/hooks_runner is kept."

clean-native: ## Remove only the native-asset build outputs (forces the Rust/Go/C libraries to be rebuilt)
	@chmod -R u+w .dart_tool/hooks_runner build/native_assets 2>/dev/null || true
	@rm -rf .dart_tool/hooks_runner build/native_assets
	@echo "[OK] Removed .dart_tool/hooks_runner and build/native_assets."

build-macos: require-version toolchain-check check-reqs-macos check-sdk-macos ## Build macOS release (source by default; PREBUILTS=1 uses verified prebuilts)
	@echo "--- Configuring project (scripts/build_app.sh)..."
	@cd scripts && echo yes | env $(MACOS_ENV_UNSET) ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p macos -a $(APP_NAME) -s $(if $(filter 1,$(PREBUILTS)),-d)
	@echo "--- Resolving dependencies..."
	@env $(MACOS_ENV_UNSET) $(FLUTTER) pub get
	@cd scripts && env $(MACOS_ENV_UNSET) bash prebuild.sh
	@echo "--- Final Compilation..."
	@env $(MACOS_ENV_UNSET) $(FLUTTER) build macos --release


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

build-linux: export PUB_CACHE := $(LINUX_PUB_CACHE)
build-linux: require-version check-linux toolchain-check check-reqs ## Build Linux Release through Flutter native-assets hooks
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
	@echo "--- Preparing release bundle..."
	@python3 scripts/linux/prepare_release_bundle.py $(LINUX_BUNDLE)

# Windows: run from Git Bash. Same steps as the "build-windows" job in .github/workflows/build.yaml.
# WINDOWS_COPY_ASSETS=1 makes link_assets.sh copy instead of creating symlinks, for hosts
# where the user cannot create them (for example the GitHub-hosted runner).
# Windows uses verified dnix prebuilts; source mode needs Nix inside WSL2 and is
# driven by build_app.sh directly, not by this target.
WINDOWS_COPY_ASSETS ?= 0

build-windows: require-version check-windows toolchain-check ## Build Windows release (Git Bash; verified dnix prebuilts)
	@command -v flutter >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo >&2 "[ERROR] Go not installed."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && echo yes | MWEBD_FETCH=1 WINDOWS_COPY_ASSETS=$(WINDOWS_COPY_ASSETS) ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p windows -a $(APP_NAME) -d -s
	@$(FLUTTER) pub get
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

build-android: require-version toolchain-check android-dev-key ## Build Android APKs (prebuilt dnix on macOS; Linux follows PREBUILTS)
	@command -v flutter >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@[ -n "$$ANDROID_SDK_ROOT$$ANDROID_HOME" ] || { echo >&2 "[ERROR] ANDROID_SDK_ROOT is not set (Android SDK/NDK required)."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && echo yes | ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p android -a $(APP_NAME) $(if $(filter 1,$(ANDROID_PREBUILTS)),-d) -s
	@$(FLUTTER) pub get
	@$(FLUTTER) build apk --split-per-abi --release

# iOS: same steps as the "build-ios" CI job (device build, no code signing). Run on macOS with Xcode.
build-ios: require-version check-sdk-macos toolchain-check ## Build iOS Runner.app without code signing (same steps as CI)
	@command -v flutter >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && echo yes | ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p ios -a $(APP_NAME) $(if $(filter 1,$(PREBUILTS)),-d) -s
	@$(FLUTTER) pub get
	@$(FLUTTER) build ios --release --no-codesign
