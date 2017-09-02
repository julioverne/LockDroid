#import <UIKit/UIKit.h>

extern UIColor* selectionColor;
extern UIColor* warningColor;
extern UIColor* validColor;
extern UIColor* dotNormalColor;
extern UIColor* dotFillColor;
extern BOOL useImage;
extern NSString* imagePath;
extern int matrix;

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