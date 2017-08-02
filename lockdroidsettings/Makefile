include theos/makefiles/common.mk

BUNDLE_NAME = LockDroid
LockDroid_FILES = /mnt/d/codes/lockdroid/lockdroidsettings/LockDroidController.mm
LockDroid_INSTALL_PATH = /Library/PreferenceBundles
LockDroid_FRAMEWORKS = UIKit QuartzCore CoreGraphics MessageUI Social Twitter Foundation
LockDroid_PRIVATE_FRAMEWORKS = Preferences
LockDroid_LIBRARIES = MobileGestalt
LockDroid_CFLAGS = -fobjc-arc
LockDroid_LDFLAGS = -Wl,-segalign,4000
LockDroid_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/bundle.mk

all::
	