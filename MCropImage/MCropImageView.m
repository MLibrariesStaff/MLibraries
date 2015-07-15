//
//  MCropImageView.m
//
//  Created by saimushi on 2014/10/08.
//

#import "MCropImageView.h"

// 切り取りイメージのサイズと表示上のサイズの倍率
#define TRIM_SHOW_SCALE 1.0f

@implementation MCropImageView
{
    MEditImageView *editImageView;
    MCropCompletionHandler completionHandler;
    UIView *editImageViewOverViewTop;
    UIView *editImageViewOverViewBottom;
    UIView *editImageViewOverViewLeft;
    UIView *editImageViewOverViewRight;
}

/**
 * 色枠ビューで画像を編集
 */
- (id)initWithFrame:(CGRect)frame
           cropSize:(CGSize)cropSize
          lineColor:(UIColor *)lineColor
            bgColor:(UIColor *)bgColor
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        editImageView = [[MEditImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        editImageView.delegate        = self;
        editImageView.editImageSize   = cropSize;
        editImageView.backgroundColor = bgColor;
        editImageView.editable        = YES;
        editImageView.defaultImage    = NO;
        // ピンチで拡大できる最大倍率
        editImageView.scaleMax = 4.0;
        // 回転フィッティングレンジ
        editImageView.turnFitRange = 5.0;
        // 切り取りイメージのサイズと切り取りイメージの表示上のサイズの倍率
        editImageView.rectangleTrimAndFittingScale = TRIM_SHOW_SCALE;
        [self addSubview:editImageView];
        
        // EditImageViewの外枠
        UIView *rangeView = [[UIView alloc] init];
        rangeView.frame = CGRectMake((self.frame.size.width - cropSize.width)/2, (self.frame.size.height - cropSize.height)/2,
                                     cropSize.width, cropSize.height);
        rangeView.backgroundColor        = [UIColor clearColor];
        rangeView.layer.borderWidth      = 2.0f;
        rangeView.layer.borderColor      = lineColor.CGColor;
        rangeView.userInteractionEnabled = NO;
        [self addSubview:rangeView];
    }
    return self;
}

/**
 * 半透明黒枠ビューで画像を編集
 */
- (id)initWithFrame:(CGRect)frame
           cropSize:(CGSize)cropSize
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        editImageView                 = [[MEditImageView alloc] initWithFrame:CGRectMake(0, 0,
                                                                                         self.frame.size.width, self.frame.size.height)];
        editImageView.delegate        = self;
        editImageView.editImageSize   = cropSize;
        editImageView.backgroundColor = [UIColor blackColor];
        editImageView.editable        = YES;
        editImageView.defaultImage    = NO;
        // ピンチで拡大できる最大倍率
        editImageView.scaleMax = 3.0;
        // 回転フィッティングレンジ
        editImageView.turnFitRange = 5.0;
        // 切り取りイメージのサイズと切り取りイメージの表示上のサイズの倍率
        editImageView.rectangleTrimAndFittingScale = TRIM_SHOW_SCALE;
        [self addSubview:editImageView];
        
        // EditImageViewの半透明黒枠
        editImageViewOverViewTop = [[UIView alloc] init];
        editImageViewOverViewTop.frame = CGRectMake(0, 0, self.frame.size.width, (self.frame.size.height - cropSize.height)/2.0);
        editImageViewOverViewTop.backgroundColor = [UIColor blackColor];
        editImageViewOverViewTop.alpha = 0.5;
        editImageViewOverViewTop.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewTop];
        
        editImageViewOverViewBottom = [[UIView alloc] init];
        editImageViewOverViewBottom.frame = CGRectMake(0, editImageViewOverViewTop.frame.origin.y + editImageViewOverViewTop.frame.size.height + cropSize.height, editImageViewOverViewTop.frame.size.width, editImageViewOverViewTop.frame.size.height);
        editImageViewOverViewBottom.backgroundColor = [UIColor blackColor];
        editImageViewOverViewBottom.alpha = 0.5;
        editImageViewOverViewBottom.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewBottom];
        
        editImageViewOverViewLeft = [[UIView alloc] init];
        editImageViewOverViewLeft.frame = CGRectMake(0, editImageViewOverViewTop.frame.origin.y + editImageViewOverViewTop.frame.size.height, (self.frame.size.width - cropSize.width) / 2, self.frame.size.height - (editImageViewOverViewTop.frame.size.height*2));
        editImageViewOverViewLeft.backgroundColor = [UIColor blackColor];
        editImageViewOverViewLeft.alpha = 0.5;
        editImageViewOverViewLeft.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewLeft];
        
        editImageViewOverViewRight = [[UIView alloc] init];
        editImageViewOverViewRight.frame = CGRectMake(self.frame.size.width - editImageViewOverViewLeft.frame.size.width, editImageViewOverViewLeft.frame.origin.y, editImageViewOverViewLeft.frame.size.width, editImageViewOverViewLeft.frame.size.height);
        editImageViewOverViewRight.backgroundColor = [UIColor blackColor];
        editImageViewOverViewRight.alpha = 0.5;
        editImageViewOverViewRight.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewRight];
    }
    return self;
}

/**
 * 画像をセット
 */
- (void)setImage:(UIImage *)image
{
    editImageView.image = image;
    return;
}

/**
 * 編集した画像を返す
 */
- (UIImage *)getCroppedImage
{
    return editImageView.lastEdittingImage;
}


- (id)initWithFrame:(CGRect)frame :(UIImage *)argImage :(int)argCropWith :(int)argCropHeight :(MCropCompletionHandler)argCompletionHandler;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        editImageView = [[MEditImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        editImageView.delegate = self;
        editImageView.editImageSize = CGSizeMake(argCropWith, argCropHeight);
        editImageView.backgroundColor = [UIColor blackColor];
        editImageView.editable = YES;
        editImageView.defaultImage = NO;
        // ピンチで拡大できる最大倍率
        editImageView.scaleMax = 3.0;
        // 回転フィッティングレンジ
        editImageView.turnFitRange = 5.0;
        // 切り取りイメージのサイズと切り取りイメージの表示上のサイズの倍率
        editImageView.rectangleTrimAndFittingScale = TRIM_SHOW_SCALE;
        editImageView.image = argImage;
        [self addSubview:editImageView];

        // EditImageViewの外枠
        editImageViewOverViewTop = [[UIView alloc] init];
        editImageViewOverViewTop.frame = CGRectMake(0, 0, self.frame.size.width, (self.frame.size.height - argCropHeight)/2.0);
        editImageViewOverViewTop.backgroundColor = [UIColor blackColor];
        editImageViewOverViewTop.alpha = 0.5;
        editImageViewOverViewTop.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewTop];
        
        editImageViewOverViewBottom = [[UIView alloc] init];
        editImageViewOverViewBottom.frame = CGRectMake(0, editImageViewOverViewTop.frame.origin.y + editImageViewOverViewTop.frame.size.height + argCropHeight, editImageViewOverViewTop.frame.size.width, editImageViewOverViewTop.frame.size.height);
        editImageViewOverViewBottom.backgroundColor = [UIColor blackColor];
        editImageViewOverViewBottom.alpha = 0.5;
        editImageViewOverViewBottom.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewBottom];
        
        editImageViewOverViewLeft = [[UIView alloc] init];
        editImageViewOverViewLeft.frame = CGRectMake(0, editImageViewOverViewTop.frame.origin.y + editImageViewOverViewTop.frame.size.height, (self.frame.size.width - argCropWith) / 2, self.frame.size.height - (editImageViewOverViewTop.frame.size.height*2));
        editImageViewOverViewLeft.backgroundColor = [UIColor blackColor];
        editImageViewOverViewLeft.alpha = 0.5;
        editImageViewOverViewLeft.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewLeft];
        
        editImageViewOverViewRight = [[UIView alloc] init];
        editImageViewOverViewRight.frame = CGRectMake(self.frame.size.width - editImageViewOverViewLeft.frame.size.width, editImageViewOverViewLeft.frame.origin.y, editImageViewOverViewLeft.frame.size.width, editImageViewOverViewLeft.frame.size.height);
        editImageViewOverViewRight.backgroundColor = [UIColor blackColor];
        editImageViewOverViewRight.alpha = 0.5;
        editImageViewOverViewRight.userInteractionEnabled = NO;
        [self addSubview:editImageViewOverViewRight];

        completionHandler = argCompletionHandler;

        UIView *btnAreaView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 60)];
        btnAreaView.backgroundColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];

        // キャンセルボタン
        UIButton *selectCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        selectCancelButton.frame = CGRectMake(20, 10, 100, 40);
        selectCancelButton.backgroundColor = [UIColor clearColor];
        [selectCancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [selectCancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
        [selectCancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [selectCancelButton sizeToFit];
        selectCancelButton.frame = CGRectMake(20, selectCancelButton.frame.origin.y, selectCancelButton.frame.size.width, 40);
        [selectCancelButton addTarget:self action:@selector(onPushCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [btnAreaView addSubview:selectCancelButton];
        
        // OKボタン
        UIButton *selectOkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        selectOkButton.frame = CGRectMake(btnAreaView.frame.size.width - 100, selectCancelButton.frame.origin.y, 100, 40);
        selectOkButton.backgroundColor = [UIColor clearColor];
        [selectOkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [selectOkButton setTitle:NSLocalizedString(@"Choose", @"Choose") forState:UIControlStateNormal];
        [selectOkButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [selectOkButton sizeToFit];
        selectOkButton.frame = CGRectMake(btnAreaView.frame.size.width - selectOkButton.frame.size.width - 20, selectCancelButton.frame.origin.y, selectOkButton.frame.size.width, 40);
        [selectOkButton addTarget:self action:@selector(onPushOkButton:) forControlEvents:UIControlEventTouchUpInside];
        [btnAreaView addSubview:selectOkButton];
    
        [self addSubview:btnAreaView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame :(UIImage *)argImage :(int)argCropWith :(int)argCropHeight :(UIView*)argOverlayView :(MCropCompletionHandler)argCompletionHandler;
{
    id _self = [self initWithFrame:frame :argImage :argCropWith:argCropHeight :argCompletionHandler];
    [_self addSubview:argOverlayView];
    return _self;
}

- (void)show:(BOOL)animated;
{
    if(YES == animated){
        [UIView animateWithDuration:0.3f animations:^{
            self.frame = CGRectMake(self.frame.origin.x, 0, self.frame.size.width, self.frame.size.height);
        } completion:nil];
    }
    else {
        self.frame = CGRectMake(self.frame.origin.x, 0, self.frame.size.width, self.frame.size.height);
    }
}

- (void)dissmiss:(BOOL)animated;
{
    if(YES == animated){
        [UIView animateWithDuration:0.3f animations:^{
            self.frame = CGRectMake(self.frame.origin.x, self.frame.size.height + 10, self.frame.size.width, self.frame.size.height);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }
    else {
        [self removeFromSuperview];
    }
}

- (void)onPushCancelButton:(id)sender
{
    // ハンドラの実行
    if (nil != completionHandler){
        completionHandler(self, NO, nil);
    }
}

- (void)onPushOkButton:(id)sender
{
    // ハンドラの実行
    if (nil != completionHandler){
        completionHandler(self, YES, editImageView.lastEdittingImage);
    }
}

@end
