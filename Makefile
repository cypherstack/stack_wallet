# Stack Wallet builds.
#
# Each build-<platform> target configures one brand with tool/branding and
# builds its flavor. With NIX=1 (default except on Windows) the build runs in
# the nix_dart dev shell for that platform, using the Flutter SDK pinned in
# nix.yaml; with NIX=0 it uses the tools on PATH.
#
#   make build-linux APP=stack_wallet VERSION=2.4.0 BUILD_NUM=240
#
# Certain VERSION and BUILD_NUM values make the resulting app delete wallet
# data during migration. Choose them with the release history in mind.

APP       ?= stack_wallet
VERSION   ?=
BUILD_NUM ?=
# 1 uses the CI prebuilt native assets listed in the pubspec template.
PREBUILTS ?= 1
# 1 lets configuration replace generated files it does not own yet.
OVERWRITE ?= 0
NIX       ?= 1

NIX_DART     ?= $(or $(PUB_CACHE),$(HOME)/.pub-cache)/bin/nix_dart
NIX_DART_URL ?= https://github.com/ManyMath/nix.git
NIX_DART_REF ?= 030805856c925ac83297e90b6393a52478c1f289

# Linux only: 1 links the system libsecret and jsoncpp, as CI does.
USE_SYSTEM_SECURE_STORAGE_DEPS ?= 1
# Windows only: 1 downloads the pinned mwebd.exe release, 0 builds it.
MWEBD_FETCH ?= 1

export APP VERSION BUILD_NUM PREBUILTS OVERWRITE USE_SYSTEM_SECURE_STORAGE_DEPS

BRANDS := stack_wallet stack_duo campfire
UNIX_PLATFORMS := linux android macos ios

# Nix runs only inside WSL on Windows; Windows builds use the host tools.
ifeq ($(OS),Windows_NT)
override NIX := 0
endif

# Configuration runs outside the dev shell; with NIX=1 it uses the pinned SDK.
ifeq ($(NIX),1)
SDK_BIN := $(CURDIR)/.flutter-sdk/flutter/bin/
else
SDK_BIN :=
endif

.PHONY: help check-reqs nix-dart \
	$(addprefix setup-,$(UNIX_PLATFORMS)) \
	$(addprefix configure-,$(UNIX_PLATFORMS) windows) \
	$(addprefix build-,$(UNIX_PLATFORMS) windows) \
	$(addprefix flutter-build-,$(UNIX_PLATFORMS) windows) \
	$(addprefix shell-,$(UNIX_PLATFORMS)) \
	android-dev-key clean clean-app clean-native

help:
	@echo "build-<platform>      configure APP and build its flavor (linux android macos ios windows)"
	@echo "configure-<platform>  configure APP only"
	@echo "shell-<platform>      enter the nix_dart dev shell (linux android macos ios)"
	@echo "setup-<platform>      fetch the SDKs pinned in nix.yaml"
	@echo "check-reqs            check the tools the selected mode needs"
	@echo "clean-app             remove build/ and Pods; keep native-asset outputs"
	@echo "clean-native          remove native-asset outputs"
	@echo "clean                 both of the above"
	@echo
	@echo "Variables:            APP=$(APP) VERSION=$(VERSION) BUILD_NUM=$(BUILD_NUM)"
	@echo "                      PREBUILTS=$(PREBUILTS) OVERWRITE=$(OVERWRITE) NIX=$(NIX)"

check-reqs:
ifeq ($(NIX),1)
	@command -v nix >/dev/null 2>&1 || { echo >&2 "nix not found"; exit 1; }
	@command -v dart >/dev/null 2>&1 || { echo >&2 "dart not found; nix_dart is installed with it"; exit 1; }
else
	@for tool in flutter dart rustup cargo go cmake meson ninja protoc; do \
		command -v $$tool >/dev/null 2>&1 || { echo >&2 "$$tool not found"; exit 1; }; \
	done
endif
	@echo "Requirements found."

# --- Toolchain (NIX=1) ---

nix-dart:
	@if [ "$$(cat .dart_tool/nix_dart.ref 2>/dev/null)" != "$(NIX_DART_REF)" ] || \
		! command -v $(NIX_DART) >/dev/null 2>&1; then \
		dart pub global activate --source git $(NIX_DART_URL) \
			--git-ref $(NIX_DART_REF) --git-path packages/nix && \
		mkdir -p .dart_tool && echo "$(NIX_DART_REF)" > .dart_tool/nix_dart.ref; \
	fi

# Fetches the Flutter SDK pinned in nix.yaml and, for android, the Android SDK.
$(addprefix setup-,$(UNIX_PLATFORMS)): setup-%: nix-dart
	$(NIX_DART) setup $*

$(addprefix shell-,$(UNIX_PLATFORMS)): shell-%: setup-%
	$(NIX_DART) shell $*

# --- Configuration ---

# Writes the brand's generated files, resolves packages, and generates icons
# and splash screens: everything scripts/build_app.sh did before a build.
$(addprefix configure-,$(UNIX_PLATFORMS) windows): configure-%: $(if $(filter 1,$(NIX)),setup-%)
	@[ -n "$(VERSION)" ] && [ -n "$(BUILD_NUM)" ] || \
		{ echo >&2 "Set VERSION and BUILD_NUM"; exit 1; }
	@case " $(BRANDS) " in *" $(APP) "*) ;; \
		*) echo >&2 "APP must be one of: $(BRANDS)"; exit 1;; esac
	bash scripts/prebuild.sh
	$(if $(call ships_mwebd,$*),"$(SDK_BIN)dart" tool/build_standalone_mwebd_windows.dart $(if $(filter 1,$(MWEBD_FETCH)),--fetch))
	"$(SDK_BIN)dart" tool/branding/configure.dart --brand $(APP) --platforms $* \
		--version $(VERSION) --build-number $(BUILD_NUM) --flavor $(APP) --apply \
		$(if $(filter 1,$(PREBUILTS)),--prebuilts) \
		$(if $(filter 1,$(OVERWRITE)),--overwrite) \
		$(if $(call ships_mwebd,$*),--mwebd-sha256 "$$(sha256sum assets/windows/mwebd.exe | cut -d' ' -f1)")
	"$(SDK_BIN)flutter" pub get
	$(if $(filter-out linux,$*),"$(SDK_BIN)dart" run flutter_launcher_icons \
		-f scripts/app_config/platforms/$*/flutter_launcher_icons.yaml)
	$(if $(filter android ios,$*),"$(SDK_BIN)dart" run flutter_native_splash:create \
		--path scripts/app_config/platforms/$*/flutter_native_splash.yaml)

# Only stack_wallet ships mwebd.exe, and only on Windows.
ships_mwebd = $(and $(filter windows,$(1)),$(filter stack_wallet,$(APP)))

# --- Builds ---

$(addprefix build-,$(UNIX_PLATFORMS)): build-%: configure-%
ifeq ($(NIX),1)
	$(NIX_DART) build $*
else
	$(MAKE) flutter-build-$*
endif

# Windows builds natively from Git Bash with the tools on PATH.
build-windows: configure-windows
	$(MAKE) flutter-build-windows

# These run after configuration, inside the dev shell with NIX=1; see nix.yaml.
flutter-build-linux:
	flutter build linux --release --flavor $(APP)
	python3 scripts/linux/prepare_release_bundle.py build/linux/x64/$(APP)/release/bundle

flutter-build-android: android-dev-key
	flutter build apk --split-per-abi --release --flavor $(APP)

flutter-build-macos:
	flutter build macos --release --flavor $(APP)

flutter-build-ios:
	flutter build ios --release --no-codesign --flavor $(APP)

flutter-build-windows:
	dart run coinlib:build_windows
	flutter build windows --release --flavor $(APP)

# Signs release APKs with a throw-away key when android/key.properties is
# missing. Never distribute APKs signed with it.
android-dev-key:
	@if [ ! -f android/key.properties ]; then \
		echo "android/key.properties missing; creating a throw-away key"; \
		keytool -genkeypair -keystore android/dev-keystore.jks -storetype pkcs12 \
			-storepass android -keypass android -alias devkey -keyalg RSA \
			-keysize 2048 -validity 10000 -dname "CN=Stack Wallet dev build" -noprompt && \
		printf 'storeFile=../dev-keystore.jks\nstorePassword=android\nkeyPassword=android\nkeyAlias=devkey\n' \
			> android/key.properties; \
	fi

# --- Cleaning ---

clean-app:
	@chmod -R u+w build/ 2>/dev/null || true
	rm -rf build/ macos/Pods macos/Podfile.lock ios/Pods ios/Podfile.lock

clean-native:
	@chmod -R u+w .dart_tool/hooks_runner build/native_assets 2>/dev/null || true
	rm -rf .dart_tool/hooks_runner build/native_assets

clean: clean-app clean-native
