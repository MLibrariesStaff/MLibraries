//
//  MPublicFunction.h
//
//  Created by n00874 on 2014/11/05.
//  Copyright (c) 2014年 cybird. All rights reserved.
//
#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

@interface PublicFunction : NSObject <NSURLSessionTaskDelegate, UITextFieldDelegate>

// JSONをパースする
+ (NSMutableDictionary *)parse:(NSData *)jsonData;
// JSONに変換
+ (NSString *)toJson:(NSDictionary *)dataDictionary;

// 数字をフォーマット
NSString *numberFormat(NSString *number);

// 数字のフォーマットを元にもどす
int undoNumberFormat(NSString *number);

// 絶対位置を取得
CGPoint absPoint(UIView *view);

// カラーコードをUIColorに変換
+ (UIColor *)getColorFromColorCode:(NSString *)colorCode;

// 本日の日付けを取得
NSString *getToday();

// 暗号化 ※ Security.framework必須
+ (NSString *)encryptString:(NSString *)text;

// 復号化 ※ Security.framework必須
+ (NSString *)decryptString:(NSString *)text;

#pragma mark - ビューパーツをセット

// 最後に『...続きを読む』をつける
+ (void)seeMoreTruncatingTail:(UITextView *)textView maxHeight:(CGFloat)maxHeight;

//『「...」』で省略する
+ (void)encloseTruncatingTail:(UILabel *)label maxHeight:(CGFloat)maxHeight;

// ナビゲーションバーにボタンをセット
+ (UIBarButtonItem *)setRightButton:(id)target action:(SEL)action imageName:(NSString *)imageName;

// ボタンの背景色を画像としてセット
+ (UIImage *)imageWithColor:(UIColor *)color;

#pragma mark - アニメーション

// ボタンのぽよんアニメーション
+ (void)pushAnimation:(UIButton *)button completion:(void (^)(BOOL finished))completion;

// フェードイン
+ (void)fadein:(UIView *)view;

@end
