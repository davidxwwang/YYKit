//
//  MyPhotoGroupView.h
//  YYKitDemo
//
//  Created by david on 2016/12/5.
//  Copyright © 2016年 ibireme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface  MyPhotoItem: NSObject

@property (nonatomic , strong) UIView *thumbView;
@property (nonatomic , assign) CGSize largeImageSize;
@property (nonatomic , strong) NSURL *largeImageUrl;

@end

@interface MyPhotoGroupView : UIView

@property (nonatomic,strong)NSArray *itemsArray;
@property (nonatomic,assign)NSInteger *currentPage;

- (instancetype)initWithItemsArrays:(NSArray *)itemsArray;
- (void)presentImageView:(UIView *)fromView
            tocontainter:(UIView *)container
                animated:(BOOL)animate
                complete:(void (^)(void))complete;


@end
