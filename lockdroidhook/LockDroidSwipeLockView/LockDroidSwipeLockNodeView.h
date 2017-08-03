#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger, LockDroidSwipeLockNodeViewStatus) {
    LockDroidSwipeLockNodeViewStatusNormal,
	LockDroidSwipeLockNodeViewStatusWarning,
	LockDroidSwipeLockNodeViewStatusValid,
    LockDroidSwipeLockNodeViewStatusSelected    
};

@interface LockDroidSwipeLockNodeView : UIView
@property (nonatomic) LockDroidSwipeLockNodeViewStatus nodeViewStatus;

@end
