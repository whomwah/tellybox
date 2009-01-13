//
//  EmpViewController.m
//  Telly
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "EmpViewController.h"

@implementation EmpViewController

@synthesize displayTitle, serviceKey, playbackFormat, playbackKey;

- (void)fetchEmp:(NSString *)keyString
{
  [self setPlaybackKey:keyString];
  [self makeRequest];
}

- (void)makeRequest
{
	[[empView mainFrame] loadHTMLString:[self buildEmpHtml] baseURL:nil];
}

- (NSString *)buildEmpHtml
{
  NSBundle *thisBundle = [NSBundle mainBundle];
  NSString *html = [NSString stringWithContentsOfFile:[thisBundle pathForResource:[self playbackFormat] ofType:@"html"]
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
  NSString *markup = [NSString stringWithFormat:html, 
                      [self playbackKey], [self playbackKey], [self playbackKey]];
  return markup;
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
  [alert setMessageText:[NSString stringWithFormat:@"Error fetching %@", displayTitle]];
  [alert setInformativeText:@"Check you are connected to the Internet? \nand try again..."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert setIcon:[NSImage imageNamed:serviceKey]];
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
