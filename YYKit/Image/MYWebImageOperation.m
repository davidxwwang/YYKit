//
//  MYWebImageOperation.m
//  YYKitDemo
//
//  Created by alisports on 2017/1/23.
//  Copyright © 2017年 ibireme. All rights reserved.
//

#import "MYWebImageOperation.h"

@interface MYWebImageOperation ()

@property(strong,nonatomic)NSURLRequest *request;
@property(strong,nonatomic)NSURLSession *session;
@property(strong,nonatomic)NSURLSessionTask *sessionTask;

@property(assign,nonatomic,getter=isCancelled)BOOL cancelled;
@property(assign,nonatomic,getter=isFinished)BOOL  finished;
@property(assign,nonatomic,getter=isExecuting)BOOL executing;


@end
@implementation MYWebImageOperation


- (void)start
{
    
}

- (instancetype)initWithRequest:(NSURLRequest *)request
                        options:(YYWebImageOptions)options
                          cache:(nullable YYImageCache *)cache
                       cacheKey:(nullable NSString *)cacheKey
                       progress:(nullable YYWebImageProgressBlock)progress
                      transform:(nullable YYWebImageTransformBlock)transform
                     completion:(nullable YYWebImageCompletionBlock)completion
{
    return nil;
}

@end
