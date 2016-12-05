//
//  MyPhotoGroupView.m
//  YYKitDemo
//
//  Created by david on 2016/12/5.
//  Copyright © 2016年 ibireme. All rights reserved.
//
#import "UIView+YYAdd.h"
#import "CALayer+YYAdd.h"
#import "MyPhotoGroupView.h"
#import "YYAnimatedImageView.h"
#import "UIImageView+YYWebImage.h"

#define progressLayerwidth 40

@interface MyPhotoItem()

@property (nonatomic , readonly) UIImage *thumbImage;

@end

@implementation MyPhotoItem
@end


@interface MyPhotoCell : UIScrollView<UIScrollViewDelegate>

@property (nonatomic, assign) NSInteger page;
@property (nonatomic,strong) MyPhotoItem *photoItem;
@property (nonatomic,strong) CAShapeLayer *progressLayer;
@property (nonatomic,strong) YYAnimatedImageView *imageView;
@property (nonatomic,strong) UIView *imageContainerView;

@end

@implementation MyPhotoCell

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;
    
    self.maximumZoomScale = 3.0f;
    
    _imageContainerView = [UIView new];
    _imageContainerView.clipsToBounds = YES;
    [self addSubview:_imageContainerView];
    
    _imageView = [YYAnimatedImageView new];
    _imageView.clipsToBounds = YES;
    [_imageContainerView addSubview:_imageView];
    
    _progressLayer = [CAShapeLayer new];
    _progressLayer.size = CGSizeMake(progressLayerwidth, progressLayerwidth);
    _progressLayer.backgroundColor = (__bridge CGColorRef _Nullable)([UIColor redColor]);
    _progressLayer.hidden = YES;
    [self.layer addSublayer:_progressLayer];
    
    return self;

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _progressLayer.center = CGPointMake(self.width /2 , self.height /2);
}

- (void)setPhotoItem:(MyPhotoItem *)photoItem
{
    _photoItem = photoItem;
    
    __weak __typeof(self) weakSelf = self;
    [_imageView setImageWithURL:_photoItem.largeImageUrl placeholder:nil options:kNilOptions progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
        CGFloat progress = receivedSize / expectedSize;
        progress = progress < 0.01 ? 0.01 : progress > 1.0 ? 1.0 : progress;
        
        weakSelf.progressLayer.hidden = NO;
        weakSelf.progressLayer.strokeEnd = progress;
        
    } transform:nil completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error){
        
        weakSelf.progressLayer.hidden = YES;
        [weakSelf resizeSubViews];
    
        }];
}

- (void)resizeSubViews
{
    _imageContainerView.origin = CGPointZero;
    _imageContainerView.width = self.width;
    _imageContainerView.height = self.height;
    
    _imageView.frame = _imageContainerView.bounds;
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
    UIView *subview = _imageContainerView;
    subview.center = CGPointMake(scrollView.contentSize.width /2, scrollView.contentSize.height /2);
    
}

@end

@interface MyPhotoGroupView ()<UIScrollViewDelegate>

@property (nonatomic,weak)UIView *fromView;
@property (nonatomic,weak)UIView *containerView;

@property (nonatomic,strong)UIView *contentView;
@property (nonatomic,strong)UIScrollView *scrollView;

@property (nonatomic,strong)UIPageControl *pager;
@property (nonatomic,assign)NSInteger pagerCurrentpage;

@property (nonatomic,strong)NSMutableArray *cells;



@end


@implementation MyPhotoGroupView

- (instancetype)initWithItemsArrays:(NSArray *)itemsArray
{
    self = [super init];
    if (itemsArray.count == 0) return nil;
    _itemsArray = [itemsArray copy];
    _cells = [[NSMutableArray alloc]init];
    
    _contentView = [UIView new];
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _scrollView = [UIScrollView new];
    _scrollView.frame = CGRectMake(0 / 2, 0, self.width + 0, self.height);
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.alwaysBounceHorizontal = _itemsArray.count > 1;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches = NO;
    _scrollView.canCancelContentTouches = YES;
    
    _pager = [[UIPageControl alloc] init];
    _pager.hidesForSinglePage = YES;
    _pager.center = CGPointMake(self.width/2, self.height -18);
    _pager.height = 10;
    _pager.width = self.width - 50;
    _pager.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    
    [self addSubview:_contentView];
    [_contentView addSubview:_scrollView];
    [_contentView addSubview:_pager];
    
    return self;
    
}

- (void)presentImageView:(UIView *)fromView
            toContainter:(UIView *)container
                animated:(BOOL)animate
                complete:(void (^)(void))complete
{
    if (!container) return;
    
    _fromView = fromView;
    _containerView = container;
    
    self.pager.numberOfPages = _itemsArray.count;
    self.pager.currentPage = 0;
    
    self.size = _contentView.size;
    
    [_contentView addSubview:self];
    
    _scrollView.contentSize = CGSizeMake(_scrollView.width *_itemsArray.count, _scrollView.height);
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.width *_pager.currentPage, 0, _scrollView.width, _scrollView.height) animated:YES];
    
    [self scrollViewDidScroll:_scrollView];
    
    

}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCellsForReuse];
    
    CGFloat floatPage = _scrollView.contentOffset.x / _scrollView.width;
    NSInteger page = _scrollView.contentOffset.x / _scrollView.width;
    
    for (NSInteger i = page - 1 ; i <= page + 1; i ++) {
        if (i >=0 && i< _itemsArray.count) {
            MyPhotoCell *cell = [self cellForpage:page];
            if (!cell) {
                MyPhotoCell *cell = [self dequeueReusableCell];
                cell.page = i;
                cell.left = self.width * i;
                cell.photoItem = _itemsArray[i];
                [_scrollView addSubview:cell];
                
            }
            else{
                 cell.photoItem = _itemsArray[i];
            
            }
            
        }
    }
}

- (void)updateCellsForReuse
{
    for (MyPhotoCell *cell in _cells) {
        if (cell.superview) {
            if ((cell.left > _scrollView.contentOffset.x + 2 * self.width ) || cell.right < _scrollView.contentOffset.x - self.width) {
                [cell removeFromSuperview];
                cell.page = -1;
            }
        }
    }
}

/// dequeue a reusable cell
- (MyPhotoCell *)dequeueReusableCell {
    MyPhotoCell *cell = nil;
    for (cell in _cells) {
        if (!cell.superview) {
            return cell;
        }
    }
    
    cell = [MyPhotoCell new];
    cell.frame = self.bounds;
    cell.imageContainerView.frame = self.bounds;
    cell.imageView.frame = cell.bounds;
    cell.page = -1;
   // cell.item = nil;
    [_cells addObject:cell];
    return cell;
}


- (MyPhotoCell *)cellForpage:(NSInteger)page
{
    for (MyPhotoCell *cell in _cells) {
        if (cell.page == page) {
            return cell;
        }
    }
    return nil;
}



@end






























