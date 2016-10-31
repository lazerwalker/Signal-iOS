# Make sure we're failing even though we pipe to xcpretty
SHELL=/bin/bash -o pipefail -o errexit

DEVICE_TARGET_PATTERN ?= iPhone 6 (10.0) \[.*\]
export DEVICE_TARGET_PATTERN
DEVICE_UUID:=$(shell xcrun instruments -s | grep -o "${DEVICE_TARGET_PATTERN}" | grep -o "\[.*\]" | sed "s/^\[\(.*\)\]$$/\1/")
BUILD_DESTINATION = platform=iOS Simulator,id=${DEVICE_UUID}
WORKING_DIR = ./
SCHEME = Signal
XCODE_BUILD = xcrun xcodebuild -workspace $(SCHEME).xcworkspace -scheme $(SCHEME) -sdk iphonesimulator

.PHONY: build test retest clean

default: test

ci: print_env build_dependencies test

build_dependencies:
	cd $(WORKING_DIR) && \
		git submodule update --init
		pod install
		carthage build --platform iOS

build: build_dependencies
	cd $(WORKING_DIR) && \
		$(XCODE_BUILD) build | xcpretty

test: optional_early_start_simulator
	cd $(WORKING_DIR) && \
		$(XCODE_BUILD) \
			-destination '${BUILD_DESTINATION}' \
			test | xcpretty

clean:
	cd $(WORKING_DIR) && \
		$(XCODE_BUILD) \
			clean | xcpretty

optional_early_start_simulator:
ifdef EARLY_START_SIMULATOR
		echo "Waiting for simulator to start to help with testing timeouts" &&\
		xcrun instruments -w '${DEVICE_UUID}' || true # xcrun can return irrelevant non-zeroes.
else
		echo "Not waiting for simulator."
endif

print_env:
	echo "$(DEVICE_TARGET_PATTERN)" && \
	echo "$(DEVICE_UUID)"
