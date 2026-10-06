.PHONY: build dist android

CONFIG ?= Release
HOST_ARCH ?= $(shell uname -m)
DESTINATIONS ?= generic/platform=iOS generic/platform=iOS\ Simulator platform=macOS,arch=arm64 platform=macOS,arch=x86_64
DERIVED_DATA ?= $(CURDIR)/.xcodebuild
WORKSPACE ?= apple/.swiftpm/xcode/package.xcworkspace
MODULE_NAMES ?= GodotGoogleSignIn
RUNTIME_RPATH ?= @loader_path/../../../../../GodotApplePluginsRuntime/bin
RUNTIME_FRAMEWORK_RPATH ?= @loader_path/../../../GodotApplePluginsRuntime/bin
RUNTIME_FRAMEWORK ?= SwiftGodotRuntime
RUNTIME_LOAD_DYLIB ?= @rpath/$(RUNTIME_FRAMEWORK).framework/Versions/A/$(RUNTIME_FRAMEWORK)
XCODEBUILD ?= xcodebuild
XCODEBUILD_FLAGS ?= -skipPackagePluginValidation -skipMacroValidation
XCODEBUILD_SETTINGS ?= CODE_SIGNING_ALLOWED=NO OTHER_LDFLAGS="-Xlinker -headerpad_max_install_names"
XCODEBUILD_LOG_ON_ERROR ?=
XCODEBUILD_LOG_DIR ?=
XCODEBUILD_HEARTBEAT_SECONDS ?= 60
CODESIGN_IDENTITY ?= Apple Distribution: ZT Pawer LLC (X2Y33T5ZLR)

ANDROID_NDK_VERSION ?= 28.0.12674087
ANDROID_MODULE_NAME ?= GodotGoogleSignIn

build:
	set -e; \
	run_xcodebuild() { \
		if [ -n "$(XCODEBUILD_LOG_ON_ERROR)" ]; then \
			log_dir="$(XCODEBUILD_LOG_DIR)"; \
			if [ -n "$$log_dir" ]; then mkdir -p "$$log_dir"; fi; \
			log_file=$$(mktemp "$${log_dir:-$${TMPDIR:-/tmp}}/xcodebuild.XXXXXX"); \
			echo "Capturing xcodebuild output to $$log_file"; \
			"$$@" >"$$log_file" 2>&1 & \
			xcodebuild_pid=$$!; \
			( \
				while kill -0 "$$xcodebuild_pid" 2>/dev/null; do \
					sleep "$(XCODEBUILD_HEARTBEAT_SECONDS)"; \
					if kill -0 "$$xcodebuild_pid" 2>/dev/null; then \
						echo "xcodebuild still running (pid $$xcodebuild_pid): $$*"; \
					fi; \
				done \
			) & \
			heartbeat_pid=$$!; \
			if wait "$$xcodebuild_pid"; then status=0; else status=$$?; fi; \
			kill "$$heartbeat_pid" 2>/dev/null || true; \
			wait "$$heartbeat_pid" 2>/dev/null || true; \
			if [ "$$status" -ne 0 ]; then \
				echo "xcodebuild failed; dumping $$log_file"; \
				cat "$$log_file"; \
				return "$$status"; \
			fi; \
			rm -f "$$log_file"; \
		else \
			"$$@"; \
		fi; \
	}; \
	swift build --package-path apple; \
	for dest in $(DESTINATIONS); do \
		platform_name=`echo "$$dest" | sed -n 's/.*platform=\([^,]*\).*/\1/p'`; \
		if [ -z "$$platform_name" ]; then platform_name="iOS"; fi; \
		platform_lc=`echo "$$platform_name" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'`; \
		arch_name=`echo "$$dest" | sed -n 's/.*arch=\([a-zA-Z0-9_]*\).*/\1/p'`; \
		suffix=""; \
		if [ "$$platform_lc" = "iossimulator" ]; then suffix="simulator"; fi; \
		if [ "$$platform_lc" = "macos" ]; then suffix="$$arch_name"; fi; \
		for module in $(MODULE_NAMES); do \
			echo "Building $$module for $$dest"; \
			extra_settings=""; \
			if [ "$$platform_lc" = "macos" ] && [ "$$arch_name" = "x86_64" ]; then \
				extra_settings="ARCHS=x86_64 VALID_ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO"; \
			fi; \
			run_xcodebuild $(XCODEBUILD) \
				$(XCODEBUILD_FLAGS) \
				-workspace '$(WORKSPACE)' \
				-scheme "$$module" \
				-configuration '$(CONFIG)' \
				-destination "$$dest" \
				-derivedDataPath "$(DERIVED_DATA)$$suffix" \
				$(XCODEBUILD_SETTINGS) $$extra_settings \
				build; \
			echo "Built $$module for $$dest"; \
		done; \
	done

dist:
	set -e; \
	has_rpath() { \
		binary="$$1"; rpath="$$2"; \
		otool -l "$$binary" | grep -Fq "path $$rpath "; \
	}; \
	set_runtime_rpath() { \
		binary="$$1"; \
		old_rpath="$$2"; \
		new_rpath="$(RUNTIME_RPATH)"; \
		framework_rpath="$(RUNTIME_FRAMEWORK_RPATH)"; \
		if ! has_rpath "$$binary" "$$new_rpath"; then \
			if has_rpath "$$binary" "$$old_rpath"; then \
				install_name_tool -rpath "$$old_rpath" "$$new_rpath" "$$binary"; \
			else \
				install_name_tool -add_rpath "$$new_rpath" "$$binary"; \
			fi; \
		fi; \
		if ! has_rpath "$$binary" "$$framework_rpath"; then \
			install_name_tool -add_rpath "$$framework_rpath" "$$binary"; \
		fi; \
		if [ "$$old_rpath" != "$$new_rpath" ] && [ "$$old_rpath" != "$$framework_rpath" ] && has_rpath "$$binary" "$$old_rpath"; then \
			install_name_tool -delete_rpath "$$old_rpath" "$$binary"; \
		fi; \
	}; \
	copy_dependency_bundles() { \
		products_dir="$$1"; \
		dest_dir="$$2"; \
		for bundle in "$$products_dir"/*.bundle; do \
			if [ -d "$$bundle" ]; then rsync -a "$$bundle" "$$dest_dir/"; fi; \
		done; \
	}; \
	for module in $(MODULE_NAMES); do \
		addon="$(CURDIR)/addons/$$module/bin"; \
		mkdir -p "$$addon"; \
		rm -rf "$$addon/$${module}.xcframework" "$$addon/$${module}.framework" "$$addon/$${module}_x64.framework"; \
		ios_device_root="$(DERIVED_DATA)/Build/Products/$(CONFIG)-iphoneos"; \
		ios_sim_root="$(DERIVED_DATA)simulator/Build/Products/$(CONFIG)-iphonesimulator"; \
		ios_device="$$ios_device_root/PackageFrameworks/$${module}.framework"; \
		ios_sim="$$ios_sim_root/PackageFrameworks/$${module}.framework"; \
		if [ -d "$$ios_device" ] && [ -d "$$ios_sim" ]; then \
			copy_dependency_bundles "$$ios_device_root" "$$ios_device"; \
			copy_dependency_bundles "$$ios_sim_root" "$$ios_sim"; \
			$(XCODEBUILD) -create-xcframework \
				-framework "$$ios_device" \
				-framework "$$ios_sim" \
				-output "$$addon/$${module}.xcframework"; \
			for fw in "$$addon/$${module}.xcframework"/*/*.framework; do \
				codesign --timestamp -f -s "$(CODESIGN_IDENTITY)" "$$fw"; \
			done; \
			codesign --timestamp -f -s "$(CODESIGN_IDENTITY)" "$$addon/$${module}.xcframework"; \
		else \
			echo "Missing iOS build products for $$module, skipping xcframework" >&2; \
		fi; \
		macos_arm64_root="$(DERIVED_DATA)arm64/Build/Products/$(CONFIG)"; \
		macos_arm64="$$macos_arm64_root/PackageFrameworks/$${module}.framework"; \
		if [ -d "$$macos_arm64" ]; then \
			rsync -a "$$macos_arm64/" "$$addon/$${module}.framework"; \
			mkdir -p "$$addon/$${module}.framework/Versions/A/Resources"; \
			copy_dependency_bundles "$$macos_arm64_root" "$$addon/$${module}.framework/Versions/A/Resources"; \
			binary="$$addon/$${module}.framework/Versions/A/$${module}"; \
			if [ -f "$$binary" ]; then \
				old_rpath="$$macos_arm64_root/PackageFrameworks"; \
				set_runtime_rpath "$$binary" "$$old_rpath"; \
			fi; \
		fi; \
		macos_x64_root="$(DERIVED_DATA)x86_64/Build/Products/$(CONFIG)"; \
		macos_x64="$$macos_x64_root/PackageFrameworks/$${module}.framework"; \
		if [ -d "$$macos_x64" ]; then \
			rsync -a "$$macos_x64/" "$$addon/$${module}_x64.framework"; \
			mkdir -p "$$addon/$${module}_x64.framework/Versions/A/Resources"; \
			copy_dependency_bundles "$$macos_x64_root" "$$addon/$${module}_x64.framework/Versions/A/Resources"; \
			binary="$$addon/$${module}_x64.framework/Versions/A/$${module}"; \
			if [ -f "$$binary" ]; then \
				old_rpath="$$macos_x64_root/PackageFrameworks"; \
				set_runtime_rpath "$$binary" "$$old_rpath"; \
			fi; \
		fi; \
	done

android:
	set -e; \
	for target in template_debug template_release; do \
		( cd godot-cpp && scons platform=android target=$$target arch=arm64 \
			ndk_version=$(ANDROID_NDK_VERSION) -j$$(sysctl -n hw.ncpu 2>/dev/null || nproc) ); \
	done; \
	( cd android && ./gradlew assembleDebug assembleRelease copyToDemoAddons ); \
	addon="$(CURDIR)/addons/$(ANDROID_MODULE_NAME)/bin/android"; \
	mkdir -p "$$addon/debug/arm64-v8a" "$$addon/release/arm64-v8a"; \
	cp "android/build/outputs/aar/$(ANDROID_MODULE_NAME)-debug.aar" "$$addon/debug/"; \
	cp "android/build/outputs/aar/$(ANDROID_MODULE_NAME)-release.aar" "$$addon/release/"; \
	cp "android/build/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib/arm64-v8a/lib$(ANDROID_MODULE_NAME).so" "$$addon/debug/arm64-v8a/"; \
	cp "android/build/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/lib$(ANDROID_MODULE_NAME).so" "$$addon/release/arm64-v8a/"
