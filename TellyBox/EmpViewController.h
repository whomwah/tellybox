//
//  EmpViewController.h
//  Telly
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface EmpViewController : NSViewController {
  IBOutlet WebView              *empView;
  NSString                      *displayTitle;
  NSString                      *serviceKey;
  NSString                      *playbackFormat;
  NSString                      *playbackKey;
}

@property (copy) NSString *displayTitle;
@property (copy) NSString *serviceKey;
@property (copy) NSString *playbackFormat;
@property (copy) NSString *playbackKey;

- (void)fetchEmp:(NSString *)keyString;
- (void)makeRequest;
- (NSString *)buildEmpHtml;
- (void)fetchErrorMessage:(WebView *)sender;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;

@end