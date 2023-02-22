//  FindEmptyDir.h
//  findEmpty
//
//  Created by David Phillip Oster on 2/18/23.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DirItem;
@protocol FindEmptyDelegate;

/// Call -[findEmptyAt:] and it will call back its delegate with a list of empty directories.
/// Empty directories can no visible contents except other empty directories.
@interface FindEmptyDir : NSObject
@property(nonatomic, weak, nullable) id<FindEmptyDelegate> delegate;

/// Incremented each time this examines a new directory. 
@property(nonatomic, readonly) NSUInteger counter;


- (void)findEmptyAt:(NSString *)path;

@end

@protocol FindEmptyDelegate <NSObject>

- (void)findEmpty:(FindEmptyDir *)finder found:(nullable NSArray<DirItem *> *)found error:(nullable NSError *)error;

@end


NS_ASSUME_NONNULL_END
