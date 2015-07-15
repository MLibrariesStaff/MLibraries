//
//  MSpringboardFlowLayout.m
//
//  original sorce
//  LXReorderableCollectionViewFlowLayout.h
//
//  Created by maichi on 2014/11/25.
//  Copyright (c) 2014年 cybird. All rights reserved.
//

#import "MSpringboardFlowLayout.h"
#import <QuartzCore/QuartzCore.h>

#define LX_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

static NSString * const kLXScrollingDirectionKey = @"LXScrollingDirection";
static NSString * const kLXCollectionViewKeyPath = @"collectionView";

@interface UICollectionViewLayout (LXPaging)

- (CGPoint)LX_contentOffsetForPageIndex:(NSInteger)pageIndex;
- (NSInteger)LX_currentPageIndex;
- (NSInteger)LX_pageCount;

@end

@implementation UICollectionViewLayout (LXPaging)

- (NSInteger)LX_currentPageIndex
{
     return round(self.collectionView.contentOffset.x / self.collectionView.frame.size.width);
}

- (NSInteger)LX_pageCount
{
    return ceil(self.collectionViewContentSize.width / self.collectionView.frame.size.width);
}

- (CGPoint)LX_contentOffsetForPageIndex:(NSInteger)pageIndex
{
    return CGPointMake(self.collectionView.frame.size.width * pageIndex, 0);
}

@end

@interface UICollectionViewCell (MSpringboardFlowLayout)

- (UIImage *)LX_rasterizedImage;

@end

@implementation UICollectionViewCell (MSpringboardFlowLayout)

- (UIImage *)LX_rasterizedImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface MSpringboardFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) NSTimer *scrollingTimer;

@property (assign, nonatomic, readonly) id<MSpringboardFlowLayoutDatasource> dataSource;
@property (assign, nonatomic, readonly) id<MSpringboardFlowLayoutDelegate> delegate;

@end

@implementation MSpringboardFlowLayout
{
    BOOL _pageScrollingDisabled;
    NSTimer *panTimer;
    
    // horizontal
    NSInteger _cellCount;
    CGSize _boundsSize;
}

- (void)setDefaults
{
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView
{
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(handleLongPressGesture:)];
    longPressGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:longPressGestureRecognizer];
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
        }
    }
    _longPressGestureRecognizer = longPressGestureRecognizer;
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handlePanGesture:)];
    panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    _panGestureRecognizer = panGestureRecognizer;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self invalidatesScrollTimer];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<MSpringboardFlowLayoutDatasource>)dataSource
{
    return (id<MSpringboardFlowLayoutDatasource>)self.collectionView.dataSource;
}

- (id<MSpringboardFlowLayoutDelegate>)delegate
{
    return (id<MSpringboardFlowLayoutDelegate>)self.collectionView.delegate;
}

/**
 * 必要であればレイアウトを元に戻す
 */
- (void)invalidateLayoutIfNecessary
{
    const CGPoint point = [self.collectionView convertPoint:self.currentView.center fromView:self.collectionView.superview];
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:point];
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    
    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    
    [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView deleteItemsAtIndexPaths:@[ previousIndexPath ]];
            [strongSelf.collectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
        }
    } completion:nil];
}

- (void)invalidatesScrollTimer
{
    if (self.scrollingTimer.isValid) {
        [self.scrollingTimer invalidate];
    }
    self.scrollingTimer = nil;
}

- (void)scrollIfNecessary
{
    if (!self.currentView) return; // Prevent scrollToPageIndex to continue scrolling after the drag ended
    
    const CGPoint viewCenter = [self.collectionView convertPoint:self.currentView.center fromView:self.collectionView.superview];
    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
        [self scrollWithDirection:LXScrollingDirectionLeft];
    
    } else {
        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
            [self scrollWithDirection:LXScrollingDirectionRight];
        } else {
            [self invalidatesScrollTimer];
        }
    }
    return;
}

- (void)scrollToPreviousPage
{
    if (_pageScrollingDisabled) return;
    const NSInteger currentPage = [self LX_currentPageIndex];
    if (currentPage <= 0) return;
    const NSInteger newPage = currentPage - 1;
    [self scrollToPageIndex:newPage forward:NO];
}

- (void)scrollToNextPage
{
    if (_pageScrollingDisabled) return;
    const NSInteger currentPage = [self LX_currentPageIndex];
    const NSInteger pageCount = [self LX_pageCount];
    if (currentPage >= pageCount - 1) return;
    const NSInteger newPage = currentPage + 1;
    [self scrollToPageIndex:newPage forward:YES];
}

- (void)scrollToPageIndex:(NSInteger)pageIndex forward:(BOOL)forward
{
    const CGPoint offset = [self LX_contentOffsetForPageIndex:pageIndex];
    [self.collectionView setContentOffset:offset animated:YES];
    
    // Wait a little bit before changing page again
    _pageScrollingDisabled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ // Delay must be bigger than the contentOffset animation
        _pageScrollingDisabled = NO;
        [self scrollIfNecessary];
    });
}

- (void)scrollWithDirection:(LXScrollingDirection)direction
{
    if (self.collectionView.pagingEnabled) {
        switch(direction) {
            case LXScrollingDirectionUp:
            case LXScrollingDirectionLeft: {
                [self scrollToPreviousPage];
            } break;
            case LXScrollingDirectionDown:
            case LXScrollingDirectionRight: {
                [self scrollToNextPage];
            } break;
            default: {
                // Do nothing...
            } break;
        }
    } else {
        [self setupScrollTimerInDirection:direction];
    }
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction
{
    if (self.scrollingTimer.isValid) {
        LXScrollingDirection oldDirection = [self.scrollingTimer.userInfo[kLXScrollingDirectionKey] integerValue];
        
        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];
    
    self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                           target:self
                                                         selector:@selector(handleScroll:)
                                                         userInfo:@{ kLXScrollingDirectionKey : @(direction) }
                                                          repeats:YES];
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(NSTimer *)timer
{
    LXScrollingDirection direction = (LXScrollingDirection)[timer.userInfo[kLXScrollingDirectionKey] integerValue];
    if (direction == LXScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGFloat distance = self.scrollingSpeed / LX_FRAMES_PER_SECOND;
    CGPoint translation = CGPointZero;
    
    switch(direction) {
        case LXScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        case LXScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    self.collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
                ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            UIImageView *highlightedImageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            collectionViewCell.highlighted = NO;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            const CGPoint center = [self.collectionView.superview convertPoint:collectionViewCell.center fromView:self.collectionView];
            self.currentView.center = center;
            [self.collectionView.superview addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                     highlightedImageView.alpha = 0.0f;
                     imageView.alpha = 1.0f;
                 }
             }
             completion:^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     [highlightedImageView removeFromSuperview];
                     
                     if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                         [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                     }
                 }
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                
                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                
                __weak typeof(self) weakSelf = self;
                [UIView
                 animateWithDuration:0.3
                 delay:0.0
                 options:UIViewAnimationOptionBeginFromCurrentState
                 animations:^{
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                         const CGPoint center = [strongSelf.collectionView.superview convertPoint:layoutAttributes.center fromView:strongSelf.collectionView];
                         strongSelf.currentView.center = center;
                     }
                 }
                 completion:^(BOOL finished) {
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         [strongSelf.currentView removeFromSuperview];
                         strongSelf.currentView = nil;
                         [strongSelf invalidateLayout];
                         
                         if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                             [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                         }
                     }
                 }];
            }
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    int currentPage = (int)[self LX_currentPageIndex];
    CGRect dropZoneRect = CGRectMake(_dropZone.frame.origin.x + self.collectionView.frame.size.width*currentPage,
                                    _dropZone.frame.origin.y,
                                    _dropZone.frame.size.width,
                                    _dropZone.frame.size.height);
    CGPoint dragPoint = [gestureRecognizer locationInView:self.collectionView];

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:

        case UIGestureRecognizerStateChanged: {
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView.superview];
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            
            // スクロール枠にいたらタイマーを止めない
            if (self.currentView.center.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)
                || self.currentView.center.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
            
            // タイマーを停止
            } else if (panTimer.isValid == YES) {
                [panTimer invalidate];
            }
            
            // 一定時間以上ページング枠で停止していたらページング処理を実行
            if (panTimer.isValid == NO) {
                panTimer = [NSTimer scheduledTimerWithTimeInterval:0.7f
                                                            target:self
                                                          selector:@selector(panTimerAction:)
                                                          userInfo:nil
                                                           repeats:NO];
            }
            
            // ドロップ領域にドラッグした時
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            if (CGRectContainsPoint(dropZoneRect, CGPointMake(dragPoint.x, dragPoint.y))) {
                if ([self.delegate respondsToSelector:@selector(willDraggingItemIntodropZoneAtIndexPath:)]) {
                    [self.delegate willDraggingItemIntodropZoneAtIndexPath:currentIndexPath];
                }
                
            // ドロップ領域から外れた時
            } else {
                if ([self.delegate respondsToSelector:@selector(willDraggingItemOutofdropZoneAtIndexPath:)]) {
                    [self.delegate willDraggingItemOutofdropZoneAtIndexPath:currentIndexPath];
                }
            }
            
            [self invalidateLayoutIfNecessary];
            
        } break;
        
        case UIGestureRecognizerStateEnded: {
            // タイマーを停止
            if (panTimer.isValid == YES) {
                [panTimer invalidate];
            }
            
            // ドロップ領域にドロップした時
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            if (CGRectContainsPoint(dropZoneRect, dragPoint)) {
                self.currentView.hidden = YES;
                if ([self.delegate respondsToSelector:@selector(didDropItemIntodropZoneAtIndexPath:)]) {
                    [self.delegate didDropItemIntodropZoneAtIndexPath:currentIndexPath];
                }
            }
            
        } break;
        
        default: {
            [self invalidatesScrollTimer];
        } break;
    }
}

-(void)panTimerAction:(NSTimer *)timer
{
    // タイマーを停止してページングを判定
    if (panTimer.isValid == YES) {
        [panTimer invalidate];
        [self scrollIfNecessary];
    }
    return;
}

#pragma mark - UICollectionViewLayout overridden methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:_cellCount];
    
    for (NSUInteger i=0; i<_cellCount; ++i) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attr = [self _layoutForAttributesForCellAtIndexPath:indexPath];
        switch (attr.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:attr];
            } break;
            default: {
                // Do nothing...
            } break;
        }
        
        [allAttributes addObject:attr];
    }
    
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [self _layoutForAttributesForCellAtIndexPath:indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes*)_layoutForAttributesForCellAtIndexPath:(NSIndexPath*)indexPath
{
    // Here we have the magic of the layout.
    
    NSInteger row = indexPath.row;
    
    CGRect bounds = self.collectionView.bounds;
    CGSize itemSize = self.itemSize;
    
    // Get some info:
    NSInteger verticalItemsCount = (NSInteger)floorf(bounds.size.height / itemSize.height);
    NSInteger horizontalItemsCount = (NSInteger)floorf(bounds.size.width / itemSize.width);
    NSInteger itemsPerPage = verticalItemsCount * horizontalItemsCount;
    
    // Compute the column & row position, as well as the page of the cell.
    NSInteger columnPosition = row%horizontalItemsCount;
    NSInteger rowPosition = (row/horizontalItemsCount)%verticalItemsCount;
    NSInteger itemPage = floorf(row/itemsPerPage);
    
    // Creating an empty attribute
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGRect frame = CGRectZero;
    
    // And finally, we assign the positions of the cells
    frame.origin.x = itemPage * bounds.size.width + columnPosition * itemSize.width;
    frame.origin.y = rowPosition * itemSize.height;
    frame.size = _itemSize;
    
    attr.frame = frame;
    
    return attr;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kLXCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
        }
    }
}


#pragma mark Starting from 0.1.0
- (void)setUpGestureRecognizersOnCollectionView
{
    // Do nothing...
}

#pragma mark - HorizontalCollectionViewLayout

- (void)prepareLayout
{
    _cellCount = [self.collectionView numberOfItemsInSection:0];
    _boundsSize = self.collectionView.bounds.size;
}

- (CGSize)collectionViewContentSize
{
    NSInteger verticalItemsCount = (NSInteger)floorf(_boundsSize.height / _itemSize.height);
    NSInteger horizontalItemsCount = (NSInteger)floorf(_boundsSize.width / _itemSize.width);
    
    NSInteger itemsPerPage = verticalItemsCount * horizontalItemsCount;
    NSInteger numberOfItems = _cellCount;
    NSInteger numberOfPages = (NSInteger)ceilf((CGFloat)numberOfItems / (CGFloat)itemsPerPage);
    
    CGSize size = _boundsSize;
    size.width = numberOfPages * _boundsSize.width;
    
    return size;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    // We should do some math here, but we are lazy.
    return YES;
}

- (void)setItemSize:(CGSize)itemSize
{
    _itemSize = itemSize;
    [self invalidateLayout];
}

@end
