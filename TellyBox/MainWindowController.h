//
//  MainWindowController.h
//  TellyBox
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "MGTwitterEngine.h"

@class EmpViewController;
@class BBCSchedule;
@class BBCBroadcast;
@class DockView;

@interface MainWindowController : NSWindowController <MGTwitterEngineDelegate> {
	IBOutlet NSView *drMainView;
  NSDockTile *dockTile;
  NSDictionary *currentStation;
  NSArray *stations;
  NSString *windowTitle;
  BBCSchedule *currentSchedule;
  BBCBroadcast *currentBroadcast;
  EmpViewController *empViewController;
  NSTimer *scheduleTimer;
  NSTimer *screenGrabTimer;
  DockView *dockIconView;
  MGTwitterEngine *twitterEngine;
}

@property (nonatomic, assign) NSTimer *screenGrabTimer;
@property (nonatomic, assign) NSTimer *scheduleTimer;
@property (nonatomic, copy) NSString *windowTitle;
@property (nonatomic, retain) BBCSchedule *currentSchedule;

- (void)stopScreenGrabTimer;
- (void)startScreenGrabTimer;
- (void)grabScreen:(id)sender;
- (void)changeEmpSize:(id)sender;
- (void)buildViewSizesMenu;
- (NSString *)createTweet;
- (void)tweet:(id)sender;
- (NSString *)realOrTwitterName;
- (NSString *)liveOrNotText;
- (void)growl;
- (void)changeDockNetworkIcon;
- (void)stopScheduleTimer;
- (void)startScheduleTimer;
- (void)refreshStation:(id)sender;
- (void)fetchTV:(NSDictionary *)station;
- (void)fetchEMP:(id)sender;
- (void)changeStation:(id)sender;
- (void)redrawEmp;
- (void)buildStationsMenu;
- (void)buildScheduleMenu;
- (void)fetchNewSchedule:(id)sender;
- (void)clearMenu:(NSMenu *)menu;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change context:(void *)context;

@end
