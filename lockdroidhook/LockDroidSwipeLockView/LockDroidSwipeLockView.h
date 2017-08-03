#import <UIKit/UIKit.h>
#define LIGHTBLUE [UIColor colorWithRed:0 green:170/255.0 blue:1 alpha:1]

typedef NS_ENUM(NSUInteger, LockDroidSwipeLockViewState) {
    LockDroidSwipeLockViewStateNormal,
    LockDroidSwipeLockViewStateWarning,
	LockDroidSwipeLockViewStateValid,
    LockDroidSwipeLockViewStateSelected
};
@protocol LockDroidSwipeLockViewDelegate;

@interface LockDroidSwipeLockView : UIView
@property (nonatomic, unsafe_unretained) id<LockDroidSwipeLockViewDelegate> delegate;
@end


@protocol LockDroidSwipeLockViewDelegate<NSObject>
@optional
-(LockDroidSwipeLockViewState)swipeView:(LockDroidSwipeLockView *)swipeView didEndSwipeWithPassword:(NSString *)password;
-(void)swipeView:(LockDroidSwipeLockView *)swipeView didChangeSwipeWithPassword:(NSString *)password;
@end