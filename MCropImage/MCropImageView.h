//
//  MCropImageView.h
//
//  Created by saimushi on 2014/10/08.
//

#import "MEditImageView.h"

@class MCropImageView;

typedef void(^MCropCompletionHandler)(MCropImageView *mcropImageView, BOOL finished, UIImage *image);

@interface MCropImageView : UIView <MEditImageViewDelegate>

// 色枠ビューで画像を編集
- (id)initWithFrame:(CGRect)frame
           cropSize:(CGSize)cropSize
          lineColor:(UIColor *)lineColor
            bgColor:(UIColor *)bgColor;

// 半透明黒枠ビューで画像を編集
- (id)initWithFrame:(CGRect)frame
           cropSize:(CGSize)cropSize;

// addSubViewしたいときはこっちを呼ぼう
- (id)initWithFrame:(CGRect)frame :(UIImage *)argImage :(int)argCropWith :(int)argCropHeight :(MCropCompletionHandler)argCompletionHandler;
- (id)initWithFrame:(CGRect)frame :(UIImage *)argImage :(int)argCropWith :(int)argCropHeight :(UIView*)argOverlayView :(MCropCompletionHandler)argCompletionHandler;

- (void)show:(BOOL)animated;
- (void)dissmiss:(BOOL)animated;

- (void)setImage:(UIImage *)image;
- (UIImage *)getCroppedImage;

@end
