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
#import "UIImage+YYAdd.h"

#define progressLayerwidth 40

@interface MyPhotoItem()

@property (nonatomic , readonly) UIImage *thumbImage;

@end

@implementation MyPhotoItem

- (UIImage *)thumbImage {
    if ([_thumbView respondsToSelector:@selector(image)]) {
        return ((UIImageView *)_thumbView).image;
    }
    return nil;
}

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
    self.delegate = self;
    _imageContainerView = [UIView new];
    _imageContainerView.clipsToBounds = YES;
    [self addSubview:_imageContainerView];
    
    _imageView = [YYAnimatedImageView new];
    _imageView.clipsToBounds = YES;
    [_imageContainerView addSubview:_imageView];
    
    _progressLayer = [CAShapeLayer new];
    _progressLayer.size = CGSizeMake(progressLayerwidth, progressLayerwidth);
    _progressLayer.backgroundColor =[UIColor colorWithWhite:0.000 alpha:0.500].CGColor;
    _progressLayer.hidden = NO;
    _progressLayer.cornerRadius = progressLayerwidth/2;

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(_progressLayer.bounds, 7, 7) cornerRadius:(40 / 2 - 7)];
    _progressLayer.path = path.CGPath;
    _progressLayer.fillColor = [UIColor redColor].CGColor;
    _progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    _progressLayer.lineWidth = 4;
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;

    
    [self.layer addSublayer:_progressLayer];
    SEL sel = @selector(dismiss);
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
    [_imageView setImageWithURL:photoItem.largeImageURL placeholder:photoItem.thumbImage options:kNilOptions progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
        CGFloat progress = receivedSize / expectedSize;
        progress = progress < 0.01 ? 0.01 : progress > 1.0 ? 1.0 : progress;
        
        weakSelf.progressLayer.hidden = YES;
        weakSelf.progressLayer.strokeEnd = progress;
        
    } transform:nil completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error){
        
        weakSelf.progressLayer.hidden = NO;
        [weakSelf resizeSubViews];
    
        }];
    
    [self resizeSubViews];
}

- (void)resizeSubViews
{
    _imageContainerView.origin = CGPointZero;
    _imageContainerView.width = self.width;
    _imageContainerView.height = self.height;
     CGSize xx = _imageView.image.size;
//    _imageView.frame = _imageContainerView.bounds;
//    
//    _imageView.frame = CGRectMake(_imageContainerView.center.x, _imageContainerView.bounds.size.height/2, MIN(xx.width, xx.height), MIN(xx.width, xx.height));
    
    UIImage *image = _imageView.image;
    if (image.size.height / image.size.width > self.height / self.width) {
        _imageContainerView.height = floor(image.size.height / (image.size.width / self.width));
    } else {
        CGFloat height = image.size.height / image.size.width * self.width;
        if (height < 1 || isnan(height)) height = self.height;
        height = floor(height);
        _imageContainerView.height = height;
        _imageContainerView.centerY = self.height / 2;
    }
    if (_imageContainerView.height > self.height && _imageContainerView.height - self.height <= 1) {
        _imageContainerView.height = self.height;
    }
    self.contentSize = CGSizeMake(self.width, MAX(_imageContainerView.height, self.height));
    [self scrollRectToVisible:self.bounds animated:NO];
    
    if (_imageContainerView.height <= self.height) {
        self.alwaysBounceVertical = NO;
    } else {
        self.alwaysBounceVertical = YES;
    }

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


@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint panGestureBeginPoint;

@property (nonatomic, strong) UIImageView *blurBackground;


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
    
    _blurBackground = [UIImageView new];
    _blurBackground.frame = self.bounds;
    _blurBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _blurBackground.image =  [UIImage imageWithColor:[UIColor blackColor]];
    
    [self addSubview:_blurBackground];
    [self addSubview:_contentView];
    [_contentView addSubview:_scrollView];
    [_contentView addSubview:_pager];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tap2.delegate = self;
    tap2.numberOfTapsRequired = 2;
    [tap requireGestureRecognizerToFail: tap2];
    [self addGestureRecognizer:tap2];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    _panGesture = pan;
    
    
    return self;
    
}

- (void)pan:(UIPanGestureRecognizer *)g
{
    switch (g.state) {
        case UIGestureRecognizerStateBegan:{
            _panGestureBeginPoint = [g locationInView:self];
        }break;
        case UIGestureRecognizerStateChanged:{
            if (_panGestureBeginPoint.x == 0 && _panGestureBeginPoint.y == 0) return;
            CGPoint changedPoint = [g locationInView:self];
            CGFloat delter = changedPoint.y - _panGestureBeginPoint.y;
            _scrollView.top = delter;
            
            _blurBackground.alpha =fabs(delter)/100;
            
            
            
        }break;
        case UIGestureRecognizerStateEnded:{
            CGPoint p = [g locationInView:self];
            if (fabs(p.y - _panGestureBeginPoint.y) > 100) {
                BOOL movetoTop = (p.y - _panGestureBeginPoint.y) < 0 ;
                
                [UIView animateWithDuration:0.3 animations:^{
                    _blurBackground.alpha = 0;
                    if (movetoTop) {
                         _scrollView.bottom = 0;
                    }
                    else{
                        _scrollView.top = self.height;
                    }
                } completion:^(BOOL finished) {
                     [self removeFromSuperview];
                }];
            }
            else{
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _blurBackground.alpha = 1;
                    _scrollView.top = 0;
                } completion:^(BOOL finished) {
                    _scrollView.top = 0;
                }];
                
                
            }
        }break;
        case UIGestureRecognizerStateCancelled:{
            _scrollView.top = 0;
        }break;

        default:
            break;
    }

}

- (void)doubleTap:(UITapGestureRecognizer *)g
{
    MyPhotoCell *cell = [self cellForpage:self.currentPage];
    if (cell) {
        if (cell.zoomScale >1.0) {
            [cell setZoomScale:1.0 animated:YES];
        }
        else{
            CGPoint point = [g locationInView:cell.imageView];
            CGFloat newZoomScale = cell.maximumZoomScale;
            CGFloat xsize = self.width / newZoomScale;
            CGFloat ysize = self.height / newZoomScale;
            [cell zoomToRect:CGRectMake(point.x - xsize/2, point.y -ysize/2, xsize, ysize) animated:YES];
        
        }
        
    }
}

- (void)dismiss
{
    [self dismissAnimated:YES completion:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
    
    [UIView animateWithDuration:animated? 15 : 0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell];
//        CGFloat scale = fromFrame.size.width / cell.imageContainerView.width * cell.zoomScale;
//        CGFloat height = fromFrame.size.height / fromFrame.size.width * cell.imageContainerView.width;
//        if (isnan(height)) height = cell.imageContainerView.height;
//        
//        cell.imageContainerView.height = height;
//        cell.imageContainerView.center = CGPointMake(CGRectGetMidX(fromFrame), CGRectGetMinY(fromFrame));
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        
        if (completion) {
            completion();
        }
        
    }];
   
    
}

- (void)presentImageView:(UIView *)fromView
            tocontainter:(UIView *)container
                animated:(BOOL)animate
                complete:(void (^)(void))complete;

{
    if (!container) return;
    
    _fromView = fromView;
    _containerView = container;
    
    self.pager.numberOfPages = _itemsArray.count;
    self.pager.currentPage = 0;
    
    //self.origin = CGPointMake(0, _containerView.size.height);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        //self.origin = CGPointMake(0, _containerView.size.height);
       
        
    } completion:^(BOOL finished) {
        self.size = _containerView.size;
        [_containerView addSubview:self];
        _scrollView.contentSize = CGSizeMake(_scrollView.width *_itemsArray.count, _scrollView.height);
        [_scrollView scrollRectToVisible:CGRectMake(_scrollView.width *_pager.currentPage, 0, _scrollView.width, _scrollView.height) animated:YES];
        [self scrollViewDidScroll:_scrollView];
        
    }];

}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCellsForReuse];
    
    CGFloat floatPage = _scrollView.contentOffset.x / _scrollView.width;
    NSInteger page = floatPage + 0.5;
    page = page < 0 ? 0 : page >= _itemsArray.count ? (int)_itemsArray.count - 1 : page;
   // NSInteger page = _scrollView.contentOffset.x / _scrollView.width;
    
    NSLog(@"--->_scrollView.contentOffset.x = %f",_scrollView.contentOffset.x);
    
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
    
    NSInteger intPage = floatPage + 0.5;
    intPage = intPage < 0 ? 0 : intPage >= _itemsArray.count ? (int)_itemsArray.count - 1 : intPage;
    _pager.currentPage = intPage;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        _pager.alpha = 1;
    }completion:^(BOOL finish) {
    }];

    
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






























