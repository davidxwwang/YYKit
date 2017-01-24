//
//  MYWebImageOperation.h
//  YYKitDemo
//
//  Created by alisports on 2017/1/23.
//  Copyright © 2017年 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYKit.h"
//#import <YYKit/YYWebImageManager.h>


@protocol  MYWebImageOperation<NSObject>

- (instancetype)initWithRequest:(NSURLRequest *)request
                        options:(YYWebImageOptions)options
                          cache:(nullable YYImageCache *)cache
                       cacheKey:(nullable NSString *)cacheKey
                       progress:(nullable YYWebImageProgressBlock)progress
                      transform:(nullable YYWebImageTransformBlock)transform
                     completion:(nullable YYWebImageCompletionBlock)completion;

@end

@interface MYWebImageOperation : NSOperation<MYWebImageOperation>

@end
