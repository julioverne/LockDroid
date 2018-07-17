#import <Social/Social.h>
#import <prefs.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>
#import <CommonCrypto/CommonCrypto.h>

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.lockdroid.plist"

#define NSLog(...)



@interface LockDroidController : PSListController {
	UILabel* _label;
	UILabel* underLabel;
}
- (void)HeaderCell;
@end

@implementation LockDroidController
- (id)specifiers {
	if (!_specifiers) {
		NSMutableArray* specifiers = [NSMutableArray array];
		PSSpecifier* spec;
		
		spec = [PSSpecifier emptyGroupSpecifier];
		[spec setProperty:@"Requires Device Passcode Enabled." forKey:@"footerText"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                  target:self
											         set:@selector(setPreferenceValue:specifier:)
											         get:@selector(readPreferenceValue:)
                                                  detail:Nil
											        cell:PSSwitchCell
											        edit:Nil];
		[spec setProperty:@"Enabled" forKey:@"key"];
		[spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
		
		
		
		BOOL needDrawPass;
		@autoreleasepool {
			NSDictionary *CydiaEnablePrefsCheck = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary];
			needDrawPass = CydiaEnablePrefsCheck[@"PasswordDraw"]?NO:YES;
		}
		spec = [PSSpecifier emptyGroupSpecifier];
		if(needDrawPass) {
			[spec setProperty:@"⚠ Requires Draw Pattern. ⚠" forKey:@"footerText"];
		}
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:[needDrawPass?@"⚠ ":@"" stringByAppendingString:@"Draw New Password"]
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(openDraw);
        [specifiers addObject:spec];
		
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Matrix Size"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Matrix Size" forKey:@"label"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Matrix Size"
											  target:self
												 set:@selector(setPreferenceValue:specifier:)
												 get:@selector(readPreferenceValue:)
											  detail:Nil
												cell:PSSegmentCell
												edit:Nil];
		[spec setValues:@[@(3), @(4), @(5),] titles:@[@"3x3", @"4x4", @"5x5",]];
		[spec setProperty:@(3) forKey:@"default"];
		[spec setProperty:@"matrix" forKey:@"key"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Fast Recognise Draw"
                                                  target:self
											         set:@selector(setPreferenceValue:specifier:)
											         get:@selector(readPreferenceValue:)
                                                  detail:Nil
											        cell:PSSwitchCell
											        edit:Nil];
		[spec setProperty:@"DrawRecognizeFast" forKey:@"key"];
		[spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Attempt Error"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Attempt" forKey:@"label"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                  target:self
											         set:@selector(setPreferenceValue:specifier:)
											         get:@selector(readPreferenceValue:)
                                                  detail:Nil
											        cell:PSSwitchCell
											        edit:Nil];
		[spec setProperty:@"AttemptEnabled" forKey:@"key"];
		[spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Limit:"
                                              target:self
											  set:@selector(setPreferenceValue:specifier:)
											  get:@selector(readPreferenceValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"leftTryAttenps" forKey:@"key"];
		[spec setProperty:@"3" forKey:@"default"];
        [specifiers addObject:spec];
		
	spec = [PSSpecifier preferenceSpecifierNamed:@"Theme"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Theme" forKey:@"label"];
    [specifiers addObject:spec];
	spec = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                  target:self
											         set:@selector(setPreferenceValue:specifier:)
											         get:@selector(readPreferenceValue:)
                                                  detail:Nil
											        cell:PSSwitchCell
											        edit:Nil];
		[spec setProperty:@"useImage" forKey:@"key"];
		[spec setProperty:@NO forKey:@"default"];
        [specifiers addObject:spec];
	NSArray* themes = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Application Support/LockDroid" error:nil]?:@[];
	spec = [PSSpecifier preferenceSpecifierNamed:@"Select Theme"
					      target:self
											  set:@selector(setPreferenceValue:specifier:)
											  get:@selector(readPreferenceValue:)
					      detail:PSListItemsController.class
											  cell:PSLinkListCell
											  edit:Nil];
		[spec setProperty:@"imagePath" forKey:@"key"];
		[spec setProperty:@"Default.theme" forKey:@"default"];
		[spec setValues:themes titles:themes];
	[specifiers addObject:spec];
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Color"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Color" forKey:@"label"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Selection"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
		[spec setProperty:NSClassFromString(@"PFSimpleLiteColorCell") forKey:@"cellClass"];
		[spec setProperty:@"Selection" forKey:@"label"];
		[spec setProperty:@YES forKey:@"isContoller"];
		[spec setProperty:@{@"defaults": @"com.julioverne.lockdroid",
				@"key": @"selectionColor",
				@"fallback": @"#00adff",
				@"PostNotification": @"com.julioverne.lockdroid/Settings",
				@"alpha": @YES,} forKey:@"libcolorpicker"];
		spec->action = @selector(cellAction);
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Warning"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
		[spec setProperty:NSClassFromString(@"PFSimpleLiteColorCell") forKey:@"cellClass"];
		[spec setProperty:@"Warning" forKey:@"label"];
		[spec setProperty:@YES forKey:@"isContoller"];
		[spec setProperty:@{@"defaults": @"com.julioverne.lockdroid",
				@"key": @"warningColor",
				@"fallback": @"#ff0000",
				@"PostNotification": @"com.julioverne.lockdroid/Settings",
				@"alpha": @YES,} forKey:@"libcolorpicker"];
		spec->action = @selector(cellAction);
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Valid"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
		[spec setProperty:NSClassFromString(@"PFSimpleLiteColorCell") forKey:@"cellClass"];
		[spec setProperty:@"Valid" forKey:@"label"];
		[spec setProperty:@YES forKey:@"isContoller"];
		[spec setProperty:@{@"defaults": @"com.julioverne.lockdroid",
				@"key": @"validColor",
				@"fallback": @"#00ff00",
				@"PostNotification": @"com.julioverne.lockdroid/Settings",
				@"alpha": @YES,} forKey:@"libcolorpicker"];
		spec->action = @selector(cellAction);
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Dot Normal"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
		[spec setProperty:NSClassFromString(@"PFSimpleLiteColorCell") forKey:@"cellClass"];
		[spec setProperty:@"Dot Normal" forKey:@"label"];
		[spec setProperty:@YES forKey:@"isContoller"];
		[spec setProperty:@{@"defaults": @"com.julioverne.lockdroid",
				@"key": @"dotNormalColor",
				@"fallback": @"#ffffff",
				@"PostNotification": @"com.julioverne.lockdroid/Settings",
				@"alpha": @YES,} forKey:@"libcolorpicker"];
		spec->action = @selector(cellAction);
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Dot Fill"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
		[spec setProperty:NSClassFromString(@"PFSimpleLiteColorCell") forKey:@"cellClass"];
		[spec setProperty:@"Dot Fill" forKey:@"label"];
		[spec setProperty:@YES forKey:@"isContoller"];
		[spec setProperty:@{@"defaults": @"com.julioverne.lockdroid",
				@"key": @"dotFillColor",
				@"fallback": @"#000000:0.200000",
				@"PostNotification": @"com.julioverne.lockdroid/Settings",
				@"alpha": @YES,} forKey:@"libcolorpicker"];
		spec->action = @selector(cellAction);
        [specifiers addObject:spec];
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Localization's"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Localization's" forKey:@"label"];
        [specifiers addObject:spec];
	
	spec = [PSSpecifier preferenceSpecifierNamed:nil
					      target:self
											  set:@selector(setPreferenceValue:specifier:)
											  get:@selector(readPreferenceValue:)
					      detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"drawYourPassword" forKey:@"key"];
		[spec setProperty:@"Draw Your Password" forKey:@"default"];
	[specifiers addObject:spec];
	spec = [PSSpecifier preferenceSpecifierNamed:nil
					      target:self
											  set:@selector(setPreferenceValue:specifier:)
											  get:@selector(readPreferenceValue:)
					      detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"incorrectDrawPassword" forKey:@"key"];
		[spec setProperty:@"Incorrect Draw Password" forKey:@"default"];
	[specifiers addObject:spec];
	spec = [PSSpecifier preferenceSpecifierNamed:nil
					      target:self
											  set:@selector(setPreferenceValue:specifier:)
											  get:@selector(readPreferenceValue:)
					      detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"inputPassword" forKey:@"key"];
		[spec setProperty:@"Input Password." forKey:@"default"];
	[specifiers addObject:spec];
	spec = [PSSpecifier preferenceSpecifierNamed:nil
					      target:self
											  set:@selector(setPreferenceValue:specifier:)
											  get:@selector(readPreferenceValue:)
					      detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"attemptLeft" forKey:@"key"];
		[spec setProperty:@"Attempt Left." forKey:@"default"];
	[specifiers addObject:spec];
		
		spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Reset Settings"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(reset);
        [specifiers addObject:spec];
		
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Developer"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Developer" forKey:@"label"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Follow julioverne"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(twitter);
		[spec setProperty:[NSNumber numberWithBool:TRUE] forKey:@"hasIcon"];
		[spec setProperty:[UIImage imageWithContentsOfFile:[[self bundle] pathForResource:@"twitter" ofType:@"png"]] forKey:@"iconImage"];
        [specifiers addObject:spec];
		spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"LockDroid © 2018 julioverne" forKey:@"footerText"];
        [specifiers addObject:spec];
		_specifiers = [specifiers copy];
	}
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)anin
{
	[super viewWillAppear:anin];
	[self.view endEditing:YES];
	[self reloadSpecifiers];
}

- (void)openDraw
{
	dlopen("/Library/MobileSubstrate/DynamicLibraries/lockdroid.dylib", RTLD_LAZY);
	[self.navigationController pushViewController:[[objc_getClass("DrawLockDroidController") alloc] init] animated:YES];
}

- (void)twitter
{
	UIApplication *app = [UIApplication sharedApplication];
	if ([app canOpenURL:[NSURL URLWithString:@"twitter://user?screen_name=ijulioverne"]]) {
		[app openURL:[NSURL URLWithString:@"twitter://user?screen_name=ijulioverne"]];
	} else if ([app canOpenURL:[NSURL URLWithString:@"tweetbot:///user_profile/ijulioverne"]]) {
		[app openURL:[NSURL URLWithString:@"tweetbot:///user_profile/ijulioverne"]];		
	} else {
		[app openURL:[NSURL URLWithString:@"https://mobile.twitter.com/ijulioverne"]];
	}
}
- (void)love
{
	SLComposeViewController *twitter = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
	[twitter setInitialText:@"#LockDroid by @ijulioverne is cool!"];
	if (twitter != nil) {
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	}
}
- (void)showPrompt
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:@"An Respring is Requerid for this option." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Respring", nil];
	alert.tag = 55;
	[alert show];
}
- (void)reset
{
	[@{} writeToFile:@PLIST_PATH_Settings atomically:YES];	
	[self reloadSpecifiers];
	notify_post("com.julioverne.lockdroid/Settings");
	[self showPrompt];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
	@autoreleasepool {
		NSMutableDictionary *CydiaEnablePrefsCheck = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
		[CydiaEnablePrefsCheck setObject:value forKey:[specifier identifier]];
		if([[specifier identifier] isEqualToString:@"matrix"]) {
			[CydiaEnablePrefsCheck removeObjectForKey:@"PasswordDraw"];
		}
		[CydiaEnablePrefsCheck writeToFile:@PLIST_PATH_Settings atomically:YES];
		notify_post("com.julioverne.lockdroid/Settings");
		if ([[specifier properties] objectForKey:@"PromptRespring"]) {
			[self showPrompt];
		}
		[self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:1];
	}
}
- (id)readPreferenceValue:(PSSpecifier*)specifier
{
	@autoreleasepool {
		NSDictionary *CydiaEnablePrefsCheck = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary];
		return CydiaEnablePrefsCheck[[specifier identifier]]?:[[specifier properties] objectForKey:@"default"];
	}
}
- (void)_returnKeyPressed:(id)arg1
{
	[super _returnKeyPressed:arg1];
	[self.view endEditing:YES];
}

- (void)HeaderCell
{
	@autoreleasepool {
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 100)];
	int width = [[UIScreen mainScreen] bounds].size.width;
	CGRect frame = CGRectMake(0, 20, width, 60);
		CGRect botFrame = CGRectMake(0, 55, width, 60);
 
		_label = [[UILabel alloc] initWithFrame:frame];
		[_label setNumberOfLines:1];
		_label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48];
		[_label setText:@"LockDroid"];
		[_label setBackgroundColor:[UIColor clearColor]];
		_label.textColor = [UIColor blackColor];
		_label.textAlignment = NSTextAlignmentCenter;
		_label.alpha = 0;

		underLabel = [[UILabel alloc] initWithFrame:botFrame];
		[underLabel setNumberOfLines:1];
		underLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
		[underLabel setText:@"Android Lockscreen"];
		[underLabel setBackgroundColor:[UIColor clearColor]];
		underLabel.textColor = [UIColor grayColor];
		underLabel.textAlignment = NSTextAlignmentCenter;
		underLabel.alpha = 0;
		
		[headerView addSubview:_label];
		[headerView addSubview:underLabel];
		
	[_table setTableHeaderView:headerView];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(increaseAlpha)
                                   userInfo:nil
                                    repeats:NO];
				
	}
}
- (void) loadView
{
	[super loadView];
	[self HeaderCell];
	self.title = @"LockDroid";
	[UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = [UIColor colorWithRed:0.09 green:0.99 blue:0.99 alpha:1.0];
	UIButton *heart = [[UIButton alloc] initWithFrame:CGRectZero];
	[heart setImage:[[UIImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"Heart" ofType:@"png"]] forState:UIControlStateNormal];
	[heart sizeToFit];
	[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:heart];
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 55 && buttonIndex == 1) {
        system("killall backboardd SpringBoard");
    }
}
- (void)increaseAlpha
{
	[UIView animateWithDuration:0.5 animations:^{
		_label.alpha = 1;
	}completion:^(BOOL finished) {
		[UIView animateWithDuration:0.5 animations:^{
			underLabel.alpha = 1;
		}completion:nil];
	}];
}				
@end


__attribute__((constructor)) static void initialize()
{
	dlopen("/usr/lib/libcolorpicker.dylib", RTLD_GLOBAL);
}