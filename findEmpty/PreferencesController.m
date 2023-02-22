//  PreferencesController.m
//  findEmpty
//
//  Created by David Phillip Oster on 2/20/23.

#import "PreferencesController.h"

@interface PreferencesController () <NSWindowDelegate>

@end

@implementation PreferencesController

- (void)windowDidLoad {
  [super windowDidLoad];
  self.window.delegate = self;
}

@end
