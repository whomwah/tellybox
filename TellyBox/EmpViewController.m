//
//  EmpViewController.m
//  TellyBox
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "EmpViewController.h"

@implementation EmpViewController

//config_settings_bitrateFloor=0&amp;config_settings_bitrateCeiling=800&amp;

@synthesize viewSizes;

- (void)awakeFromNib
{
  NSArray *sizes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"EmpSizes"];
  NSMutableArray *arry = [NSMutableArray array];
  for (NSDictionary *d in sizes) {
    [arry addObject:[d objectForKey:@"size"]];
  }
  self.viewSizes = arry;
}

- (void)fetchLIVE:(NSDictionary *)d
{
  data = d;
  markup = nil;
  
  [self startBuildingEmp:[data valueForKey:@"empKey"]];
}

- (void)fetchCATCHUP:(NSString *)str
{
  data = nil;
  markup = nil;
  
  [self startBuildingEmp:str];
}

- (BOOL)isLive
{
  if (data) {
    return YES;
  } else {
    return NO;    
  }
}

- (NSString *)playbackFormat
{
  if ([self isLive] == YES) {
    return @"live";
  } else {
    return @"emp";    
  }
}

- (NSString *)tmpl
{
  NSString *path = [[NSBundle mainBundle] pathForResource:[self playbackFormat] 
                                                   ofType:@"html"];
  return [NSString stringWithContentsOfFile:path
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
}

- (NSSize)defaultSize
{
  int index = [[[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultEmpSize"] intValue];
  return [self sizeForEmp:index];
}

- (NSSize)minimumSize
{
  return [self sizeForEmp:0];
}

- (NSSize)normalSize
{
  return [self sizeForEmp:2];
}

- (NSSize)maximumSize
{
  int index = [[[NSUserDefaults standardUserDefaults] valueForKey:@"EmpSizes"] count];
  return [self sizeForEmp:index-1];
}

- (void)startBuildingEmp:(NSString *)key
{
  [self resizeEmpTo:[self defaultSize]];
  markup = [NSString stringWithFormat:[self tmpl], key, key];
  [self makeRequest];
}

- (void)makeRequest
{
  [[empView mainFrame] loadHTMLString:markup baseURL:[NSURL URLWithString:@"http://www.bbc.co.uk/"]];  
}

- (int)intForEmpWithSize:(NSSize)size
{
  int n;
  for (n = 0; n < [[[NSUserDefaults standardUserDefaults] arrayForKey:@"EmpSizes"] count]; n++) {
    if (NSEqualSizes(size,[self sizeForEmp:n]) == YES) {
      return n;
    }
  }
  return 0;
}

- (NSSize)sizeForEmp:(int)index
{
  NSSize size = NSSizeFromString([viewSizes objectAtIndex:index]);
  size.height = size.height + 25.0;
  return size;
}

- (void)resizeEmpTo:(NSSize)size
{ 
  NSWindow *w = [[self view] window];
  NSSize currentSize = [w frame].size; 
  
  if (NSEqualSizes(size,currentSize) == YES)
    return;
  
  float deltaWidth = size.width - currentSize.width;
  float deltaHeight = size.height - currentSize.height;
  
  NSRect wf = [w frame];
  wf.size.width += deltaWidth;
  wf.size.height += deltaHeight;
  wf.origin.x -= deltaWidth/2;
  wf.origin.y -= deltaHeight/2;
  
  [w setFrame:wf display:YES animate:YES];
}

#pragma mark URL load Delegates

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Started to load the page");
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
  NSLog(@"Finshed loading page");
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
  [self fetchErrorMessage:(id)sender];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
  [self fetchErrorMessage:(id)sender];  
}

#pragma mark URL fetch errors

- (void)fetchErrorMessage:(WebView *)sender
{
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"Try again?"];
  [alert addButtonWithTitle:@"Quit"];
  [alert setMessageText:@"Error fetching stream"];
  [alert setInformativeText:@"Check you are connected to the Internet? \nand try again..."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert beginSheetModalForWindow:[empView window]
                    modalDelegate:self 
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                      contextInfo:nil];
  [alert release];  
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn) {
    return [self makeRequest];
  } else if (returnCode == NSAlertSecondButtonReturn) {
    return [NSApp terminate:self]; 
  }
}

@end
