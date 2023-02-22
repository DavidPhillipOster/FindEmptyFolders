//  AppDelegate.h
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.

#import <Cocoa/Cocoa.h>

@class FindEmptyDirViewController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property FindEmptyDirViewController *viewController;
@property NSWindowController *prefController;

@end

