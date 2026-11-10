# Stack Wallet builds.
#
# Each build-<platform> target configures one brand with tool/branding and
# builds its flavor with the tools on PATH.
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

# Linux only: 1 links the system libsecret and jsoncpp, as CI does.
USE_SYSTEM_SECURE_STORAGE_DEPS ?= 1
# Windows only: 1 downloads the pinned mwebd.exe release, 0 builds it.
MWEBD_FETCH ?= 1

export APP VERSION BUILD_NUM PREBUILTS OVERWRITE USE_SYSTEM_SECURE_STORAGE_DEPS

BRANDS := stack_wallet stack_duo campfire
UNIX_PLATFORMS := linux android macos ios

.PHONY: help check-reqs \
	$(addprefix configure-,$(UNIX_PLATFORMS) windows) \
	$(addprefix build-,$(UNIX_PLATFORMS) windows) \
	$(addprefix flutter-build-,$(UNIX_PLATFORMS) windows) \
	android-dev-key clean clean-app clean-native

help:
	@echo "build-<platform>      configure APP and build its flavor (linux android macos ios windows)"
	@echo "configure-<platform>  configure APP only"
	@echo "check-reqs            check the tools the build needs"
	@echo "clean-app             remove build/ and Pods; keep native-asset outputs"
	@echo "clean-native          remove native-asset outputs"
	@echo "clean                 both of the above"
	@echo
	@echo "Variables:            APP=$(APP) VERSION=$(VERSION) BUILD_NUM=$(BUILD_NUM)"
	@echo "                      PREBUILTS=$(PREBUILTS) OVERWRITE=$(OVERWRITE)"

check-reqs:
	@for tool in flutter dart rustup cargo go cmake meson ninja protoc; do \
		command -v $$tool >/dev/null 2>&1 || { echo >&2 "$$tool not found"; exit 1; }; \
	done
	@echo "Requirements found."

# --- Configuration ---

# Writes the brand's generated files, resolves packages, and generates icons
# and splash screens: everything scripts/build_app.sh did before a build.
$(addprefix configure-,$(UNIX_PLATFORMS) windows): configure-%:
	@[ -n "$(VERSION)" ] && [ -n "$(BUILD_NUM)" ] || \
		{ echo >&2 "Set VERSION and BUILD_NUM"; exit 1; }
	@case " $(BRANDS) " in *" $(APP) "*) ;; \
		*) echo >&2 "APP must be one of: $(BRANDS)"; exit 1;; esac
	bash scripts/prebuild.sh
	$(if $(call ships_mwebd,$*),dart tool/build_standalone_mwebd_windows.dart $(if $(filter 1,$(MWEBD_FETCH)),--fetch))
	dart tool/branding/configure.dart --brand $(APP) --platforms $* \
		--version $(VERSION) --build-number $(BUILD_NUM) --flavor $(APP) --apply \
		$(if $(filter 1,$(PREBUILTS)),--prebuilts) \
		$(if $(filter 1,$(OVERWRITE)),--overwrite) \
		$(if $(call ships_mwebd,$*),--mwebd-sha256 "$$(sha256sum assets/windows/mwebd.exe | cut -d' ' -f1)")
	flutter pub get
	$(if $(filter-out linux,$*),dart run flutter_launcher_icons \
		-f scripts/app_config/platforms/$*/flutter_launcher_icons.yaml)
	$(if $(filter android ios,$*),dart run flutter_native_splash:create \
		--path scripts/app_config/platforms/$*/flutter_native_splash.yaml)

# Only stack_wallet ships mwebd.exe, and only on Windows.
ships_mwebd = $(and $(filter windows,$(1)),$(filter stack_wallet,$(APP)))

# --- Builds ---

$(addprefix build-,$(UNIX_PLATFORMS) windows): build-%: configure-%
	$(MAKE) flutter-build-$*

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
