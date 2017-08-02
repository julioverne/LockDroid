include theos/makefiles/common.mk

SUBPROJECTS += lockdroidhook
SUBPROJECTS += lockdroidsettings

include $(THEOS_MAKE_PATH)/aggregate.mk

all::
	
