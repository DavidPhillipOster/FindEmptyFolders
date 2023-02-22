//  DirItem.m
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.//

#import "DirItem.h"

@implementation DirItem

+ (instancetype)dirItemWithPath:(NSString *)path {
  DirItem *result = [[DirItem alloc] init];
  result.path = path;
  return result;
}

- (NSString *)description {
  NSMutableArray *a = [NSMutableArray array];
  [a addObject:[NSString stringWithFormat:@"<%p %@ %@", self, [self class], self.path]];
  if (self.children) {
    [a addObject:@"["];
    BOOL first = YES;
    for (DirItem *child in self.children) {
      if (!first) {
        [a addObject:@", "];
      } else {
        first = NO;
      }
      [a addObject:child];
    }
    [a addObject:@"]"];
  }
  [a addObject:@">"];
  return [a componentsJoinedByString:@""];
}

- (NSUInteger)hash {
  return [self.path hash];
}

- (BOOL)isEqual:(id)object {
  DirItem *other = object;
  return [self class] == [other class] && [self.path isEqual:other.class] && self.children.count == other.children.count &&
    (self.children.count ? [self.children isEqual:other.children] : YES);
}

/// sort by last component of path.
///
/// Note: sort of children is stable, filename vs partial path.
+ (void)sortTree:(NSMutableArray<DirItem *> *)dirItems isPartialPath:(BOOL)isPartialPath {
  [dirItems sortUsingComparator:^(id obj1, id obj2) {
      DirItem *d1 = obj1;
      DirItem *d2 = obj2;
      NSComparisonResult result = isPartialPath ? NSOrderedSame :
          [[d1.path lastPathComponent] caseInsensitiveCompare:[d2.path lastPathComponent]];
      if (NSOrderedSame == result) {
        result = [d1.path caseInsensitiveCompare:d2.path];
        if (NSOrderedSame == result) {
          result = [d1.path compare:d2.path];
        }
      }
      return result;
    }
  ];
}

@end
