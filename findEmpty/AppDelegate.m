//  AppDelegate.m
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.

#import "AppDelegate.h"

#import "FindEmptyDirViewController.h"
#import "PreferencesController.h"

@implementation AppDelegate

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
  return YES;
}

// If the viewController's window is closed, then this is all that can handle the open menu command.
- (IBAction)openDocument:(id)sender {
  [self.viewController.view.window makeKeyAndOrderFront:nil];
  [(id)self.viewController openDocument:sender];
}


- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [self.viewController openPath:filename];
  return YES;
}

- (IBAction)showPreferences:(id)sender {
  if (self.prefController == nil) {
    self.prefController = [NSStoryboard.mainStoryboard instantiateControllerWithIdentifier:@"PreferencesController"];
  }
#if 1
  [self.prefController.window makeKeyAndOrderFront:nil];
#else
  // Commented out because currently the only way to close settings is with the close button in its titlebar.
  NSWindow *window = self.viewController.view.window;
  if (window.visible) {
    [window beginSheet:self.prefController.window completionHandler:nil];
  } else {
    [self.prefController.window makeKeyAndOrderFront:nil];
  }
#endif
}

@end
