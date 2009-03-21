//
//  DockView.m
//  TellyBox
//
//  Created by Duncan Robertson on 11/03/2009.
//  Copyright 2009 Whomwah. All rights reserved.
//

#import "DockView.h"

#define PICT_SIZE @"{90.0 80.0}"
#define HOLD_SIZE @"{100.0 70.0}"

@implementation DockView

@synthesize networkIcon, windowId;

- (id)initWithFrame:(NSRect)frame withKey:(NSString *)key 
{
  self = [super initWithFrame:frame];
  if (self) {
    self.networkIcon = [NSImage imageNamed:key];
    appIcon = [NSImage imageNamed:@"tellybox-on"];
  }
  return self;
}

- (void)drawRect:(NSRect)rect
{
  [self setSubviews:[NSArray array]];
  NSImageView *tvIconView = [[NSImageView alloc] initWithFrame:rect];
  NSImageView *appIconView = [[NSImageView alloc] initWithFrame:rect];  
  [appIconView setImage:appIcon];
  
  if (windowId) {  
    NSImage *image;
    CGWindowID wid = windowId;
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, 
                                kCGWindowListOptionIncludingWindow, 
                                wid, 
                                kCGWindowImageBoundsIgnoreFraming);
    
    if (!(CGImageGetWidth(windowImage) <= 1)) {
      NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: windowImage];
      image = [[NSImage alloc] initWithSize:NSSizeFromString(PICT_SIZE)];
      [image addRepresentation:bitmapRep];
      [tvIconView setImage:image];
      [image release];
      [bitmapRep release];
    } else {
      image = [NSImage imageNamed:@"tcard"];
      [image setSize:NSSizeFromString(HOLD_SIZE)];
      [tvIconView setImage:image];
    }
    CGImageRelease(windowImage);
  } else {
    NSImage *image = [NSImage imageNamed:@"tcard"];
    [image setSize:NSSizeFromString(HOLD_SIZE)];
    [tvIconView setImage:image];
  }
  
  [tvIconView setImageAlignment:NSImageAlignCenter];  
  [self addSubview:tvIconView];
  [self addSubview:appIconView];

  if (networkIcon) {
    NSImageView *networkIconView = [[NSImageView alloc] initWithFrame: 
                                    NSMakeRect(15, rect.size.height - [networkIcon size].height - 2, 
                                               [networkIcon size].width, [networkIcon size].height)];
    
    [networkIconView setImage:networkIcon];
    [networkIconView setImageAlignment:NSImageAlignCenter];
    [self addSubview:networkIconView];
    [networkIconView release];
  }
  
  [tvIconView release];        
  [appIconView release]; 
}

@end
