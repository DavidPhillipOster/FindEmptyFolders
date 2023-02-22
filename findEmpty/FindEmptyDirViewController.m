//  FindEmptyDirViewController.m
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.

#import "FindEmptyDirViewController.h"

#import "AppDelegate.h"
#import "DirItem.h"
#import "FindEmptyDir.h"

@interface FindEmptyDirViewController () <FindEmptyDelegate, NSMenuItemValidation, NSOutlineViewDelegate, NSOutlineViewDataSource>
@property IBOutlet NSOutlineView *outlineView;
@property IBOutlet NSView *coverView;
@property IBOutlet NSTextField *label;
@property(nonatomic) NSArray<DirItem *> *dirItems;
@property FindEmptyDir *findEmpty;
@property NSOperationQueue *queue;
@property NSTimer *progressTimer;
@property NSString *root;
// while the outlineView is disabled, it's menu lives here.
@property NSMenu *saveMenu;
@property BOOL isInFind;
@end

@implementation FindEmptyDirViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"partialPath" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc {
  [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"partialPath"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (object == NSUserDefaults.standardUserDefaults && NULL == context) {
    if ([keyPath isEqual:@"partialPath"]) {
      if (self.dirItems) {
        NSMutableArray *mDirItems = [self.dirItems mutableCopy];
        [DirItem sortTree:mDirItems isPartialPath:[NSUserDefaults.standardUserDefaults boolForKey:@"partialPath"]];
        self.dirItems = mDirItems;
        [self.outlineView deselectAll:nil];
        [self.outlineView reloadData];
      }
    }
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.findEmpty = [[FindEmptyDir alloc] init];
  self.findEmpty.delegate = self;

  self.coverView.layer.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent:0.5] CGColor];

  self.queue = [[NSOperationQueue alloc] init];
  [self performSelector:@selector(openDocument:) withObject:nil afterDelay:0.1];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [(AppDelegate *)NSApp.delegate setViewController:self];
}

- (void)showProgress:(NSTimer *)timer {
  NSString *s = @"";
  if (self.isInFind) {
    s = [NSString stringWithFormat:@"Directories Examined: %lu", (unsigned long)self.findEmpty.counter];
  }
  self.label.stringValue = s;
}

- (IBAction)openDocument:(id)sender {
  if (self.isInFind) {  return; }
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowsMultipleSelection = NO;
  panel.canChooseDirectories = YES;
  panel.canChooseFiles = NO;
  panel.canCreateDirectories = NO;
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
    if (NSModalResponseOK == result) {
      [self openPath:panel.URL.path];
    }
  }];
}

- (void)openPath:(NSString *)path {
  if (self.isInFind) {  return; }
  NSView *superView = self.outlineView.superview.superview;
  [superView addSubview:self.coverView];
  self.coverView.frame = CGRectInset(superView.bounds, -1, -1);
  self.label.stringValue = @"";
  [self.label setHidden:NO];
  [self setOutlineViewEnabled:NO];
  self.root = path;
  self.view.window.title = path;
  self.isInFind = YES;
  self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showProgress:) userInfo:nil repeats:YES];
  [self.queue addOperation:[NSBlockOperation blockOperationWithBlock:^{
    [self.findEmpty findEmptyAt:self.root];
  }]];
}

- (IBAction)delete:(id)sender {
  NSArray<NSURL *> *urls = [self selectedURLs];
  NSIndexSet *indexes = self.outlineView.selectedRowIndexes;
  NSWorkspace *ws = NSWorkspace.sharedWorkspace;
  [ws recycleURLs:urls completionHandler:nil];
  NSMutableArray *dirItems = [self.dirItems mutableCopy];
  for (NSUInteger i = indexes.firstIndex; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]) {
    DirItem *item = [self.outlineView itemAtRow:i];
    DirItem *parent = item.parent;
    if (parent) {
      [parent.children removeObject:item];
      if (0 == parent.children.count) {
        parent.children = nil;
      }
    } else {
      [dirItems removeObject:item];
    }
  }
  self.dirItems = dirItems;
  [self.outlineView deselectAll:nil];
  [self.outlineView reloadData];
}

- (void)findEmpty:(FindEmptyDir *)finder found:(NSArray<DirItem *> *)found error:(nullable NSError *)error{
  [[NSOperationQueue mainQueue] addOperation:[NSBlockOperation blockOperationWithBlock:^{
    [self.coverView removeFromSuperview];
    [self setOutlineViewEnabled:YES];
    self.dirItems = found;
    self.isInFind = NO;
    if (error) {
      [self presentError:error];
    }
    [self.progressTimer invalidate];
    if (found.count) {
      [self.label setHidden:YES];
    } else {
      self.label.stringValue = @"No Empty Directories";
    }
  }]];
}

- (void)setOutlineViewEnabled:(BOOL)isOK {
  if (isOK && nil != self.outlineView) {
    self.outlineView.menu = self.saveMenu;
  }
  if (!isOK) {
    if (self.outlineView.menu) {
      self.saveMenu = self.outlineView.menu;
      self.outlineView.menu = nil;
    }
  }
  [self.outlineView setEnabled:isOK];
}

- (void)setDirItems:(NSArray<DirItem *> *)paths {
  _dirItems = paths;
  [self.outlineView reloadData];
}


- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  if ([menuItem action] == @selector(openDocument:)) {
    return !self.isInFind;
  } else if ([menuItem action] == @selector(delete:)) {
    NSUInteger count = self.outlineView.selectedRowIndexes.count;
    BOOL isOK = (0 != count) && !self.isInFind;
    if (isOK) {
      menuItem.title = [NSString stringWithFormat:@"Delete %d item%@", (int)self.outlineView.selectedRowIndexes.count,
        1 < count ? @"s" : @""];
    } else {
      menuItem.title = @"Delete";
    }
    return isOK;
  }
  return NO;
}

#pragma mark - Service Menu

- (NSArray<NSURL *> *)selectedURLs {
  NSMutableArray<NSURL *> *urls = [NSMutableArray array];
  NSIndexSet *indexes = self.outlineView.selectedRowIndexes;
  for (NSUInteger i = indexes.firstIndex; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]) {
    DirItem *item = [self.outlineView itemAtRow:i];
    NSString *fullPath = [self.root stringByAppendingPathComponent:item.path];
    NSURL *url = [NSURL fileURLWithPath:fullPath];
    [urls addObject:url];
  }
  return urls;
}

- (void)copyToPasteboard:(NSPasteboard *)pboard {
  [pboard clearContents];
  [pboard writeObjects:[self selectedURLs]];
}


- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
  if ([returnType isEqual:NSPasteboardTypeURL] && 0 != self.outlineView.selectedRowIndexes.count) {
    return self;
  }
  return [[self nextResponder] validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
  if (([types containsObject:NSPasteboardTypeURL]) && 0 != self.outlineView.selectedRowIndexes.count) {
    [self copyToPasteboard:pboard];
    return YES;
  }
  return NO;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item {
  if (item == nil) {
    return self.dirItems.count;
  }
  DirItem *dirItem = item;
  return dirItem.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item {
  if (item == nil) {
    return self.dirItems[index];
  }
  DirItem *dirItem = item;
  return dirItem.children[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  DirItem *dirItem = item;
  return 0 != dirItem.children.count;
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item {
  DirItem *dirItem = item;
  NSTableCellView *view = [outlineView makeViewWithIdentifier:@"cell" owner:nil];
  BOOL isPartialPath = [NSUserDefaults.standardUserDefaults boolForKey:@"partialPath"];
  view.textField.stringValue = isPartialPath ? dirItem.path : [dirItem.path lastPathComponent];
  return view;
}

- (IBAction)doDoubleClick:(id)sender {
  DirItem *dirItem = [self.outlineView itemAtRow:self.outlineView.clickedRow];
  NSString *path = dirItem.path;
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSString *fullPath = [self.root stringByAppendingPathComponent:path];
  [ws selectFile:fullPath inFileViewerRootedAtPath:@""];
}

@end
