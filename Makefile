TARGET := iphone:clang:latest:15.4
THEOS_DEVICE_IP = 192.168.1.119

INSTALL_TARGET_PROCESSES = TikTok


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChronoKit

ChronoKit_FILES = $(shell find Sources/ChronoKit -name '*.swift') $(shell find deps/SQLite.swift/Sources/SQLite -name '*.swift') $(shell find Sources/ChronoKitC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp' -o -name '*.x')
ChronoKit_SWIFT_OBJC_BRIDGING_HEADER = Sources/ChronoKitC/include/ChronoKit-Bridging-Header.h
ChronoKit_CFLAGS = -fobjc-arc -ISources/ChronoKitC/include

include $(THEOS_MAKE_PATH)/tweak.mk
