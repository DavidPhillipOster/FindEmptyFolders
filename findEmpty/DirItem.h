//  DirItem.h
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Represents an empty folder
@interface DirItem : NSObject

/// partial file path (root prefix is elsewhere)
@property NSString *path;

/// Weak reference to Parent. OutlineView delete needs this.
@property(nullable, weak) DirItem *parent;

/// nill if no children.
@property(nullable) NSMutableArray<DirItem *> *children;

+ (instancetype)dirItemWithPath:(NSString *)path;

+ (void)sortTree:(NSMutableArray<DirItem *> *)dirItems isPartialPath:(BOOL)isPartialPath;

@end


NS_ASSUME_NONNULL_END
