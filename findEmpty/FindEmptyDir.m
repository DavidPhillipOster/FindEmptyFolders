//  FindEmptyDir.m
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.

#import "FindEmptyDir.h"

#import "DirItem.h"

@interface FindEmptyDir ()
@property(nonatomic, readwrite) NSUInteger counter;
@end

@implementation FindEmptyDir

- (BOOL)isApp:(NSString *)fullpath contents:(NSArray *)contents {
  BOOL isApp = [[fullpath lastPathComponent] isEqual:@"Contents"] &&
    [contents containsObject:@"Info.plist"] &&
    [[fullpath stringByDeletingLastPathComponent] hasSuffix:@".app"];
  return isApp;
}

- (void)findEmptyAt:(NSString *)rootPath {
// put contents of the initial directory on the 'explore' array. loop until explore is empty:
// the the last item is an empty directory, add it to 'paths' else if non-empty, put its contents on the 'explore' array
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;
  NSMutableArray *paths = [NSMutableArray array];
  NSMutableArray *explore = [NSMutableArray array];
  self.counter = 0;
  NSArray *dir = [fm contentsOfDirectoryAtPath:rootPath error:&error];
  [explore addObjectsFromArray:dir];
  while (explore.count) {
    @autoreleasepool {
      NSString *item = explore.lastObject;
      [explore removeLastObject];
      self.counter += 1;
      if (![item hasPrefix:@"."]) {
        NSString *fullpath = [rootPath stringByAppendingPathComponent:item];
        NSDictionary *attr = [fm attributesOfItemAtPath:fullpath error:NULL];
        if ([NSFileTypeDirectory isEqual:attr[NSFileType]]) {
          NSMutableArray *dir = [[fm contentsOfDirectoryAtPath:fullpath error:&error] mutableCopy];
          [dir removeObjectsAtIndexes:[dir indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return [obj hasPrefix:@"."];
          }]];
          if (dir.count) {
            if (![self isApp:fullpath contents:dir]) {
              NSMutableArray *partial = [NSMutableArray array];
              for (NSString *leaf in dir) {
                [partial addObject:[item stringByAppendingPathComponent:leaf]];
              }
              [explore addObjectsFromArray:partial];
            }
          } else {
            [paths addObject:item];
          }
        }
      }
    }
  }

  NSMutableArray<DirItem *> *dirItems = [self dirItemsWithPaths:paths];
  dirItems = [self buildTree:dirItems rootPath:rootPath];
  [DirItem sortTree:dirItems isPartialPath:[NSUserDefaults.standardUserDefaults boolForKey:@"partialPath"]];
  [self.delegate findEmpty:self found:dirItems error:error];
}

/// @param paths - an array of partial path strings
/// @return - an equivalent array of leaf DirItems.
- (NSMutableArray<DirItem *> *)dirItemsWithPaths:(NSArray *)paths {
  NSMutableArray<DirItem *> *dirItems = [NSMutableArray array];
  for (NSString *leaf in paths) {
    [dirItems addObject:[DirItem dirItemWithPath:leaf]];
  }
  return dirItems;
}

// a dir is empty if it contains only dot files and items that are in dirItems. If it is empty, than return true by returning the
// new empty dir.
- (DirItem *)isEmptyDir:(NSString *)item subDirs:(NSArray<DirItem *> *)dirItems rootPath:(NSString *)rootPath {
  NSString *fullPath = [rootPath stringByAppendingPathComponent:item];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error;
  NSMutableArray<DirItem *> *emptyChildren = [NSMutableArray array];
  NSArray *dir = [fm contentsOfDirectoryAtPath:fullPath error:&error];
  for (NSString *child in dir) {
    if (![child hasPrefix:@"."]) {
      NSString *childPath = [item stringByAppendingPathComponent:child];
      NSUInteger index = [dirItems indexOfObjectPassingTest:^(DirItem *obj, NSUInteger idx, BOOL *stop) {
          BOOL isMatch = [obj.path isEqual:childPath];
          if (isMatch) {
            *stop = YES;
          }
          return isMatch;
      }];
      if (NSNotFound == index) {
        return nil;
      } else {
        [emptyChildren addObject:dirItems[index]];
      }
    }
  }
  DirItem *result = nil;
  if (emptyChildren.count) {
    result = [DirItem dirItemWithPath:item];
    result.children = emptyChildren;
    for  (DirItem *child in emptyChildren) {
      child.parent = result;
    }
  }
  return result;
}


/// a directory is empty if all its childen are empty.
/// @param dirItems - array of leaf empty directories
/// @param rootPath - prefix to make dirItem paths absolute paths.
- (NSMutableArray<DirItem *> *)buildTree:(NSMutableArray<DirItem *> *)dirItems rootPath:(NSString *)rootPath {
  NSMutableSet<NSString *> *explore = [NSMutableSet set];
  for (DirItem *item in dirItems) {
    NSString *parent = [item.path stringByDeletingLastPathComponent];
    if (parent.length) {
      [explore addObject:parent];
    }
  }
  while (explore.count) {
    NSString *item = explore.anyObject;
    [explore removeObject:item];
    self.counter += 1;
    DirItem *parent = [self isEmptyDir:item subDirs:dirItems rootPath:rootPath];
    if (parent) {
      for (DirItem *child in parent.children) {
        [dirItems removeObject:child];
      }
      [dirItems addObject:parent];
      NSString *parent1 = [parent.path stringByDeletingLastPathComponent];
      if (parent1.length) {
        [explore addObject:parent1];
      }
    }
  }
  return dirItems;
}


@end
