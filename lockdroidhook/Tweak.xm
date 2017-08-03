#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>
#import <CommonCrypto/CommonCrypto.h>

#define NSLog(...)


#import  "./LockDroidSwipeLockView/LockDroidSwipeLockNodeView.h"
#include "./LockDroidSwipeLockView/LockDroidSwipeLockNodeView.m"
#import  "./LockDroidSwipeLockView/LockDroidSwipeLockView.h"
#include "./LockDroidSwipeLockView/LockDroidSwipeLockView.m"


#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.lockdroid.plist"

static BOOL Enabled;
static BOOL DrawRecognizeFast;
static BOOL AttemptEnabled;
static int leftTryAttenps;
static NSString* passwordSt;
static NSString* passwordDrawSt;

@implementation NSData (AES)
- (NSData *)AES128:(BOOL)encrypt key:(NSString *)key iv:(NSString *)iv
{
	CCOperation operation = encrypt?kCCEncrypt:kCCDecrypt;
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    if (iv) {
		[iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    }
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
					  kCCAlgorithmAES128,
					  kCCOptionPKCS7Padding | kCCOptionECBMode,
					  keyPtr,
					  kCCBlockSizeAES128,
					  ivPtr,
					  [self bytes],
					  dataLength,
					  buffer,
					  bufferSize,
					  &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
	return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}
@end

static NSString* keyAES()
{
	return @"\x01\x00\x01\x04\x00\x06\x04";
}


static void settingsChangedLockDroid(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{	
	@autoreleasepool {		
		NSDictionary *WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] copy];
		Enabled = (BOOL)[[WidPlayerPrefs objectForKey:@"Enabled"]?:@YES boolValue];
		DrawRecognizeFast = (BOOL)[[WidPlayerPrefs objectForKey:@"DrawRecognizeFast"]?:@YES boolValue];
		
		AttemptEnabled = (BOOL)[[WidPlayerPrefs objectForKey:@"AttemptEnabled"]?:@YES boolValue];
		leftTryAttenps = (int)[[WidPlayerPrefs objectForKey:@"leftTryAttenps"]?:@(3) intValue];
		
		NSString* newPasswordSt = nil;
		NSString* newPasswordDrawSt = nil;
		
		if(NSData* encriptedPass = WidPlayerPrefs[@"Password"]) {
			NSData* dataPass = [encriptedPass AES128:NO key:keyAES() iv:nil];
			newPasswordSt = [[NSString alloc] initWithData:dataPass encoding:NSUTF8StringEncoding];
		}
		if(NSData* encriptedPassDraw = WidPlayerPrefs[@"PasswordDraw"]) {
			NSData* dataPass = [encriptedPassDraw AES128:NO key:keyAES() iv:nil];
			newPasswordDrawSt = [[NSString alloc] initWithData:dataPass encoding:NSUTF8StringEncoding];
		}
		passwordSt = newPasswordSt;
		passwordDrawSt = newPasswordDrawSt;
	}
}

static void changeSettingsAndSave(NSString* key, id value, BOOL remove)
{
	@autoreleasepool {
		NSMutableDictionary *WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] mutableCopy];
		if(remove) {
			[WidPlayerPrefs removeObjectForKey:key];
		} else if(value) {
			WidPlayerPrefs[key] = value;
		}
		[WidPlayerPrefs writeToFile:@PLIST_PATH_Settings atomically:YES];
		notify_post("com.julioverne.lockdroid/Settings");
	}
}



@interface DrawLockDroidController : UIViewController 
@property (nonatomic) LockDroidSwipeLockView *lockView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) NSString *passwordString;
@end

@implementation DrawLockDroidController
@synthesize lockView, titleLabel, passwordString;
- (void)leftBarButton:(BOOL)hidden
{
	UIBarButtonItem *noButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset Pattern" style:UIBarButtonItemStylePlain target:self action:@selector(reset)];
	((UIViewController*)self).navigationItem.rightBarButtonItems = hidden?@[]:@[noButtonItem];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
    
	self.title = @"Draw New Password";
	
    self.titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Draw Your New Pattern";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.frame = CGRectMake(0, 70, self.view.bounds.size.width, 20);
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.view addSubview:titleLabel];
    
    CGFloat viewWidth = self.view.bounds.size.width - 40;
    CGFloat viewHeight = viewWidth;
	
    self.lockView = [[LockDroidSwipeLockView alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - viewHeight - 40 - 100, viewWidth, viewHeight)];
    [self.view addSubview:lockView];
    self.lockView.delegate = (id<LockDroidSwipeLockViewDelegate>)self;
	
	[self leftBarButton:YES];
}
-(LockDroidSwipeLockViewState)swipeView:(LockDroidSwipeLockView *)swipeView didEndSwipeWithPassword:(NSString *)password
{
	if(password&&password.length>0) {
		if (self.passwordString == nil) {
			self.passwordString = password;
			self.titleLabel.text = @"Confirm Your New Pattern";
		}else if ([self.passwordString isEqualToString:password]){
			self.titleLabel.text = @"Done";
			
			@autoreleasepool {
				NSData* encriptedPass = [[self.passwordString dataUsingEncoding:NSUTF8StringEncoding] AES128:YES key:keyAES() iv:nil];
				changeSettingsAndSave(@"PasswordDraw", encriptedPass, NO);
			}
			self.passwordString = nil;
			[self performSelector:@selector(dismiss) withObject:nil afterDelay:0.5f];
			return LockDroidSwipeLockViewStateSelected;
		} else {
			self.titleLabel.text = @"Wrong Draw Pattern";
			[self leftBarButton:NO];
			return LockDroidSwipeLockViewStateWarning;
		}
	}
    return LockDroidSwipeLockViewStateNormal;
}
- (void)dismiss
{
	[self.navigationController popViewControllerAnimated:YES];
}
- (void)reset
{
    self.passwordString = nil;
    self.titleLabel.text = @"Draw Your New Pattern";
    [self leftBarButton:YES];
}
@end






@interface SBLockScreenManager : NSObject
@property(readonly) BOOL isUILocked;
+ (id)sharedInstance;
- (BOOL)attemptUnlockWithPasscode:(id)arg1;
@end
@interface SBUIPasscodeLockViewSimpleFixedDigitKeypad : UIView
- (void)_resetForFailedPasscode:(BOOL)arg1;
- (void)updateStatusText:(id)arg1 subtitle:(id)arg2 animated:(bool)arg3;
- (void)passcodeLockNumberPad:(id)arg1 keyDown:(id)arg2;
@end
@interface SBUIPasscodeLockNumberPad : UIView
@property (nonatomic, readonly) NSArray *buttons;
@property (nonatomic) SBUIPasscodeLockViewSimpleFixedDigitKeypad *delegate;

@property (nonatomic, retain) LockDroidSwipeLockView* lockdroidView;
@property (assign) int lockdroidLeftTry;
- (void)lockdroidPasswordMessage:(BOOL)arg1;
@end

static LockDroidSwipeLockView* lockdroidViewInstance;

%hook SBUIPasscodeLockNumberPad

%property (nonatomic, retain) id lockdroidView;
%property (assign) int lockdroidLeftTry;

- (void)layoutSubviews
{
	%orig;
	
	UIView* _numberPad = MSHookIvar<UIView *>(self, "_numberPad");
	UIView* _bottomPaddingView = MSHookIvar<UIView *>(self, "_bottomPaddingView");
	
	if(!self.lockdroidView && _numberPad && _bottomPaddingView) {
		if(!lockdroidViewInstance) {
			lockdroidViewInstance = [[LockDroidSwipeLockView alloc] initWithFrame:_numberPad.frame];
			lockdroidViewInstance.tag = 4652;
		}
		self.lockdroidLeftTry = 0;
		self.lockdroidView = lockdroidViewInstance;
		[self.lockdroidView cleanNodesIfNeeded];
	}
	
	if(self.lockdroidView) {
		
		if(UIView* tabVi = [self viewWithTag:self.lockdroidView.tag]) {
			[tabVi removeFromSuperview];
		} else {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0001f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				if(self.delegate&&Enabled) {
					[self.delegate updateStatusText:@"Draw Your Password" subtitle:@"" animated:NO];
					if(!passwordSt || !passwordDrawSt) {
						[self lockdroidPasswordMessage:!passwordDrawSt?NO:!passwordSt?YES:NO];
					}
				}
			});
		}
		
		BOOL isValid = Enabled && (self.lockdroidLeftTry<(leftTryAttenps+1)) && passwordSt && passwordDrawSt;
		
		if(_numberPad) {
			_numberPad.alpha = isValid?0:1;
		}
		if(isValid) {
			[self addSubview:self.lockdroidView];
		}
		
		if(_bottomPaddingView && _numberPad) {
			if(isValid) {
				if(_numberPad.frame.size.height > _bottomPaddingView.frame.size.height) {
					_bottomPaddingView.frame = CGRectMake(_bottomPaddingView.frame.origin.x, _bottomPaddingView.frame.origin.y - _numberPad.frame.size.height, _bottomPaddingView.frame.size.width, _bottomPaddingView.frame.size.height + _numberPad.frame.size.height);
				}
			} else {
				if(_numberPad.frame.size.height < _bottomPaddingView.frame.size.height) {
					_bottomPaddingView.frame = CGRectMake(_bottomPaddingView.frame.origin.x, _bottomPaddingView.frame.origin.y + _numberPad.frame.size.height, _bottomPaddingView.frame.size.width, _bottomPaddingView.frame.size.height - _numberPad.frame.size.height);
				}
			}
		}
		
		self.lockdroidView.delegate = (id<LockDroidSwipeLockViewDelegate>)self;
	}
}

%new
- (void)lockdroidPasswordMessage:(BOOL)isForPassword
{
	if(self.delegate&&Enabled) {
		[self.delegate updateStatusText:@"LockDroid, Please." subtitle:isForPassword?@"Please, Unlock Device With Your Passcode First Time.":@"Please, Draw Your Pattern From LockDroid Settings." animated:YES];
		[self.delegate _resetForFailedPasscode:YES];
	}
}

%new
-(LockDroidSwipeLockViewState)swipeView:(LockDroidSwipeLockView *)swipeView didEndSwipeWithPassword:(NSString *)password
{
	if(password && password.length > 0) {
		if(passwordDrawSt && [passwordDrawSt isEqualToString:password] && [[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
			[[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:passwordSt];
			[swipeView performSelector:@selector(cleanNodes) withObject:nil afterDelay:1];
			if([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
				changeSettingsAndSave(@"Password", nil, YES);
				[self layoutSubviews];
			}
		}
		
		[self layoutSubviews];
		
		if([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
			if(self.delegate) {
				[self.delegate updateStatusText:@"Incorrect Draw Password" subtitle:AttemptEnabled?self.lockdroidLeftTry==leftTryAttenps?@"Input Password.":[NSString stringWithFormat:@"%@ Attempt Left.", @(leftTryAttenps - self.lockdroidLeftTry)]:@"" animated:YES];
				if(AttemptEnabled) {
					self.lockdroidLeftTry++;
				}
				[self.delegate _resetForFailedPasscode:YES];
			}
			return LockDroidSwipeLockViewStateWarning;
		}
	}
	return LockDroidSwipeLockViewStateNormal;
}

%new
-(void)swipeView:(LockDroidSwipeLockView *)swipeView didChangeSwipeWithPassword:(NSString *)password
{
	if(self.delegate) {
		[self.delegate passcodeLockNumberPad:self keyDown:self.buttons[2]];
	}
	if(DrawRecognizeFast && passwordDrawSt && [passwordDrawSt isEqualToString:password]) {
		[swipeView performSelector:@selector(makeNodesToValid)];
		[[%c(SBLockScreenManager) sharedInstance] performSelector:@selector(attemptUnlockWithPasscode:) withObject:passwordSt afterDelay:0.1f];
		[swipeView performSelector:@selector(cleanNodes) withObject:nil afterDelay:1];
	}
}
%end

%hook SBLockScreenManager
- (BOOL)attemptUnlockWithPasscode:(NSString*)arg1
{
    BOOL result = %orig;
	if(!passwordSt&&![self isUILocked]&&(arg1&&arg1.length>0)) {
		@autoreleasepool {
			NSData* encriptedPass = [[arg1 dataUsingEncoding:NSUTF8StringEncoding] AES128:YES key:keyAES() iv:nil];
			changeSettingsAndSave(@"Password", encriptedPass, NO);
		}
	}
	return result;
}
%end



%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChangedLockDroid, CFSTR("com.julioverne.lockdroid/Settings"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	settingsChangedLockDroid(NULL, NULL, NULL, NULL, NULL);
}

