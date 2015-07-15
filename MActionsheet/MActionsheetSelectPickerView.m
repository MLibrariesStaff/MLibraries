//
//  MActionsheetSelectPickerView.m
//
//  Created by maichi on 2014/09/05.
//  Version:1.0
//

#import "MActionsheetSelectPickerView.h"

@implementation MActionsheetSelectPickerView
{
    UIPickerView *selectPickerView;
    int _defaultIndexInt;
    NSArray *_selectArray;
    void(^_compBlock)(NSInteger buttonIndex);
}

+ (MActionsheetSelectPickerView *)setSelectPickerView:(int)defaultIndex
                                          selectArray:(NSArray *)selectArray
                                           completion:(void (^)(NSInteger selectIndex))completion;
{
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    MActionsheetSelectPickerView *mActionsheetSelectPickerView = [[self alloc] initView:(int)defaultIndex
                                                                            selectArray:(NSArray *)selectArray
                                                                             completion:(void (^)(NSInteger selectIndex))completion];
    [window addSubview:mActionsheetSelectPickerView];
    return mActionsheetSelectPickerView;
}

/**
 * 選択ピッカーのビューをセット
 */
- (id)initView:(int)defaultIndex
   selectArray:(NSArray *)selectArray
    completion:(void (^)(NSInteger selectIndex))completion
{
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    if (self) {
        _defaultIndexInt = defaultIndex;
        _selectArray     = [NSArray arrayWithArray:selectArray];
        _compBlock = [completion copy];
        [self setView];
    }
    return self;
}

- (void)setView
{
    // 背景を黒透明にする
    self.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:0.000 alpha:0.5];
    
    // ピッカーとボタンのアニメーション背景
    UIView *pickerMiddleBgView = [[UIView alloc] init];
    pickerMiddleBgView.frame   = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    pickerMiddleBgView.backgroundColor = [UIColor clearColor];
    
    // キャンセルボタン
    UIButton *selectCancelButton = [[UIButton alloc] init];
    selectCancelButton.frame = CGRectMake(SPACE, [[UIScreen mainScreen] bounds].size.height - 40 - SPACE, (self.frame.size.width - SPACE*3)/2, 40);
    selectCancelButton.layer.cornerRadius = 5.0f;
    selectCancelButton.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:0.9];
    [selectCancelButton setTitleColor:MACTIONSELECT_FONT_COLOR forState:UIControlStateNormal];
    [selectCancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [selectCancelButton addTarget:self action:@selector(onPushPickerCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    selectCancelButton.userInteractionEnabled = YES;
    [pickerMiddleBgView addSubview:selectCancelButton];
    
    // OKボタン
    UIButton *selectOkButton = [[UIButton alloc] init];
    selectOkButton.frame = CGRectMake((self.frame.size.width - SPACE*3)/2 + SPACE*2, self.frame.size.height - 40 - SPACE,
                                      (self.frame.size.width - SPACE*3)/2, 40);
    selectOkButton.layer.cornerRadius = 5.0f;
    selectOkButton.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:0.9];
    [selectOkButton setTitleColor:MACTIONSELECT_FONT_COLOR forState:UIControlStateNormal];
    [selectOkButton setTitle:@"OK" forState:UIControlStateNormal];
    [selectOkButton addTarget:self action:@selector(onPushSelectPickerOkButton:) forControlEvents:UIControlEventTouchUpInside];
    selectOkButton.userInteractionEnabled = YES;
    [pickerMiddleBgView addSubview:selectOkButton];
    
    // 下から表示
    CGPoint middleCenter = pickerMiddleBgView.center;
    CGSize offSize = [UIScreen mainScreen].bounds.size;
    CGPoint offScreenCenter = CGPointMake(offSize.width/2.0, offSize.height*2.0);
    pickerMiddleBgView.center = offScreenCenter;
    [self addSubview:pickerMiddleBgView];
    [UIView animateWithDuration:0.5f animations:^{
        pickerMiddleBgView.center = middleCenter;
    }];
    
    // ピッカーの作成
    selectPickerView            = [[UIPickerView alloc] init];
    selectPickerView.frame      = CGRectMake(0, 0, self.frame.size.width - SPACE*2, selectPickerView.frame.size.height);
    selectPickerView.delegate   = self;
    selectPickerView.dataSource = self;
    selectPickerView.backgroundColor = [UIColor clearColor];
    selectPickerView.showsSelectionIndicator = YES;
    
    // ピッカー背景
    UIView *bgSelectPickerView = [[UIView alloc] init];
    bgSelectPickerView.frame   = CGRectMake(SPACE,
                                            [[UIScreen mainScreen] bounds].size.height - 40 - selectPickerView.frame.size.height - SPACE*2,
                                            self.frame.size.width - SPACE*2,
                                            selectPickerView.frame.size.height);
    bgSelectPickerView.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:0.9];
    bgSelectPickerView.layer.cornerRadius = 5.0f;
    [pickerMiddleBgView addSubview:bgSelectPickerView];
    [bgSelectPickerView addSubview:selectPickerView];

    // デフォルト値を設定
    [selectPickerView selectRow:_defaultIndexInt inComponent:0 animated:NO];
    
    return;
}

#pragma mark - set UIPickerView

/**
 * ピッカーに表示する列数を返す
 */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

/**
 * ピッカーに表示する行数を返す
 */
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _selectArray.count;
}

/**
 * ピッカーの内容を設定
 */
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [_selectArray objectAtIndex:row];
}


/**
 * ピッカーを隠す
 */
- (void)hidePicker
{
    UIView *pickerMiddleBgView = [self.subviews objectAtIndex:0];
    CGSize offSize = [UIScreen mainScreen].bounds.size;
    CGPoint offScreenCenter = CGPointMake(offSize.width/2.0, offSize.height*3.0);
    [UIView animateWithDuration:0.3f animations:^{
        pickerMiddleBgView.center = offScreenCenter;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(didFinishHidePicker) withObject:nil];
    }];
    return;
}

/**
 * ピッカーを隠し終った時
 */
- (void)didFinishHidePicker
{
    [self removeFromSuperview];
}

#pragma mark - UIButton pushed

/**
 * ピッカーキャンセル
 */
- (void)onPushPickerCancelButton:(id)sender
{
    [self hidePicker];
}

/**
 * 選択ピッカーOK
 */
- (void)onPushSelectPickerOkButton:(id)sender
{
    // 選択されたindex
    NSInteger selectedRow = [selectPickerView selectedRowInComponent:0];
    _compBlock(selectedRow);
    
    [self hidePicker];
    return;
}

@end
