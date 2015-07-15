//
//  MActionsheetDatePickerView.m
//
//  Created by maichi on 2014/09/05.
//  Version:1.0
//

#import "MActionsheetDatePickerView.h"

@implementation MActionsheetDatePickerView
{
    UIDatePicker *datePicker;
    NSString *_defaultDateString;
    void(^_compBlock)(NSString *selectDate);
}

+ (MActionsheetDatePickerView *)setDatePickerView:(NSString *)defaultDateString
                                       completion:(void (^)(NSString *selectDate))completion
{
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    MActionsheetDatePickerView *mActionsheetDatePickerView = [[self alloc] initView:(NSString *)defaultDateString
                                                                         completion:(void (^)(NSString *selectDate))completion];
    [window addSubview:mActionsheetDatePickerView];
    return mActionsheetDatePickerView;
}

/**
 * 日付けピッカーのビューをセット
 */
- (id)initView:(NSString *)defaultDateString
    completion:(void (^)(NSString *selectDate))completion
{
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    if (self) {
        if (defaultDateString != nil) {
            _defaultDateString = [NSString stringWithString:defaultDateString];
        }
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
    [selectCancelButton setTitleColor:MACTIONDATE_FONT_COLOR forState:UIControlStateNormal];
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
    [selectOkButton setTitleColor:MACTIONDATE_FONT_COLOR forState:UIControlStateNormal];
    [selectOkButton setTitle:@"OK" forState:UIControlStateNormal];
    [selectOkButton addTarget:self action:@selector(onPushDatePickerOkButton:) forControlEvents:UIControlEventTouchUpInside];
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
    datePicker = [[UIDatePicker alloc] init];
    datePicker.frame = CGRectMake(0, 0, self.frame.size.width - SPACE*2, datePicker.frame.size.height);
    datePicker.datePickerMode = UIDatePickerModeDate;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.dateFormat = MACTIONDATE_DATE_FORMAT;
    datePicker.backgroundColor = [UIColor clearColor];
    
    // ピッカー背景
    UIView *bgDatePickerView = [[UIView alloc] init];
    bgDatePickerView.frame   = CGRectMake(SPACE, self.frame.size.height - 40 - datePicker.frame.size.height - SPACE*2,
                                          self.frame.size.width - SPACE*2, datePicker.frame.size.height);
    bgDatePickerView.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:0.9];
    bgDatePickerView.layer.cornerRadius = 5.0f;
    [pickerMiddleBgView addSubview:bgDatePickerView];
    [bgDatePickerView addSubview:datePicker];
    
    // 最大最小値をセット
    datePicker.minimumDate = [formatter dateFromString:MACTIONDATE_MIN_DATE];
    datePicker.maximumDate = [formatter dateFromString:MACTIONDATE_MAX_DATE];

    // デフォルト値を設定
    if (_defaultDateString.length == MACTIONDATE_DATE_FORMAT.length) {
        [datePicker setDate:[formatter dateFromString:_defaultDateString]];
    }
    
    return;
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
 * 日付ピッカーOK
 */
- (void)onPushDatePickerOkButton:(id)sender
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterFullStyle];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.dateFormat = MACTIONDATE_DATE_FORMAT;
    NSString *selectedDate = [formatter stringFromDate:[datePicker date]];
    
    _compBlock(selectedDate);

    [self hidePicker];
}

@end
