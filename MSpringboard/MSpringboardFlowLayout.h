//
//  MSpringboardFlowLayout.h
//
//  Portions created by:
//
//  LXReorderableCollectionViewFlowLayout
//  https://github.com/lxcid/LXReorderableCollectionViewFlowLayout
//
//  HorizontalCollectionViewLayout
//  https://github.com/fattomhk/HorizontalCollectionViewLayout
//
//  Created by maichi on 2014/11/25.
//  Version:1.0
//
/**
 [how to use]
 
 #import MSpringboardFlowLayout.h"
 
 @interaface <UICollectionViewDelegate, MSpringboardFlowLayoutDatasource, MSpringboardFlowLayoutDelegate>
 
 // sample code
 
 MSpringboardFlowLayout *flowLayout = [[MSpringboardFlowLayout alloc] init];
 flowLayout.itemSize                = CGSizeMake(screenWidth/4, screenHeigth/3);
 
 listCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(SPACE, 0, screenWidth, screenHeigth)
 collectionViewLayout:flowLayout];
 listCollectionView.delegate        = self;
 listCollectionView.dataSource      = self;
 listCollectionView.backgroundColor = [UIColor clearColor];
 listCollectionView.pagingEnabled   = YES;
 listCollectionView.bounces         = YES;
 listCollectionView.showsHorizontalScrollIndicator = NO;
 [collectionView registerClass:[CustomCollectionViewCell class] forCellWithReuseIdentifier:@"COLLECTION_CELL_ID"];

 // カスタムセルの背景を透過にするならば、
 // self.opaque = NO;
 // にすること。
 
 // 必要であればドロップボックスをセット
 dropZoneView = [[UIView alloc] init];
 dropZoneView           = CGRectMake(0, screenHeigth - 50, screenWidth, 50);
 dropZoneView.backgroundColor = [UIColor grayColor];
 dropZoneView.alpha           = 0.7f;
 dropZoneVieww.hidden         = YES;
 [self addSubview:dropZoneView];
 
 flowLayout.dropZone = dropZoneView;
 
 
 #pragma mark - MSpringboardFlowLayoutDatasource
 
 // データ入れ替え
 - (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
 {
    Data *data = dataList[(int)fromIndexPath.item];
 
    [dataList removeObjectAtIndex:(int)fromIndexPath.item];
    [dataList insertObject:data atIndex:(int)toIndexPath.item];
    return;
 }
 
 
 // 入れ替えの可否
 - (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
 {
    return YES;
 }
 // 入れ替えの可否
 - (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath
 {
    return YES;
 }
 
 #pragma mark - MSpringboardFlowLayoutDelegate methods
 
 // will begin drag
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    dropZoneView.hidden = NO;
    return;
}

// did begin drag
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}

// will end drag
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}

// did end drag
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    dropZoneView.hidden = YES;
    return;
}

- (void)willDraggingItemIntodropZoneAtIndexPath:(NSIndexPath *)indexPath
{
    dropZoneView.backgroundColor = [UIColor yellowColor];
    return;
}

- (void)willDraggingItemOutofdropZoneAtIndexPath:(NSIndexPath *)indexPath
{
    dropZoneView.backgroundColor = [UIColor grayColor];
    return;
}

// ドロップボックスに入った作品を削除
- (void)didDropItemIntodropZoneAtIndexPath:(NSIndexPath *)indexPath
{
    [dataList removeObjectAtIndex:indexPath.item];
    dropZoneView.backgroundColor = [UIColor grayColor];
    [collectionView reloadData];
    return;
}
 
 // 現在のページ数を取得
 - (void)scrollViewDidScroll:(UIScrollView *)didScrollView
 {
    CGFloat pageWidth = collectionView.frame.size.width;
    if ((NSInteger)fmod(collectionView.contentOffset.x , pageWidth) == 0) {
    int currentPageCount = collectionView.contentOffset.x / pageWidth + 1;
    if (currentPageCount < 1) {
        currentPageCount = 1;
    }
    NSLog(@"currentPageCount=%d", currentPageCount);
    return;
 }
 
 */

#import <UIKit/UIKit.h>

@interface MSpringboardFlowLayout : UICollectionViewLayout <UIGestureRecognizerDelegate>

@property (assign, nonatomic) CGFloat scrollingSpeed;
@property (assign, nonatomic) UIEdgeInsets scrollingTriggerEdgeInsets;
@property (weak, nonatomic, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (weak, nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, assign) CGSize itemSize;
@property (weak, nonatomic) UIView *dropZone;

- (void)setUpGestureRecognizersOnCollectionView __attribute__((deprecated("Calls to setUpGestureRecognizersOnCollectionView method are not longer needed as setup are done automatically through KVO.")));

@end

@protocol MSpringboardFlowLayoutDatasource <UICollectionViewDataSource>

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;

@optional

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;

@end

@protocol MSpringboardFlowLayoutDelegate <UICollectionViewDelegateFlowLayout>
@optional

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)willDraggingItemIntodropZoneAtIndexPath:(NSIndexPath *)indexPath;
- (void)willDraggingItemOutofdropZoneAtIndexPath:(NSIndexPath *)indexPath;
- (void)didDropItemIntodropZoneAtIndexPath:(NSIndexPath *)indexPath;

@end