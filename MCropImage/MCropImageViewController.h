//
//  MCropImageViewController.h
//
//  Created by maichi on 2014/11/17.
//  Version:1.1
/*
 [how to use]
 
 #import "MCropImageViewController.h"
 
 // sample code
 1. ナビゲーションで表示かつ、背景、切り取り枠の色をセットする場合
 [self.navigationController pushViewController:mCropImageViewController animated:NO];
 [mCropImageViewController cropWithColorFrame:CGSizeMake(200, 200)
                                   sourceType:sourceType
                                    lineColor:[UIColor yellowColor]
                                      bgColor:[UIColor whiteColor]
                                   completion:^(UIImage *originalImage, UIImage *croppedImage) {
                                    // 画像を受け取ったあとの処理
                                UIImageView *sampleImageView.image = croppedImage;
                                }];
 

 2. モーダルで表示かつ、切り取り枠の周りを黒半透明で表示する場合
  MCropImageViewController *mCropImageViewController = [[MCropImageViewController alloc] init];
 [self presentViewController:mCropImageViewController animated:YES completion:nil];
 
 [mCropImageViewController cropWithOverlayFrame:CGSizeMake(200, 200)
                                     sourceType:sourceType
                                     completion:^(UIImage *originalImage, UIImage *croppedImage) {
                                // 画像を受け取ったあとの処理
                                UIImageView *sampleImageView.image = croppedImage;
                                }];
 
 */

#import <UIKit/UIKit.h>

@interface MCropImageViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

// ナビゲーション + 色枠ビューで画像を編集
- (void)cropWithColorFrame:(CGSize)cropSize
                sourceType:(UIImagePickerControllerSourceType)sourceType
                 lineColor:(UIColor *)lineColor
                   bgColor:(UIColor *)bgColor
                completion:(void(^)(UIImage *originalImage, UIImage *croppedImage))completion;

// モーダルで表示 + 半透明黒枠ビューで画像を編集
- (void)cropWithOverlayFrame:(CGSize)cropSize
                  sourceType:(UIImagePickerControllerSourceType)sourceType
                  completion:(void(^)(UIImage *originalImage, UIImage *croppedImage))completion;

@end
