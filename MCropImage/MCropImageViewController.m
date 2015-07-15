//
//  MCropImageViewController.m
//
//  Created by maichi on 2014/11/17.
//  Version:1.1

#import "MCropImageViewController.h"

#import "MCropImageView.h"
#import "MProgress.h"

#define SHOW_TYPE_NAVIGATION 1
#define SHOW_TYPE_MODAL      2

@interface MCropImageViewController ()

@end

@implementation MCropImageViewController
{
    MCropImageView *mCropImageView;
    
    CGSize _cropSize;
    UIImagePickerControllerSourceType _sourceType;
    void(^_compBlock)(UIImage *originalImage, UIImage *croppedImage);
    
    UIImage *_originalImage;
    int showType;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor   = [UIColor clearColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    return;
}

/**
 * ナビゲーション + 色枠ビューで画像を編集
 */
- (void)cropWithColorFrame:(CGSize)cropSize
                sourceType:(UIImagePickerControllerSourceType)sourceType
                 lineColor:(UIColor *)lineColor
                   bgColor:(UIColor *)bgColor
                completion:(void(^)(UIImage *originalImage, UIImage *croppedImage))completion
{
    _sourceType = sourceType;
    _compBlock  = [completion copy];
    
    showType = SHOW_TYPE_NAVIGATION;
    
    // ナビゲーションバーにボタンを追加
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(onPushCancelButton:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *okButton = [[UIBarButtonItem alloc]
                                 initWithTitle:NSLocalizedString(@"Choose", @"Choose")
                                 style:UIBarButtonItemStylePlain
                                 target:self
                                 action:@selector(onPushOKButton:)];
    self.navigationItem.rightBarButtonItem = okButton;
    
    // ビューを非表示にしておく
    self.view.hidden = YES;
    self.navigationController.navigationBar.hidden = YES;

    // 編集画面
    mCropImageView = [[MCropImageView alloc] initWithFrame:self.view.frame
                                                  cropSize:cropSize
                                                 lineColor:lineColor
                                                   bgColor:bgColor];
    [self.view addSubview:mCropImageView];
    
    // 画像を選択
    [self selectPhoto];
    
    return;
}

/**
 * モーダルで表示 + 半透明黒枠ビューで画像を編集
 */
- (void)cropWithOverlayFrame:(CGSize)cropSize
                  sourceType:(UIImagePickerControllerSourceType)sourceType
                  completion:(void(^)(UIImage *originalImage, UIImage *croppedImage))completion
{
    _sourceType = sourceType;
    _compBlock  = [completion copy];
    
    showType = SHOW_TYPE_MODAL;
    
    // ビューにボタンを追加
    UIView *btnAreaView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width, 60)];
    btnAreaView.backgroundColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    btnAreaView.userInteractionEnabled = YES;
    [self.view addSubview:btnAreaView];
    
    // キャンセルボタン
    UIButton *selectCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    selectCancelButton.frame = CGRectMake(20, 10, 100, 40);
    selectCancelButton.backgroundColor = [UIColor clearColor];
    [selectCancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [selectCancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
    [selectCancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
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
    selectOkButton.frame = CGRectMake(btnAreaView.frame.size.width - selectOkButton.frame.size.width - 20, selectCancelButton.frame.origin.y, selectOkButton.frame.size.width, 40);
    [selectOkButton addTarget:self action:@selector(onPushOKButton:) forControlEvents:UIControlEventTouchUpInside];
    [btnAreaView addSubview:selectOkButton];
    
    // ビューを非表示にしておく
    self.view.hidden = YES;
    
    // 編集画面
    mCropImageView = [[MCropImageView alloc] initWithFrame:CGRectMake(0, 0,
                                                                      self.view.frame.size.width,
                                                                      self.view.frame.size.height - btnAreaView.frame.size.height)
                                                  cropSize:cropSize];
    [self.view addSubview:mCropImageView];
    
    // 一番前に
    [self.view bringSubviewToFront:btnAreaView];
    
    // 画像を選択
    [self selectPhoto];
    
    return;
}

#pragma mark - UIImagePickerController

/**
 * 画像を選択
 */
- (void)selectPhoto
{
    // カメラやアルバムが有効か
    if (![UIImagePickerController isSourceTypeAvailable:_sourceType]) {
        [MAlertView showAlertView:@"カメラまたはアルバムが有効ではありません。"
                  leftButtonTitle:@"OK"
                 rightButtonTitle:nil
                       completion:^(NSInteger buttonIndex) {
                           self.view.hidden = NO;
                           self.navigationController.navigationBar.hidden = NO;
                           [self.navigationController popViewControllerAnimated:YES];
                       }];
        return;
    }
    
    // イメージピッカーを作る
    UIImagePickerController *imagePicker;
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType    = _sourceType;
    imagePicker.allowsEditing = NO;
    imagePicker.delegate      = self;
    imagePicker.navigationBar.tintColor    = [UIColor whiteColor];
    imagePicker.navigationBar.barStyle     = UIBarStyleBlack;
    imagePicker.navigationBar.barTintColor = COLOR_BASE;
    imagePicker.navigationBar.translucent  = YES;
    
    // イメージピッカーを表示する
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tabBarController presentViewController:imagePicker animated:YES completion: nil];
    });
    return;
}

/**
 * 画像が選択されたとき
 */
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    _originalImage = image;
    
    // ローディング開始
    [MProgress showProgress];
    
    // 画像を端末に保存
    if (_sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(didSaveImage:didFinishSavingWithError:contextInfo:), nil);
    }
    
    // イメージピッカーを隠す
    [picker dismissViewControllerAnimated:YES completion:^{
        // ビューを表示状態に戻す
        self.view.hidden = NO;
        self.navigationController.navigationBar.hidden = NO;
        
        // 画像をセット
        mCropImageView.image = image;
        
        // ローディング停止
        [MProgress dismissProgress];
    }];
    return;
}

/**
 * 画像保存完了
 */
- (void)didSaveImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"Failed to save the image");
    }
    return;
}

/**
 * 画像選択キャンセル
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // ビューを表示状態に戻す
    self.view.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    
    // 戻る
    [self.navigationController popViewControllerAnimated:YES];
    
    // イメージピッカーを隠す
    [picker dismissViewControllerAnimated:YES completion:nil];
    return;
}

#pragma mark - UIButton pushed

/**
 * キャンセルボタン
 */
- (void)onPushCancelButton:(id)sender
{
    if (showType == SHOW_TYPE_NAVIGATION) {
        [self.navigationController popViewControllerAnimated:YES];
    
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    return;
}

/**
 * OKボタン
 */
- (void)onPushOKButton:(id)sender
{
    _compBlock(_originalImage, [mCropImageView getCroppedImage]);
    if (showType == SHOW_TYPE_NAVIGATION) {
        [self.navigationController popViewControllerAnimated:YES];
        
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    return;
}

@end
