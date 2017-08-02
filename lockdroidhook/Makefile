include theos/makefiles/common.mk

TWEAK_NAME = lockdroid
lockdroid_FILES = /mnt/d/codes/lockdroid/lockdroidhook/Tweak.xm
lockdroid_FRAMEWORKS = CydiaSubstrate Foundation UIKit CoreGraphics QuartzCore
lockdroid_LIBRARIES = MobileGestalt
lockdroid_CFLAGS = -fobjc-arc
lockdroid_LDFLAGS = -Wl,-segalign,4000

lockdroid_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
