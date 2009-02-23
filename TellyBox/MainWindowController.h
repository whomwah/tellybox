//
//  MainWindowController.h
//  Telly
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class EmpViewController;
@class Schedule;

@interface MainWindowController : NSWindowController {
	IBOutlet NSView *drMainView;
  NSDockTile *dockTile;
  NSView *dockView;
  NSDictionary *currentStation;
  NSArray *stations;
  NSArray *viewSizes;
  Schedule *currentSchedule;
  EmpViewController *drEmpViewController;
}

@property (nonatomic,retain) NSView *dockView;
@property (nonatomic,retain) NSDictionary *currentStation;
@property (nonatomic,retain) Schedule *currentSchedule;
@property (nonatomic,retain) EmpViewController *drEmpViewController;

- (IBAction)refreshStation:(id)sender;
- (IBAction)changeEmpSize:(id)sender;
- (void)setAndLoadStation:(NSDictionary *)station;
- (void)changeStation:(id)sender;
- (void)fetchAOD:(id)sender;
- (void)redrawEmp;
- (void)buildStationsMenu;
- (void)buildViewSizesMenu;
- (void)buildScheduleMenu;
- (void)buildDockTileForKey:(NSString *)key;
- (void)clearMenu:(NSMenu *)menu;
- (void)registerCurrentScheduleAsObserverForKey:(NSString *)key;
- (void)unregisterCurrentScheduleForChangeNotificationForKey:(NSString *)key;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
