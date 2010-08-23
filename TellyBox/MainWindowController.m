//
//  MainWindowController.m
//  TellyBox
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "MainWindowController.h"
#import "AppDelegate.h"
#import "EmpViewController.h"
#import "BBCBroadcast.h"
#import "BBCSchedule.h"
#import "DockView.h"
#import "pw_TvAndRadioBotPassword.h"

@implementation MainWindowController

@synthesize currentSchedule, windowTitle, scheduleTimer, screenGrabTimer;

- (void)awakeFromNib
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  dockTile = [NSApp dockTile];
  stations = [ud arrayForKey:@"Stations"];
  currentStation = [stations objectAtIndex:[ud integerForKey:@"DefaultStation"]];
  dockIconView = [[DockView alloc] initWithFrame:
                  NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height) 
                                         withKey:[currentStation objectForKey:@"key"]];
  [dockTile setContentView:dockIconView];
	[dockTile display];
  
  empViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  [[empViewController view] setFrameSize:[drMainView frame].size];
  [drMainView addSubview:[empViewController view]];
  [self fetchTV:currentStation];
    
  NSSize newSize = [empViewController defaultSize];
  NSPoint pos = NSPointFromString([ud stringForKey:@"DefaultEmpOrigin"]);
  [[self window] setFrame:NSMakeRect(pos.x, pos.y, newSize.width, newSize.height) 
                  display:NO];
  [[self window] setMaxSize:[empViewController maximumSize]];
  [[self window] setMinSize:[empViewController minimumSize]];
}

- (void)windowDidLoad
{
  [self setNextResponder:empViewController];
  [self buildViewSizesMenu];
  [self buildStationsMenu];
  self.windowTitle = @"BBC Television";
  
  NSString *username = RATVB_TWITTER_USER;
  NSString *password = RATVB_TWITTER_PASS;
  
  twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
  [twitterEngine setUsername:username password:password];
  [twitterEngine setClientName:@"TellyBox" 
                       version:@"1.5" 
                           URL:@"http://whomwah.github.com/tellybox" 
                         token:@"tellybox"];
}

- (void)dealloc
{
  [dockIconView release];
  [currentSchedule release];
	[empViewController release];
  [twitterEngine release];
	[super dealloc];
}

- (void)fetchTV:(NSDictionary *)station
{  
  currentStation = station;
  self.windowTitle = @"Loading...";
  [empViewController fetchLIVE:currentStation];
  [self changeDockNetworkIcon];
  [self fetchNewSchedule:nil];
}

- (void)fetchEMP:(id)sender
{
  [self stopScheduleTimer];
  BBCBroadcast *broadcast = [[currentSchedule broadcasts] objectAtIndex:[sender tag]];
  currentBroadcast = broadcast;  
  
  self.windowTitle = [currentSchedule broadcastDisplayTitleForIndex:[sender tag]];
  [empViewController fetchCATCHUP:[broadcast pid]];
  [self changeDockNetworkIcon];
  [self buildScheduleMenu];
  [self growl];
}

- (void)changeDockNetworkIcon
{
  NSImage *img = [NSImage imageNamed:[currentStation objectForKey:@"key"]];
  [dockIconView setNetworkIcon:img];
	[dockTile display];
  [self startScreenGrabTimer];
}

- (void)stopScreenGrabTimer
{
  [screenGrabTimer invalidate];
  self.screenGrabTimer = nil;  
}

- (void)startScreenGrabTimer
{
  [self stopScreenGrabTimer];
  NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10.0 // 10 seconds
                                                    target:self
                                                  selector:@selector(grabScreen:)
                                                  userInfo:nil
                                                   repeats:YES];
  NSLog(@"screen grab will be taken again in 10 seconds");
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
  self.screenGrabTimer = timer;
}

- (void)grabScreen:(id)sender
{ 
  [dockIconView setWindowId:[[self window] windowNumber]];
	[dockTile display];
}

- (void)fetchNewSchedule:(id)sender
{  
  [currentSchedule removeObserver:self forKeyPath:@"broadcasts"];
  BBCSchedule *sc = [[BBCSchedule alloc] initUsingNetwork:[currentStation objectForKey:@"key"] 
                                                andOutlet:[currentStation objectForKey:@"outlet"]];
  [sc fetchScheduleForDate:[NSDate date]];
  
  self.currentSchedule = sc;
  [currentSchedule addObserver:self
                    forKeyPath:@"broadcasts"
                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                       context:NULL];
  [sc release];  
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  if (currentSchedule.current_broadcast) {
    currentBroadcast = currentSchedule.current_broadcast;
    self.windowTitle = [currentSchedule currentBroadcastDisplayTitle];
    [self buildScheduleMenu];
    [self startScheduleTimer];
    [self growl];
  } else {
    self.windowTitle = @"Service Unavailable";
    [self buildScheduleMenu];
  }
}

- (void)growl
{
  NSImage *img = [[NSImage alloc] initWithData:[dockIconView dataWithPDFInsideRect:[dockIconView frame]]];
  [GrowlApplicationBridge notifyWithTitle:[currentSchedule.service title]
                              description:[[currentBroadcast display_titles] objectForKey:@"title"]
                         notificationName:@"Now playing"
                                 iconData:[img TIFFRepresentation]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  [img release];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultSendToTwitter"] == YES) {
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[self createTweet] 
                                                     forKey:@"tweet"];
    [NSTimer scheduledTimerWithTimeInterval:300.0 // 5 minutes
                                     target:self
                                   selector:@selector(tweet:)
                                   userInfo:dict
                                    repeats:NO];
  }
}

- (NSString *)createTweet
{
  return [NSString stringWithFormat:@"%@ is %@ %@ on %@ %@", 
          [self realOrTwitterName], 
          [self liveOrNotText], 
          [currentBroadcast.display_titles objectForKey:@"title"], 
          [currentSchedule.service title], 
          currentBroadcast.programme_url
          ];
}

- (void)tweet:(id)sender
{
  NSString *oldTweet = [[sender userInfo] valueForKey:@"tweet"];
  NSString *newTweet = [self createTweet];
  NSLog(@"checking");
  if ([newTweet isEqualToString:oldTweet] && ((currentBroadcast && [empViewController isLive]) || ![empViewController isLive])) {
    [twitterEngine sendUpdate:newTweet];
    NSImage *twitter_logo = [NSImage imageNamed:@"robot"];
    [GrowlApplicationBridge notifyWithTitle:@"Sending to @radioandtvbot on Twitter.com"
                                description:newTweet
                           notificationName:@"Send to Twitter"
                                   iconData:[twitter_logo TIFFRepresentation]
                                   priority:1
                                   isSticky:NO
                               clickContext:nil];
  } else {
    NSLog(@"No tweet, you changed channels or there is no broadcast");
  }
}

- (NSString *)liveOrNotText
{
  if ([empViewController isLive]) {
    return @"watching";
  } else {
    return @"catching up with"; 
  }
}

- (NSString *)realOrTwitterName
{
  NSString *uname = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultTwitterUsername"];
  if ([uname isEqualToString:@""] == YES) {
    return NSFullUserName();
  }  else {
    return [NSString stringWithFormat:@"@%@", uname];
  }  
}

- (void)stopScheduleTimer
{
  [scheduleTimer invalidate];
  self.scheduleTimer = nil;  
}

- (void)startScheduleTimer
{
  [self stopScheduleTimer];
  NSTimer *timer = [[NSTimer alloc] initWithFireDate:currentBroadcast.end
                                            interval:0.0
                                              target:self
                                            selector:@selector(fetchNewSchedule:)
                                            userInfo:nil
                                             repeats:NO];
  NSLog(@"Timer started and will be fired again at %@", currentBroadcast.end);
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
  self.scheduleTimer = timer;
}

- (void)changeStation:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"DefaultStation"];
  [[[sender menu] itemWithTitle:[currentStation objectForKey:@"label"]] setState:NSOffState];
  [sender setState:NSOnState];
  [self fetchTV:[stations objectAtIndex:[sender tag]]];
}

#pragma mark Build Listen menu

- (void)buildStationsMenu
{
  NSMenuItem *newItem;
  NSMenu *menu = [[[NSApp mainMenu] itemWithTitle:@"Watch"] submenu];
  int count = 0;
  
  for (NSDictionary *station in stations) {      
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[station valueForKey:@"label"] 
                                                                   action:@selector(changeStation:) 
                                                            keyEquivalent:@""];
    if ([currentStation isEqualTo:station] == YES)
      [newItem setState:NSOnState];
    
    [newItem setEnabled:YES];
    NSImage *img = [[NSImage imageNamed:[station valueForKey:@"key"]] copyWithZone:NULL];
    [img setSize:NSMakeSize(50.0, 28.0)];
    [newItem setImage:img];
    [newItem setTag:count];
    [newItem setTarget:self];
    [menu insertItem:newItem atIndex:count+2];
    
    [newItem release];
    [img release];
    count++;
  }
}

- (void)clearMenu:(NSMenu *)menu
{
  for (NSMenuItem *item in [menu itemArray]) {  
    [menu removeItem:item];
  }
}

#pragma mark Build viewSizes Menu

- (void)buildViewSizesMenu
{
  NSMenuItem *newItem;
  NSMenu *menu = [[[NSApp mainMenu] itemWithTitle:@"View"] submenu];
  [self clearMenu:menu];
  int count = 0;
  
  for (NSDictionary *v in [[NSUserDefaults standardUserDefaults] arrayForKey:@"EmpSizes"]) {      
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] 
               initWithTitle:[v valueForKey:@"label"] 
               action:@selector(changeEmpSize:) 
               keyEquivalent:[NSString stringWithFormat:@"%i", count + 1]];
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultEmpSize"] intValue] == count)
      [newItem setState:NSOnState];
    [newItem setEnabled:YES];
    [newItem setTag:count];
    [newItem setTarget:self];
    [menu addItem:newItem];
    
    [newItem release];
    count++;
  }
}

- (void)changeEmpSize:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"DefaultEmpSize"];
  [self buildViewSizesMenu];  
  NSSize newSize = [empViewController sizeForEmp:[sender tag]];
  [empViewController resizeEmpTo:newSize];
}

- (void)buildScheduleMenu
{
  NSMenuItem *newItem;
  NSString *start;
  NSMenu *scheduleMenu = [[[NSApp mainMenu] itemWithTitle:@"Schedule"] submenu];  
  [self clearMenu:scheduleMenu];
  int count = 0;
  
  for (BBCBroadcast *broadcast in [currentSchedule broadcasts]) {
    
    start = [broadcast.start descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" 
                                                                   action:NULL 
                                                            keyEquivalent:@""];
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@  %@", start, [broadcast.display_titles objectForKey:@"title"]];
    NSString *state = @"";
    
    if ([broadcast isEqual:currentBroadcast] == YES) {
      state = @" NOW PLAYING";
      [newItem setState:NSOnState]; 
    } else if ([broadcast isEqual:currentSchedule.current_broadcast] == YES) {
      state = @" LIVE";
      [newItem setAction:@selector(refreshStation:)];
    } else if (broadcast.media && [[broadcast.media objectForKey:@"format"] isEqualToString:@"tv"]) {
      [newItem setAction:@selector(fetchEMP:)];
    }
    
    [str appendString:state];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:str];
    NSString *display_title = [broadcast.display_titles objectForKey:@"title"];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:13.6]
                   range:NSMakeRange(0,[start length])];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:13.6]
                   range:NSMakeRange([start length]+1,[display_title length])];
    
    [string addAttribute:NSForegroundColorAttributeName
                   value:[NSColor lightGrayColor]
                   range:NSMakeRange(2+[start length]+[display_title length],[state length])];
    
    [string addAttribute:NSFontAttributeName
                   value:[NSFont userFontOfSize:9]
                   range:NSMakeRange(2+[start length]+[display_title length],[state length])];
    
    [newItem setAttributedTitle:string];
    [newItem setEnabled:YES];
    [newItem setTag:count];
    [newItem setEnabled:YES];
    [newItem setTarget:self];
    [scheduleMenu addItem:newItem];
    [newItem release];
    [string release];
    count++;
  }
}

- (void)redrawEmp
{
  [[empViewController view] setNeedsDisplay:YES];  
}

- (IBAction)refreshStation:(id)sender
{
  [self fetchTV:currentStation];
}

#pragma mark Main Window delegate

- (void)windowDidResignMain:(NSNotification *)notification
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultAlwaysOnTop"] == YES) {
    [[self window] setLevel:NSFloatingWindowLevel];
  } else {
    [[self window] setLevel:NSNormalWindowLevel];
  }
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
  [[self window] setLevel:NSNormalWindowLevel];
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
  if ([[empViewController viewSizes] containsObject:NSStringFromSize(proposedFrameSize)] == NO) {
    return [empViewController defaultSize];
  }
  return proposedFrameSize;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{
  return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSRect currentFrame = [[self window] frame];
  currentFrame.size = [empViewController maximumSize];
  
  if (NSEqualSizes([empViewController defaultSize],[empViewController minimumSize]) == NO) {
    currentFrame.size = [empViewController minimumSize];
  }
  
  [ud setInteger:[empViewController intForEmpWithSize:currentFrame.size] forKey:@"DefaultEmpSize"];
  [self buildViewSizesMenu];
  return currentFrame;
}

#pragma mark MGTwitterEngineDelegate methods

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
  NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
  NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
        connectionIdentifier, 
        [error localizedDescription], 
        [error userInfo]);
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got statuses for %@:\r%@", connectionIdentifier, statuses);
}

- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got user info for %@:\r%@", connectionIdentifier, userInfo);
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
	NSLog(@"Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
	NSLog(@"Got search results for %@:\r%@", connectionIdentifier, searchResults);
}

- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier
{
  NSLog(@"Got an image for %@: %@", connectionIdentifier, image);
}

- (void)connectionFinished
{
  NSLog(@"Connection finished");
}

@end
