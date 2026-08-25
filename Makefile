TARGET := iphone:clang:latest:15.4
THEOS_DEVICE_IP = 192.168.1.119
THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChronoKit

before-all::
	@echo "public let ChronoKitVersion = \"$(shell awk '/^Version:/ {print $$2}' control)\"" > Sources/ChronoKit/Version.swift

ChronoKit_FILES = $(shell find Sources/ChronoKit -name '*.swift') $(shell find deps/SQLite.swift/Sources/SQLite -name '*.swift') $(shell find Sources/ChronoKitC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp' -o -name '*.x')
ChronoKit_CFLAGS = -fobjc-arc -ISources/ChronoKitC/include

ifeq ($(DEBUG), 1)
	ChronoKit_CFLAGS += -DDEBUG=1
	ChronoKit_SWIFTFLAGS += -DDEBUG
endif

include $(THEOS_MAKE_PATH)/tweak.mk
