//
//  MainWindowController.m
//  Telly
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "MainWindowController.h"
#import "EmpViewController.h"
#import "Broadcast.h"
#import "Schedule.h"

@implementation MainWindowController

@synthesize currentStation, currentSchedule;
@synthesize dockView;
@synthesize drEmpViewController;

- (void)awakeFromNib
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  viewSizes = [ud arrayForKey:@"EmpSizes"];
  stations = [ud arrayForKey:@"Stations"];
  
  NSDictionary *s = [viewSizes objectAtIndex:[ud integerForKey:@"DefaultEmpSize"]];
  
  [[self window] setFrame:NSMakeRect([ud integerForKey:@"DefaultEmpOriginX"],
                                     [ud integerForKey:@"DefaultEmpOriginY"],
                                     [[s valueForKey:@"width"] intValue],
                                     [[s valueForKey:@"height"] intValue] + 22.0
                                     ) display:NO];
}

- (void)windowDidLoad
{
  dockTile = [NSApp dockTile];
  
  self.drEmpViewController = [[EmpViewController alloc] initWithNibName:@"EmpView" bundle:nil];
  
  [drMainView addSubview:[drEmpViewController view]];
  [[drEmpViewController view] setFrameSize:[drMainView frame].size];
  [self setNextResponder:drEmpViewController];
  
  [self setCurrentStation:[stations objectAtIndex:[[NSUserDefaults standardUserDefaults] 
                                                   integerForKey:@"DefaultStation"]]];
  [self buildViewSizesMenu];
  [self buildStationsMenu];
  [self setAndLoadStation:currentStation];
}

- (void)dealloc
{
  [currentSchedule release];
	[drEmpViewController release];
	[super dealloc];
}

- (void)setAndLoadStation:(NSDictionary *)station
{  
  Schedule *cSchedule;
  
  NSLog(@"setAndLoadStation:%@", station);
  [self setCurrentStation:station];
  [drEmpViewController setDisplayTitle:@"BBC"];
  [drEmpViewController setServiceKey:[station valueForKey:@"key"]];
  [drEmpViewController setPlaybackFormat:@"live"];
  [drEmpViewController fetchEmp:[station valueForKey:@"empKey"]];
  
  [self buildDockTileForKey:[currentStation valueForKey:@"key"]];
	[dockTile setContentView:dockView];
	[dockTile display];
  
  [self unregisterCurrentScheduleForChangeNotificationForKey:@"currentBroadcast"];
  cSchedule = [[Schedule alloc] initUsingService:[currentStation valueForKey:@"key"] 
                                          outlet:[currentStation valueForKey:@"outlet"]];
  [self setCurrentSchedule:cSchedule];
  [self registerCurrentScheduleAsObserverForKey:@"currentBroadcast"];
  
  [cSchedule release];
}

- (void)buildDockTileForKey:(NSString *)key
{
  NSRect dockFrame = NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height);
  NSView *dockIconView = [[NSView alloc] initWithFrame:dockFrame];

  NSImageView *serviceIconView = [[NSImageView alloc] initWithFrame: 
                                  NSMakeRect(0, 0, dockTile.size.width-15.0, dockTile.size.height-10.0)];
  NSImage *serviceImg = [[NSImage alloc] initWithData:
    [NSData dataWithData:[[NSImage imageNamed:key] TIFFRepresentation]]];
  [serviceIconView setImage:serviceImg];
  [serviceIconView setImageAlignment:NSImageAlignTopRight];

	NSImageView *appIconView = [[NSImageView alloc] initWithFrame:dockFrame];
  NSImage *appIcon = [[NSImage alloc] initWithData:
    [NSData dataWithData:[[NSImage imageNamed:@"television"] TIFFRepresentation]]];  
  [appIconView setImage:appIcon];
  
  [dockIconView addSubview:appIconView];
  [dockIconView addSubview:serviceIconView];
  [self setDockView:dockIconView];
  
  [dockIconView release];
  [serviceImg release];
  [appIcon release];
  [appIconView release];
}

- (void)changeStation:(id)sender
{
  [[[sender menu] itemWithTitle:[currentStation valueForKey:@"label"]] setState:NSOffState];
  [sender setState:NSOnState];
  [self setAndLoadStation:[stations objectAtIndex:[sender tag]]];
}

- (void)registerCurrentScheduleAsObserverForKey:(NSString *)key
{
  [currentSchedule addObserver:self
                    forKeyPath:key
                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                       context:NULL];
}

- (void)unregisterCurrentScheduleForChangeNotificationForKey:(NSString *)key
{
  [currentSchedule removeObserver:self forKeyPath:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  [self buildScheduleMenu];
  if ([currentSchedule currentBroadcast]) {
    NSString *stitle = [[currentSchedule service] displayTitle];
    [drEmpViewController setDisplayTitle:stitle];
    [GrowlApplicationBridge notifyWithTitle:stitle
                              description:[[currentSchedule currentBroadcast] displayTitle]
                         notificationName:@"Station about to play"
                                 iconData:[NSData dataWithData:
                                           [[NSImage imageNamed:[currentStation valueForKey:@"key"]] TIFFRepresentation]]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
  }
}

#pragma mark Build Stations Menu

- (void)buildStationsMenu
{
  NSMenuItem *newItem;
  NSMenu *listenMenu = [[[NSApp mainMenu] itemWithTitle:@"Watch"] submenu];
  int count = 0;
  
  for (NSDictionary *station in stations) {      
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[station valueForKey:@"label"] 
                                                                   action:@selector(changeStation:) 
                                                            keyEquivalent:@""];
    
    if ([currentStation isEqualTo:station] == YES)
      [newItem setState:NSOnState];
    [newItem setEnabled:YES];
    NSImage *img = [[NSImage alloc] initWithData:[NSData dataWithData:
                                                  [[NSImage imageNamed:[station valueForKey:@"key"]] TIFFRepresentation]]];
    [img setSize:NSMakeSize(40.0, 25.0)];
    [newItem setImage:img];
    [newItem setTag:count];
    [newItem setTarget:self];
    [listenMenu addItem:newItem];
    
    [img release];
    [newItem release];
    count++;
  }
}

#pragma mark Build viewSizes Menu

- (void)buildViewSizesMenu
{
  NSMenuItem *newItem;
  NSMenu *menu = [[[NSApp mainMenu] itemWithTitle:@"View"] submenu];
  [self clearMenu:menu];
  int count = 0;
  
  for (NSDictionary *v in viewSizes) {      
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

#pragma mark Build Schedule Menu

- (void)buildScheduleMenu
{
  NSMenuItem *newItem;
  NSString *start;
  NSMutableString *label;
  NSMenu *scheduleMenu = [[[NSApp mainMenu] itemWithTitle:@"Schedule"] submenu];  
  NSFont *font = [NSFont userFontOfSize:13.0];
  NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
  [self clearMenu:scheduleMenu];
  int count = 0;
  
  for (Broadcast *broadcast in [currentSchedule broadcasts]) {
    
    start = [[broadcast bStart] descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
    label = [NSMutableString stringWithFormat:@"%@ %@", start, [broadcast displayTitle]];
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" 
                                                                   action:NULL 
                                                            keyEquivalent:@""];    
    if ([broadcast availableText]) {
      [newItem setAction:@selector(fetchAOD:)];
      [label appendFormat:@" (%@)", [broadcast availableText]];      
    }
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:label
                                                                     attributes:attrsDictionary];
    
    [newItem setAttributedTitle:attrString];
    [newItem setEnabled:YES];
    [newItem setTag:count];
    if ([broadcast isEqual:[currentSchedule currentBroadcast]] == YES) {
      [newItem setState:NSOnState];
    }
    [newItem setEnabled:YES];
    [newItem setTarget:self];
    [scheduleMenu addItem:newItem];
    [newItem release];
    [attrString release];
    count++;
  }
}

- (void)clearMenu:(NSMenu *)menu
{
  for (NSMenuItem *item in [menu itemArray]) {  
    [menu removeItem:item];
  }
}

- (void)fetchAOD:(id)sender
{
  Broadcast *broadcast = [[currentSchedule broadcasts] objectAtIndex:[sender tag]];
  [dockTile display];
  [drEmpViewController setDisplayTitle:[broadcast displayTitle]];
  [drEmpViewController setServiceKey:[[currentSchedule service] key]];
  [drEmpViewController setPlaybackFormat:@"emp"];
  [drEmpViewController fetchEmp:[broadcast pid]];
  
  [GrowlApplicationBridge notifyWithTitle:[[currentSchedule service] displayTitle]
                              description:[broadcast displayTitle]
                         notificationName:@"Station about to play"
                                 iconData:[NSData dataWithData:
                                           [[NSImage imageNamed:[[currentSchedule service] key]] TIFFRepresentation]]
                                 priority:1
                                 isSticky:NO
                             clickContext:nil];
}

- (void)redrawEmp
{
  [[drEmpViewController view] setNeedsDisplay:YES];  
}

- (IBAction)refreshStation:(id)sender
{
  [self setAndLoadStation:[self currentStation]];
}

- (IBAction)changeEmpSize:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"DefaultEmpSize"];
  [self buildViewSizesMenu];
  int w = [[[viewSizes objectAtIndex:[sender tag]] valueForKey:@"width"] intValue];
  int h = [[[viewSizes objectAtIndex:[sender tag]] valueForKey:@"height"] intValue];
  [drEmpViewController resizeEmpTo:NSMakeSize(w,h)];
}



@end
