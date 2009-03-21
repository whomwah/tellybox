//
//  EmpViewController.h
//  TellyBox
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface EmpViewController : NSViewController {
  IBOutlet WebView *empView;
  NSDictionary *data;
  NSString *markup;
  NSMutableArray *viewSizes;
}

@property (nonatomic, retain) NSMutableArray *viewSizes;

- (BOOL)isLive;
- (void)makeRequest;
- (NSSize)defaultSize;
- (NSSize)normalSize;
- (NSSize)minimumSize;
- (NSSize)maximumSize;
- (NSString *)playbackFormat;
- (NSSize)sizeForEmp:(int)index;
- (int)intForEmpWithSize:(NSSize)size;
- (void)resizeEmpTo:(NSSize)size;
- (void)startBuildingEmp:(NSString *)key;
- (void)fetchLIVE:(NSDictionary *)d;
- (void)fetchCATCHUP:(NSString *)str;
- (void)fetchErrorMessage:(WebView *)sender;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;

@end