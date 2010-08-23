//
//  AppDelegate.h
//  TellyBox
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class MainWindowController;
@class PreferencesWindowController;

@interface AppDelegate : NSObject <GrowlApplicationBridgeDelegate>
{
	MainWindowController *drMainWindowController;
  PreferencesWindowController *preferencesWindowController;
}

- (IBAction)displayPreferenceWindow:(id)sender;
- (IBAction)visitIplayerSite:(id)sender;
- (IBAction)visitTermsAndCondSite:(id)sender;
- (IBAction)visitHelpSite:(id)sender;
- (IBAction)visitWebSite:(id)sender;

@end
