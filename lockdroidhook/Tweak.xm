#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>
#import <CommonCrypto/CommonCrypto.h>

#define NSLog(...)


#import  "./YLSwipeLockView/YLSwipeLockNodeView.h"
#include "./YLSwipeLockView/YLSwipeLockNodeView.m"
#import  "./YLSwipeLockView/YLSwipeLockView.h"
#include "./YLSwipeLockView/YLSwipeLockView.m"


#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.lockdroid.plist"

static BOOL Enabled;
static BOOL DrawRecognizeFast;
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
@property (nonatomic) YLSwipeLockView *lockView;
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
	
    self.lockView = [[YLSwipeLockView alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - viewHeight - 40 - 100, viewWidth, viewHeight)];
    [self.view addSubview:lockView];
    self.lockView.delegate = (id<YLSwipeLockViewDelegate>)self;
	
	[self leftBarButton:YES];
}

-(YLSwipeLockViewState)swipeView:(YLSwipeLockView *)swipeView didEndSwipeWithPassword:(NSString *)password
{
    if (self.passwordString == nil) {
        self.passwordString = password;
        self.titleLabel.text = @"Confirm Your New Pattern";
        return YLSwipeLockViewStateNormal;
    }else if ([self.passwordString isEqualToString:password]){
        self.titleLabel.text = @"Done";
		
        @autoreleasepool {
			NSData* encriptedPass = [[self.passwordString dataUsingEncoding:NSUTF8StringEncoding] AES128:YES key:keyAES() iv:nil];
			changeSettingsAndSave(@"PasswordDraw", encriptedPass, NO);
		}
		
        self.passwordString = nil;
		
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
        return YLSwipeLockViewStateSelected;
    }else{
        self.titleLabel.text = @"Wrong Draw Pattern";
        [self leftBarButton:NO];
        return YLSwipeLockViewStateWarning;
    }
    
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

@property (nonatomic, retain) YLSwipeLockView* lockdroidView;
@property (nonatomic, retain) UIView* lockdroidBGView;
@property (assign) int lockdroidLeftTry;
- (void)lockdroidPasswordMessage:(BOOL)arg1;
@end



%hook SBUIPasscodeLockNumberPad

%property (nonatomic, retain) id lockdroidView;
%property (nonatomic, retain) id lockdroidBGView;
%property (assign) int lockdroidLeftTry;

- (void)layoutSubviews
{
	%orig;
	
	UIView* _numberPad = MSHookIvar<UIView *>(self, "_numberPad");
	UIView* _bottomPaddingView = MSHookIvar<UIView *>(self, "_bottomPaddingView");
	
	if((!self.lockdroidView || !self.lockdroidBGView) && _numberPad && _bottomPaddingView) {
		self.lockdroidView = [[YLSwipeLockView alloc] initWithFrame:_numberPad.frame];
		self.lockdroidView.tag = 4652;
		self.lockdroidBGView = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:_bottomPaddingView]];
		self.lockdroidBGView.frame = self.lockdroidView.frame;
		self.lockdroidBGView.tag = 4653;
	}
	
	if(self.lockdroidView && self.lockdroidBGView) {
		
		if(UIView* tabVi = [self viewWithTag:self.lockdroidView.tag]) {
			[tabVi removeFromSuperview];
		} else {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				if(self.delegate&&Enabled) {
					[self.delegate updateStatusText:@"Draw Your Password" subtitle:@"" animated:YES];
					if(!passwordSt || !passwordDrawSt) {
						[self lockdroidPasswordMessage:!passwordDrawSt?NO:!passwordSt?YES:NO];
					}
				}
			});
		}
		if(UIView* tabVi = [self viewWithTag:self.lockdroidBGView.tag]) {
			[tabVi removeFromSuperview];
		}
		
		BOOL isValid = Enabled && self.lockdroidLeftTry<4 && passwordSt && passwordDrawSt;
		
		if(_numberPad) {
			_numberPad.alpha = isValid?0:1;
		}
		if(isValid) {
			[self addSubview:self.lockdroidBGView];
			[self addSubview:self.lockdroidView];
		}
		
		self.lockdroidView.delegate = (id<YLSwipeLockViewDelegate>)self;
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
-(YLSwipeLockViewState)swipeView:(YLSwipeLockView *)swipeView didEndSwipeWithPassword:(NSString *)password
{
	if(password && password.length > 0) {
		if(passwordDrawSt && [passwordDrawSt isEqualToString:password]) {
			[[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:passwordSt];
			if([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
				changeSettingsAndSave(@"Password", nil, YES);
			}
		}
		
		[self layoutSubviews];
		
		if([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
			if(self.delegate) {
				[self.delegate updateStatusText:@"Incorrect Draw Password" subtitle:self.lockdroidLeftTry==3?@"Input Password.":[NSString stringWithFormat:@"%@ Attempt Left.", @(3 - self.lockdroidLeftTry)] animated:YES];
				self.lockdroidLeftTry++;
				[self.delegate _resetForFailedPasscode:YES];
			}
			return YLSwipeLockViewStateWarning;
		}
	}
	return YLSwipeLockViewStateNormal;
}

%new
-(void)swipeView:(YLSwipeLockView *)swipeView didChangeSwipeWithPassword:(NSString *)password
{
	if(self.delegate) {
		[self.delegate passcodeLockNumberPad:self keyDown:self.buttons[2]];
	}
	if(DrawRecognizeFast && passwordDrawSt && [passwordDrawSt isEqualToString:password]) {
		[[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:passwordSt];
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

