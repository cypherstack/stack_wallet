# ==============================================================================
# Stack Wallet build helper. Wraps scripts/build_app.sh; see docs/building.md
# Usage: make <target> VERSION=x.x.x BUILD_NUM=xxx
# ==============================================================================

APP_NAME     ?= stack_wallet
override APP_NAME := $(strip $(APP_NAME))
ifneq ($(words $(APP_NAME)),1)
  $(error APP_NAME must be a single value: stack_wallet, stack_duo or campfire)
endif
ifneq ($(filter $(APP_NAME),stack_wallet stack_duo campfire),$(APP_NAME))
  $(error APP_NAME must be stack_wallet, stack_duo or campfire)
endif
# build_app.sh asks before replacing generated app files because some
# version/build combinations can delete wallet data. Keep that prompt
# interactive unless the caller explicitly opts in.
CONFIRM      ?= 0
# Build targets require these explicitly: a stale default silently produces an
# app numbered below the current release line. See `require-version`.
VERSION      ?=
BUILD_NUM    ?=
FLUTTER      ?=
DART         ?=
# Make splits unquoted values on whitespace, so a tool path with a space would
# silently resolve to a different binary. Fail early instead.
ifneq ($(strip $(FLUTTER)),)
  ifneq ($(words $(FLUTTER)),1)
    $(error FLUTTER must not contain spaces; put it on PATH instead)
  endif
endif
ifneq ($(strip $(DART)),)
  ifneq ($(words $(DART)),1)
    $(error DART must not contain spaces; put it on PATH instead)
  endif
endif
# Capture explicit overrides before FLUTTER/DART are normalized below.
FLUTTER_USER := $(strip $(FLUTTER))
DART_USER := $(strip $(DART))
FLUTTER_BIN  := $(if $(FLUTTER),$(if $(findstring /,$(FLUTTER)),$(abspath $(FLUTTER)),$(FLUTTER)),$(shell command -v flutter 2>/dev/null))
# A Flutter SDK ships its own Dart next to the flutter binary; an explicit
# FLUTTER path should not require a second DART= argument.
DART_BIN     := $(if $(DART),$(if $(findstring /,$(DART)),$(abspath $(DART)),$(DART)),$(if $(filter /%,$(FLUTTER_BIN)),$(or $(wildcard $(dir $(FLUTTER_BIN))dart),$(shell command -v dart 2>/dev/null)),$(shell command -v dart 2>/dev/null)))
FLUTTER      := $(FLUTTER_BIN)
DART         := $(DART_BIN)
# Make splits unquoted values on whitespace. A Flutter found on PATH under a
# directory such as "Application Support" would resolve DART to the directory,
# and verify-bom would fail later with a misleading error.
ifneq ($(strip $(FLUTTER_BIN)),)
ifneq ($(words $(FLUTTER_BIN)),1)
$(error Flutter resolves to '$(FLUTTER_BIN)', which contains a space; move it to a path without spaces or pass FLUTTER=... from such a path)
endif
endif
ifneq ($(strip $(DART)),)
ifneq ($(words $(DART)),1)
$(error Dart resolves to '$(DART)', which contains a space; move it to a path without spaces or pass DART=... from such a path)
endif
endif
SYSTEM_DEPS ?= 0
# Child scripts call bare `flutter`/`dart`; keep them on the binaries checked
# above instead of whatever PATH would otherwise resolve. Only do this for an
# explicit override: prepending the directory of a Flutter that was already on
# PATH shadows unrelated tools and makes Flutter's hook runner rerun native
# builds because PATH changed.
ifneq ($(FLUTTER_USER),)
ifneq ($(filter /%,$(FLUTTER_BIN)),)
export PATH := $(dir $(FLUTTER_BIN)):$(PATH)
endif
endif
ifneq ($(DART_USER),)
ifneq ($(filter /%,$(DART)),)
export PATH := $(dir $(DART)):$(PATH)
endif
endif
APP_PROJECT_ROOT_DIR := $(CURDIR)
ifeq ($(wildcard Makefile),)
  $(error Run make from the repository root)
endif
# Platform detection from uname. PLATFORM can be overridden, but only with a
# supported value; an unrelated exported PLATFORM must not change the defaults.
UNAME_S        := $(shell uname -s 2>/dev/null)
UNAME_M        := $(shell uname -m 2>/dev/null)
NIX_BIN        := $(shell command -v nix 2>/dev/null)
PLATFORM       ?= $(UNAME_S)
ifneq ($(PLATFORM),Darwin)
  ifneq ($(PLATFORM),Linux)
    ifeq ($(filter MINGW% MSYS%,$(PLATFORM)),)
      $(error Unsupported PLATFORM '$(PLATFORM)'; expected Darwin, Linux or Git Bash on Windows)
    endif
  endif
endif
# Toolchain source. Source builds require Nix (nix develop or direnv); the
# prebuilt path (PREBUILTS=1) uses the host tools on PATH (manual or host).
# The build steps are identical in every mode: only the prerequisite check and
# the Nix environment sanitising differ. Override with TOOLCHAIN=nix|direnv|manual|host.
TOOLCHAIN      ?= auto
DIRENV_ACTIVE  := $(if $(DIRENV_DIR),1,)
NIX_ACTIVE     := $(if $(or $(IN_NIX_SHELL),$(NIX_STORE)),1,)
ifeq ($(strip $(TOOLCHAIN)),)
  $(error TOOLCHAIN must not be empty)
endif
ifneq ($(words $(TOOLCHAIN)),1)
  $(error TOOLCHAIN must be a single value)
endif
ifneq ($(filter $(TOOLCHAIN),auto nix direnv manual host),$(TOOLCHAIN))
  $(error TOOLCHAIN must be auto, nix, direnv, manual or host)
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
# Source builds require an active Nix/direnv shell (not just nix on PATH): the
# shell supplies the dnix libraries and the toolchain. SOURCE_TOOLCHAIN is set
# only inside such a shell; the prebuilt path (PREBUILTS=1) uses host tools.
override SOURCE_TOOLCHAIN := $(if $(filter nix direnv,$(TOOLCHAIN_EFFECTIVE)),1,)
# Linux builds use a project-local pub cache so cargo finds the repo-local
# .cargo/config.toml that carries PROTOC through Flutter's filtered hook environment.
# Other targets leave PUB_CACHE unset, so Flutter uses its normal per-user cache
# and `make` and the IDE share native-asset outputs instead of rebuilding them.
LINUX_PUB_CACHE ?= $(APP_PROJECT_ROOT_DIR)/.pub-cache
PUB_CACHE    ?=
PROTOC_PATH  := $(shell command -v protoc 2>/dev/null)
# Toolchain installed for host-side checks/targets. Native-assets crates pick their own
# pinned toolchain via rust-toolchain.toml; do not export RUSTUP_TOOLCHAIN globally.
BOM_FILE     := $(APP_PROJECT_ROOT_DIR)/stack-bom.toml
BOM_RUST     := $(shell bash "$(APP_PROJECT_ROOT_DIR)/scripts/bom_values.sh" --get rust "$(BOM_FILE)" 2>/dev/null)
RUST_VERSION ?= $(if $(BOM_RUST),$(BOM_RUST),$(error Cannot read [toolchain] rust from $(BOM_FILE)))
# Only strip Nix/Apple variables when a Nix shell actually supplied them. In a
# Homebrew or manual shell these are the user's own settings and are kept.
NIX_ENV_UNSET = -u LD -u LDFLAGS -u NIX_LDFLAGS -u NIX_CFLAGS_LINK \
	-u NIX_CFLAGS_COMPILE -u CFLAGS -u CXXFLAGS -u CPPFLAGS \
	-u SDKROOT -u BINDGEN_EXTRA_CLANG_ARGS
ifeq ($(NIX_ACTIVE),1)
MACOS_ENV_UNSET = $(NIX_ENV_UNSET) \
	-u IPHONEOS_DEPLOYMENT_TARGET -u TVOS_DEPLOYMENT_TARGET -u WATCHOS_DEPLOYMENT_TARGET \
	-u XROS_DEPLOYMENT_TARGET -u XR_DEPLOYMENT_TARGET
IOS_ENV_UNSET = $(NIX_ENV_UNSET)
else
MACOS_ENV_UNSET =
IOS_ENV_UNSET =
endif

export APP_PROJECT_ROOT_DIR
ifneq ($(strip $(PUB_CACHE)),)
export PUB_CACHE
endif

.PHONY: help toolchain toolchain-check bootstrap require-version check-reqs check-reqs-macos check-sdk-macos check-linux check-windows bootstrap-macos bootstrap-xcode sccache-setup cache-stats verify-bom clean clean-app clean-native build-macos build-linux build-windows diagnose-env-macos build-android android-dev-key build-ios

help: ## Show available commands
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' "$(firstword $(MAKEFILE_LIST))" | awk 'BEGIN {FS = ":.*?## "}; {printf "%-24s %s\n", $$1, $$2}'

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
ifeq ($(filter nix direnv,$(TOOLCHAIN_EFFECTIVE)),)
	@echo "[INFO] $(TOOLCHAIN_EFFECTIVE): using the tools on PATH; no separate check."
endif

bootstrap: ## Enter the Nix dev shell (primary toolchain; no-op when already inside)
	@if [ -n "$$NIX_STORE$$IN_NIX_SHELL" ]; then \
		echo "[OK] Already inside a Nix dev shell ($(TOOLCHAIN_EFFECTIVE))."; \
	elif [ "$(PLATFORM)" = "Darwin" ] && [ "$(UNAME_M)" != "arm64" ] && [ "$(UNAME_M)" != "aarch64" ]; then \
		echo >&2 "[ERROR] Intel macOS is prebuilt-only; use 'make bootstrap-macos' (or a manual toolchain) and PREBUILTS=1."; \
		exit 1; \
	elif ! command -v nix >/dev/null 2>&1; then \
		echo >&2 "[ERROR] Nix is not installed. Source builds require Nix; install it from https://nixos.org/download/."; \
		exit 1; \
	else \
	@echo "Entering the Nix dev shell. Run 'make build-macos VERSION=... BUILD_NUM=...' inside it."; \
	exec nix --extra-experimental-features 'nix-command flakes' develop; \
	fi

check-linux: ## Fail unless the host is Linux
ifeq ($(PLATFORM),Linux)
	@:
else
	@echo >&2 "[ERROR] build-linux is Linux-only."
	@exit 1
endif

check-windows: ## Fail unless running from Git Bash on Windows
ifeq ($(filter MINGW% MSYS%,$(PLATFORM)),)
	@echo >&2 "[ERROR] build-windows must run from Git Bash on Windows."
	@exit 1
else
	@:
endif

# --- PREREQUISITES ---

require-version: ## Fail unless VERSION/BUILD_NUM are valid and BUILD_NUM is not below the latest release tag
	@printf '%s' '$(VERSION)' | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$$' || { echo >&2 "[ERROR] VERSION must be x.y.z or x.y.z-suffix (got '$(VERSION)'; latest release tag: $$(git tag -l 'build_*' --sort=-v:refname 2>/dev/null | head -n1))."; exit 1; }
	@printf '%s' '$(BUILD_NUM)' | grep -Eq '^[0-9]+$' || { echo >&2 "[ERROR] BUILD_NUM must be numeric (got '$(BUILD_NUM)'; latest release tag: $$(git tag -l 'build_*' --sort=-v:refname 2>/dev/null | head -n1))."; exit 1; }
	@latest="$$(git tag -l 'build_*' --sort=-v:refname 2>/dev/null | sed -n 's/^build_\([0-9][0-9]*\)$$/\1/p' | head -n1)"; \
	if [ -n "$$latest" ]; then \
	  [ "$(BUILD_NUM)" -ge "$$latest" ] || { echo >&2 "[ERROR] BUILD_NUM $(BUILD_NUM) is below the latest release tag build_$$latest."; exit 1; }; \
	  if [ "$(BUILD_NUM)" -eq "$$latest" ]; then \
	    echo "[INFO] Rebuilding release tag build_$$latest with BUILD_NUM=$(BUILD_NUM)."; \
	  fi; \
	else \
	  echo "[INFO] No numeric build_* tag found; skipping BUILD_NUM comparison."; \
	fi

check-reqs: ## Verify essential build tools
	@echo "Checking core prerequisites..."
	@[ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed. Use 'nix develop' (recommended) or add Flutter to PATH."; exit 1; }
	@[ -n "$(DART)" ] && command -v "$(DART)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Dart not installed. It ships with Flutter; use 'nix develop' (recommended)."; exit 1; }
	@command -v rustup >/dev/null 2>&1 || { echo >&2 "[ERROR] rustup not installed."; exit 1; }
	@rustup run 1.90.0 rustc --version >/dev/null 2>&1 || { echo >&2 "[ERROR] Rust 1.90.0 (DNSSEC) not installed via rustup."; exit 1; }
	@rustup run 1.99.1 rustc --version >/dev/null 2>&1 || { echo >&2 "[ERROR] Rust 1.99.1 not installed via rustup."; exit 1; }
	@# `rustup which cargo` resolves a toolchain path even when no shim is on PATH,
	@# but the plugin build scripts invoke bare `cargo` — verify that separately.
	@command -v cargo >/dev/null 2>&1 || [ -x "$$HOME/.cargo/bin/cargo" ] || { echo >&2 "[ERROR] 'cargo' is not on PATH (rustup shims missing from ~/.cargo/bin). Run 'rustup-init -y', then open a new terminal."; exit 1; }
# Go is only needed for Stack Wallet's MWEB build; Stack Duo and Campfire do not use it.
ifeq ($(APP_NAME),stack_wallet)
	@command -v go >/dev/null 2>&1 || { echo >&2 "[ERROR] Go not installed (needed for Stack Wallet's MWEB build)."; exit 1; }
endif
	@command -v cmake >/dev/null 2>&1 || { echo >&2 "[ERROR] CMake not installed."; exit 1; }
ifeq ($(PLATFORM),Linux)
	@command -v protoc >/dev/null 2>&1 || { echo >&2 "[ERROR] protoc not installed (protobuf, needed for the Linux build)."; exit 1; }
ifeq ($(SYSTEM_DEPS),0)
	@command -v meson >/dev/null 2>&1 || { echo >&2 "[ERROR] Meson not installed (needed to build sysprof/libsecret; use SYSTEM_DEPS=1 to use host libraries)."; exit 1; }
	@command -v ninja >/dev/null 2>&1 || { echo >&2 "[ERROR] Ninja not installed (needed to build sysprof/libsecret; use SYSTEM_DEPS=1 to use host libraries)."; exit 1; }
endif
endif
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
	@patchelf --help 2>&1 | grep -q -- '--clear-execstack' || { echo >&2 "[ERROR] patchelf >= 0.18 is required (--clear-execstack). Use 'nix develop' or install a newer patchelf."; exit 1; }
	@command -v readelf >/dev/null 2>&1 || { echo >&2 "[ERROR] readelf not installed (apt-get install binutils)."; exit 1; }
endif
	@echo "[OK] All core CLI requirements found!"

check-sdk-macos: ## Verify XCode on macOS
ifeq ($(PLATFORM),Darwin)
	@echo "Checking macOS SDK requirements..."
	@dev="$${DEVELOPER_DIR:-$$(xcode-select -p 2>/dev/null || true)}"; \
	 case "$$dev" in \
	   *.app/Contents/Developer) ;; \
	   *) echo >&2 "[ERROR] Full Xcode is required (DEVELOPER_DIR or xcode-select -p = $$dev). Install Xcode or run 'make bootstrap-xcode'."; exit 1 ;; \
	 esac
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
	@rustup run $(RUST_VERSION) rustc -vV >/dev/null 2>&1 || { echo >&2 "[ERROR] Rust $(RUST_VERSION) toolchain not available. Run 'rustup toolchain install $(RUST_VERSION)', or use 'nix develop'/'make bootstrap-macos'."; exit 1; }
	@command -v pod >/dev/null 2>&1 || { echo >&2 "[ERROR] CocoaPods (pod) not installed."; exit 1; }
	@command -v xcodebuild >/dev/null 2>&1 || { echo >&2 "[ERROR] xcodebuild not available."; exit 1; }
	@echo "[OK] macOS-specific toolchain is available."
else
	@echo "[ERROR] check-reqs-macos is macOS-only."
	@exit 1
endif

bootstrap-macos: ## Install Nix + check/select the full Xcode.app (source-build bootstrap)
ifeq ($(PLATFORM),Darwin)
# Call install_*.sh directly instead of `$(MAKE) bootstrap-xcode`: a recipe
# line containing $(MAKE) is executed even under `make -n`, which would make a
# dry run accept the Xcode license and run first-launch setup for real.
# Source builds require a Nix/direnv shell (the flake provides Flutter, Rust,
# Go and the dnix libraries); install Nix if it is missing. Xcode itself is
# never provided by Nix (Apple's license forbids redistributing it), so it is
# checked/selected too. Both installers are idempotent.
	@bash scripts/install_nix.sh
	@bash scripts/install_xcode.sh
else
	@echo "[ERROR] bootstrap-macos is macOS-only."
	@exit 1
endif

bootstrap-xcode: ## Check/select an installed full Xcode.app (may ask for sudo to accept the licence)
ifeq ($(PLATFORM),Darwin)
	@bash scripts/install_xcode.sh
else
	@echo "[ERROR] bootstrap-xcode is macOS-only."
	@exit 1
endif

SCCACHE_CARGO_CONFIG ?= $(if $(CARGO_HOME),$(CARGO_HOME),$(HOME)/.cargo)/config.toml

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

verify-bom: ## Check the local toolchain against stack-bom.toml
	@[ -n "$(DART)" ] || { echo >&2 "[ERROR] Dart not installed (needed for verify-bom). Install Flutter or pass DART=/path/to/dart."; exit 1; }
	@bash scripts/bom_values.sh --check
	@FLUTTER="$(FLUTTER)" "$(DART)" tool/verify_bom.dart --app "$(APP_NAME)"

verify-bom-toolchains: ## Check only the installed toolchain (skip pubspec.lock pins); for CI to run on the runner before the prebuilt image
	@[ -n "$(DART)" ] || { echo >&2 "[ERROR] Dart not installed (needed for verify-bom-toolchains). Install Flutter or pass DART=/path/to/dart."; exit 1; }
	@bash scripts/bom_values.sh --check
	@FLUTTER="$(FLUTTER)" "$(DART)" tool/verify_bom.dart --toolchains

cache-stats: ## Show sccache statistics (hit rate) after a build
	@command -v sccache >/dev/null 2>&1 || { echo >&2 "[ERROR] sccache not installed."; exit 1; }
	@sccache --show-stats

clean: ## Remove artifacts and fix permissions
	@echo "Cleaning Flutter and Rust artifacts..."
	@chflags -R nouchg build/ macos/ 2>/dev/null || true
	@chmod -R u+w build/ macos/ 2>/dev/null || true
	@if [ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 && [ -f pubspec.yaml ]; then "$(FLUTTER)" clean || echo "[WARN] 'flutter clean' failed; continuing."; else echo "[WARN] Flutter not available; skipped 'flutter clean'."; fi
	@rm -rf macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock build/
	@echo "Cleaning local pub cache residues..."
	@chmod -R u+w "$(LINUX_PUB_CACHE)/git/" 2>/dev/null || true
	@find "$(LINUX_PUB_CACHE)/git/" -type d \( -name "build" -o -name "target" \) -path "*flutter_lib*" -exec rm -rf {} + 2>/dev/null || true
	@echo "[OK] Removed the Flutter build output and local caches."

# --- PLATFORM BUILDS ---

# dnix mode. A source build needs Nix on PATH to build the pinned native
# libraries. It is the default on Apple Silicon macOS and on Linux; Intel
# macOS, Windows and CI use verified prebuilts. PREBUILTS=1 passes -d and
# needs no Nix for those four libraries; PREBUILTS=0 builds them with Nix and
# verifies hashes. Any macOS/Linux toolchain can build from source when Nix
# is installed: the restriction is the nix binary, not the setup route.
ifeq ($(strip $(SOURCE_TOOLCHAIN)),)
  PREBUILTS_DEFAULT := 1
else ifeq ($(PLATFORM),Darwin)
  ifeq ($(filter arm64 aarch64,$(UNAME_M)),)
    PREBUILTS_DEFAULT := 1
  else
    PREBUILTS_DEFAULT := 0
  endif
else ifeq ($(PLATFORM),Linux)
  PREBUILTS_DEFAULT := 0
else
  PREBUILTS_DEFAULT := 1
endif
PREBUILTS ?= $(PREBUILTS_DEFAULT)
ifeq ($(strip $(PREBUILTS)),)
  override PREBUILTS := $(PREBUILTS_DEFAULT)
endif
ifneq ($(words $(PREBUILTS)),1)
  $(error PREBUILTS must be 0 or 1)
endif
ifneq ($(filter $(PREBUILTS),0 1),$(PREBUILTS))
  $(error PREBUILTS must be 0 or 1)
endif
ifeq ($(PREBUILTS),0)
  ifeq ($(PLATFORM),Darwin)
    ifeq ($(filter arm64 aarch64,$(UNAME_M)),)
      $(error PREBUILTS=0 (dnix source) requires Apple Silicon on macOS; use the default PREBUILTS=1)
    endif
  endif
  ifeq ($(filter Darwin Linux,$(PLATFORM)),$(PLATFORM))
    ifeq ($(filter nix direnv,$(TOOLCHAIN_EFFECTIVE)),)
      $(error PREBUILTS=0 (dnix source) requires an active Nix/direnv shell (TOOLCHAIN=nix or direnv); run 'make bootstrap' or use PREBUILTS=1)
    endif
  endif
endif
ifneq ($(filter MINGW% MSYS%,$(PLATFORM)),)
  ifeq ($(PREBUILTS),0)
    $(error build-windows uses verified dnix prebuilts; run build_app.sh for source mode)
  endif
endif
# Android source builds through dnix need an x86_64 Linux host with Nix on PATH.
# Every other host defaults to the verified prebuilts; that combination
# follows PREBUILTS.
ANDROID_ARCH   := $(UNAME_M)
override ANDROID_SOURCE_OK := $(and $(filter Linux,$(PLATFORM)),$(filter x86_64,$(ANDROID_ARCH)),$(strip $(SOURCE_TOOLCHAIN)),$(strip $(NIX_BIN)))
ANDROID_PREBUILTS_DEFAULT := $(if $(ANDROID_SOURCE_OK),$(PREBUILTS),1)
ANDROID_PREBUILTS ?= $(ANDROID_PREBUILTS_DEFAULT)
ifeq ($(strip $(ANDROID_PREBUILTS)),)
  override ANDROID_PREBUILTS := $(ANDROID_PREBUILTS_DEFAULT)
endif
ifneq ($(words $(ANDROID_PREBUILTS)),1)
  $(error ANDROID_PREBUILTS must be 0 or 1)
endif
ifneq ($(filter $(ANDROID_PREBUILTS),0 1),$(ANDROID_PREBUILTS))
  $(error ANDROID_PREBUILTS must be 0 or 1)
endif
ifeq ($(ANDROID_PREBUILTS),0)
  ifeq ($(strip $(ANDROID_SOURCE_OK)),)
    $(error ANDROID_PREBUILTS=0 requires TOOLCHAIN=nix or direnv on x86_64 Linux; use the prebuilt mode)
  endif
endif
# Linux only: SYSTEM_DEPS=1 uses the system libsecret/jsoncpp packages instead of building them (like the CI image).
SYSTEM_DEPS ?= 0
ifneq ($(words $(SYSTEM_DEPS)),1)
  $(error SYSTEM_DEPS must be 0 or 1)
endif
ifneq ($(filter $(SYSTEM_DEPS),0 1),$(SYSTEM_DEPS))
  $(error SYSTEM_DEPS must be 0 or 1)
endif
LINUX_ARCH   := $(shell printf '%s' '$(UNAME_M)' | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')
LINUX_BUNDLE ?= build/linux/$(LINUX_ARCH)/release/bundle

clean-app: ## Remove app build output (build/, Pods) but keep .dart_tool/hooks_runner, so the next build is fast
	@chflags -R nouchg build/ macos/ 2>/dev/null || true
	@chmod -R u+w build/ macos/ 2>/dev/null || true
	@rm -rf build/ macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock
	@echo "[OK] Removed build/ and Pods; .dart_tool/hooks_runner is kept."

clean-native: ## Remove only the native-asset build outputs (forces the Rust/Go/C libraries to be rebuilt)
	@chflags -R nouchg .dart_tool/hooks_runner build/native_assets 2>/dev/null || true
	@chmod -R u+w .dart_tool/hooks_runner build/native_assets 2>/dev/null || true
	@rm -rf .dart_tool/hooks_runner build/native_assets
	@echo "[OK] Removed .dart_tool/hooks_runner and build/native_assets."

build-macos: require-version verify-bom toolchain-check check-reqs-macos check-sdk-macos ## Build macOS release (source in Nix/direnv on Apple Silicon; PREBUILTS=1 uses verified prebuilts)
	@echo "--- Configuring project (scripts/build_app.sh)..."
	@cd scripts && $(if $(filter 1,$(CONFIRM)),echo yes |,) env $(MACOS_ENV_UNSET) ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p macos -a "$(APP_NAME)" $(if $(filter 1,$(PREBUILTS)),-d)
	@echo "--- Resolving dependencies..."
	@env $(MACOS_ENV_UNSET) "$(FLUTTER)" pub get
	@cd scripts && env $(MACOS_ENV_UNSET) bash prebuild.sh
	@echo "--- Final Compilation..."
	@env $(MACOS_ENV_UNSET) "$(FLUTTER)" build macos --release


diagnose-env-macos: ## Print macOS build env and tool resolution
	@echo "--- Toolchain diagnostics ---"
	@echo "flutter: $$(command -v "$(FLUTTER)" || echo missing)"
	@echo "dart: $$(command -v "$(DART)" || echo missing)"
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

# Respect a caller's PUB_CACHE. Only NixOS needs the repo-local cache (for the
# protoc workaround below); elsewhere use the normal per-user cache.
build-linux: export PUB_CACHE := $(or $(PUB_CACHE),$(if $(wildcard /etc/NIXOS),$(LINUX_PUB_CACHE)),$(HOME)/.pub-cache)
build-linux: require-version verify-bom check-linux toolchain-check check-reqs ## Build Linux release (source when nix is on PATH; PREBUILTS=1 uses verified prebuilts)
	@echo "--- Running prebuild bootstrap..."
	@cd scripts && bash prebuild.sh
	@echo "--- Generating config..."
	@if [ -z "$(PROTOC_PATH)" ]; then echo "[ERROR] protoc not found!"; exit 1; fi
	@cd scripts && $(if $(filter 1,$(CONFIRM)),yes yes |,) BUILD_ISAR_FROM_SOURCE=0 PROTOC="$(PROTOC_PATH)" ./build_app.sh -a "$(APP_NAME)" -p linux -v $(VERSION) -b $(BUILD_NUM) $(if $(filter 1,$(PREBUILTS)),-d) $(if $(filter 1,$(SYSTEM_DEPS)),-s)
	@# Flutter 3.47.x hooks only see a filtered environment, so PROTOC (exported by the flake) never
	@# reaches cargo build scripts. Some crates (prost-build 0.7) ship a generic-Linux protoc that cannot
	@# run on NixOS. cargo reads [env] from .cargo/config.toml found from the package dir upwards; the
	@# project-local PUB_CACHE under /etc/NIXOS keeps that lookup inside the checkout.
	@# Rewrite the file when the store path changes or the recorded path is gone.
	@mkdir -p .cargo; \
	recorded=$$(sed -n 's/^PROTOC = "\(.*\)"$$/\1/p' .cargo/config.toml 2>/dev/null | head -n 1); \
	if [ ! -e .cargo/config.toml ] || [ "$$recorded" != "$(PROTOC_PATH)" ] || [ ! -e "$$recorded" ]; then \
		printf '[env]\nPROTOC = "%s"\n' "$(PROTOC_PATH)" > .cargo/config.toml; \
		echo "[OK] Wrote .cargo/config.toml (PROTOC=$(PROTOC_PATH))"; \
	fi
	@echo "--- Building app..."
	@"$(FLUTTER)" pub get
	@if [ "$(SYSTEM_DEPS)" = "1" ]; then \
		USE_SYSTEM_SECURE_STORAGE_DEPS=1 PROTOC="$(PROTOC_PATH)" "$(FLUTTER)" build linux --release; \
	else \
		SYSPROF_PC_DIR="$${SYSPROF_PC_DIR:-}"; \
		PC_PATH=$$(pkg-config --variable=pc_path pkg-config 2>/dev/null || echo ""); \
		PKG_CONFIG_DISABLE_UNINSTALLED=1 PKG_CONFIG_PATH="$${PKG_CONFIG_PATH:-}" \
		PKG_CONFIG_LIBDIR="$(CURDIR)/scripts/linux/pc$${SYSPROF_PC_DIR:+:$$SYSPROF_PC_DIR}:$$PC_PATH" \
		pkg-config --modversion libsecret-1 >/dev/null || \
		{ echo "[ERROR] libsecret-1 not resolvable via pkg-config"; exit 1; }; \
		PKG_CONFIG_DISABLE_UNINSTALLED=1 PKG_CONFIG_PATH="$${PKG_CONFIG_PATH:-}" \
		PKG_CONFIG_LIBDIR="$(CURDIR)/scripts/linux/pc$${SYSPROF_PC_DIR:+:$$SYSPROF_PC_DIR}:$$PC_PATH" \
		PROTOC="$(PROTOC_PATH)" "$(FLUTTER)" build linux --release; \
	fi
	@echo "--- Preparing release bundle..."
	@python3 scripts/linux/prepare_release_bundle.py $(LINUX_BUNDLE)

# Windows: run from Git Bash. Same steps as the "build-windows" job in .github/workflows/build.yaml.
# Windows uses verified dnix prebuilts; source mode needs Nix inside WSL2 and is
# driven by build_app.sh directly, not by this target.
build-windows: require-version verify-bom check-windows toolchain-check ## Build Windows release (Git Bash; verified dnix prebuilts)
	@[ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && $(if $(filter 1,$(CONFIRM)),echo yes |,) MWEBD_FETCH=1 ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p windows -a "$(APP_NAME)" -d
	@"$(FLUTTER)" pub get
	@"$(FLUTTER)" build windows --release

# Android: same steps as the "build-android" CI job, without the signing secrets. Needs the Android SDK/NDK
# (ANDROID_SDK_ROOT) and Java; the CI image ghcr.io/<owner>/stackwallet-ci:android is built from the Dockerfile
# (docker build --target android). Run `make android-dev-key` to create a throw-away debug key when
# android/key.properties is missing; build-android requires that file and the APKs are not suitable for distribution.
android-dev-key: ## Create a throw-away debug signing key if android/key.properties is missing (never use for releases)
	@keytool -help >/dev/null 2>&1 || { echo >&2 "[ERROR] keytool not found; install a JDK (macOS /usr/bin/keytool is a stub)."; exit 1; }
	@umask 077; if [ ! -f android/key.properties ]; then \
		echo "[INFO] android/key.properties missing: creating a throw-away debug key (not for releases)"; \
		keytool -genkeypair -keystore android/dev-keystore.jks -storetype pkcs12 -storepass android -keypass android \
			-alias devkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Stack Wallet dev build" -noprompt && \
		printf 'storeFile=../dev-keystore.jks\nstorePassword=android\nkeyPassword=android\nkeyAlias=devkey\n' > android/key.properties; \
	fi
	@chmod 600 android/key.properties android/dev-keystore.jks 2>/dev/null || true

build-android: require-version verify-bom toolchain-check ## Build Android APKs (requires android/key.properties; prebuilt unless x86_64 Linux in Nix/direnv follows PREBUILTS)
	@[ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@[ -f android/key.properties ] || { echo >&2 "[ERROR] android/key.properties is missing. Run 'make android-dev-key' for a local throw-away key; never distribute APKs signed with it."; exit 1; }
	@if grep -q '^keyAlias=devkey$$' android/key.properties 2>/dev/null; then \
		echo "[WARN] Signing with the public throw-away dev key; this APK is for local testing only."; \
	fi
	@if [ -z "$$ANDROID_SDK_ROOT$$ANDROID_HOME" ]; then echo "[WARN] ANDROID_SDK_ROOT/ANDROID_HOME not set; using the SDK Flutter is configured with."; fi
	@cd scripts && bash prebuild.sh
	@cd scripts && $(if $(filter 1,$(CONFIRM)),echo yes |,) ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p android -a "$(APP_NAME)" $(if $(filter 1,$(ANDROID_PREBUILTS)),-d)
	@"$(FLUTTER)" pub get
	@"$(FLUTTER)" build apk --split-per-abi --release

# iOS: same steps as the "build-ios" CI job (device build, no code signing). Run on macOS with Xcode.
build-ios: require-version verify-bom toolchain-check check-reqs-macos check-sdk-macos ## Build iOS Runner.app without code signing (source in Nix/direnv on Apple Silicon; same steps as CI)
	@[ -n "$(FLUTTER)" ] && command -v "$(FLUTTER)" >/dev/null 2>&1 || { echo >&2 "[ERROR] Flutter not installed."; exit 1; }
	@xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1 || { echo >&2 "[ERROR] iOS SDK not available; install the iOS platform in Xcode."; exit 1; }
	@cd scripts && bash prebuild.sh
	@cd scripts && $(if $(filter 1,$(CONFIRM)),echo yes |,) env $(IOS_ENV_UNSET) ./build_app.sh -v $(VERSION) -b $(BUILD_NUM) -p ios -a "$(APP_NAME)" $(if $(filter 1,$(PREBUILTS)),-d)
	@env $(IOS_ENV_UNSET) "$(FLUTTER)" pub get
	@env $(IOS_ENV_UNSET) "$(FLUTTER)" build ios --release --no-codesign
