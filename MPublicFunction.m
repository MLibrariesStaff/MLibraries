//
//  MPublicFunction.m
//
//  Created by n00874 on 2014/11/05.
//  Copyright (c) 2014年 cybird. All rights reserved.
//

#import "PublicFunction.h"

@implementation PublicFunction

/**
 * JSONをパースする
 */
+ (NSDictionary *)parse:(NSData *)jsonData
{
    NSError *error = nil;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    return jsonDictionary;
}

/**
 * JSONに変換
 */
+ (NSString *)toJson:(NSDictionary *)dataDictionary
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDictionary options:kNilOptions error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonString;
}

/**
 * 数字をフォーマット
 */
NSString *numberFormat(NSString *number)
{
    if (number == nil || [number isKindOfClass:[NSNull class]] == YES) {
        return @"0";
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    [formatter setGroupingSize:3];
    NSString *formattedNumberString = [formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:[number longLongValue]]];
    
    return formattedNumberString;
}

/**
 * 数字のフォーマットを元にもどす
 */
int undoNumberFormat(NSString *number)
{
    return [[number stringByReplacingOccurrencesOfString:@"," withString:@""] intValue];
}

/**
 * 絶対位置を取得
 */
CGPoint absPoint(UIView *view)
{
    CGPoint ret = CGPointMake(view.frame.origin.x, view.frame.origin.y);
    if ([view superview] != nil) {
        CGPoint addPoint = absPoint([view superview]);
        ret = CGPointMake(ret.x + addPoint.x, ret.y + addPoint.y);
        
        if ([view.superview isKindOfClass:[UIScrollView class]] == YES) {
            UIScrollView *sv = (UIScrollView *)view.superview;
            CGPoint offset   = sv.contentOffset;
            ret.x = ret.x - offset.x;
            ret.y = ret.y - offset.y;
        }
    }
    return ret;
}

/**
 * カラーコードをUIColorに変換 (ex) #000000)
 */
+ (UIColor *)getColorFromColorCode:(NSString *)colorCode
{
    if ([colorCode isKindOfClass:[NSString class]] == NO
        ||colorCode == nil || [colorCode isEqualToString:@""] == YES) {
        return [UIColor clearColor];
    }
    
    unsigned rgbValue = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:colorCode];
    [scanner setScanLocation:1]; // #でわける
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

/**
 * 本日の日付けを取得
 */
NSString *getToday()
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
                                   NSMonthCalendarUnit  |
                                   
                                   NSDayCalendarUnit    |
                                   NSHourCalendarUnit   |
                                   NSMinuteCalendarUnit |
                                   NSSecondCalendarUnit
                                              fromDate:date];
    return [NSString stringWithFormat:@"%ld/%02ld/%02ld", (long)dateComps.year, (long)dateComps.month, (long)dateComps.day];
}

/**
 * 暗号化
 */
+ (NSString *)encryptString:(NSString *)text
{
    if (text == nil || [text isEqualToString:@""] == YES) {
        return nil;
    }
    
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *keyData = [AUTH_KEY dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyData.bytes, kCCKeySizeAES256,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        data = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        return [data base64EncodedStringWithOptions:0];
    }
    free(buffer);
    return nil;
}

/**
 * 複合化
 */
+ (NSString *)decryptString:(NSString *)text
{
    if (text == nil || [text isEqualToString:@""] == YES) {
        return nil;
    }
    
    NSData *data          = [[NSData alloc] initWithBase64EncodedString:text options:0];
    NSData *keyData       = [AUTH_KEY dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyData.bytes, kCCKeySizeAES256,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        data = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return [decodedString stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    }
    free(buffer);
    return nil;
}

/**
 * 最後を『...続きを読む』で省略
 */
+ (void)seeMoreTruncatingTail:(UITextView *)textView maxHeight:(CGFloat)maxHeight
{
    // 省略するかどうか
    textView.textContainer.maximumNumberOfLines = 0;
    CGSize fullSize = [textView sizeThatFits:CGSizeMake((CGFloat)textView.width, CGFLOAT_MAX)];

    if (fullSize.height > maxHeight) {
        
        // 省略文字
        NSString *seeMoreString = [NSString stringWithFormat:@" ...%@", NSLocalizedString(@"続きを読む", @"See More")];
        
        // 表示文字数を取得
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:textView.text
                                                                         attributes:@{NSFontAttributeName:textView.font}];
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, textView.width, maxHeight));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFRange actuallyRenderedRange = CTFrameGetVisibleStringRange(frame);
        NSString *actuallyRenderedText = [textView.text substringWithRange:NSMakeRange(0, actuallyRenderedRange.length)];
        
        // リリース
        CGPathRelease(path);
        CFRelease(framesetter);
        CFRelease(frame);
        
        // 最後の文字が改行であるとき、なぜかmaxHeightに収まっていないので、あれば消す
        NSString *lastWord = [actuallyRenderedText substringFromIndex:actuallyRenderedText.length - 1];
        if ([lastWord isEqualToString:@"\n"] == YES) {
            actuallyRenderedText = [actuallyRenderedText substringWithRange:NSMakeRange(0, actuallyRenderedRange.length - 1)];
        }
        
        // 省略文字を加えた文字列が最大サイズを超えているか
        textView.text = [NSString stringWithFormat:@"%@%@", actuallyRenderedText, seeMoreString];
        CGSize actuallySize = [textView sizeThatFits:CGSizeMake((CGFloat)textView.width, CGFLOAT_MAX)];

        // 越えていればさらに省略
        if (actuallySize.height > maxHeight) {
            
            // 省略文字のバイト数
            int seeMoreByteLength = (int)[seeMoreString lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
            
            // 省略文字バイト数分の文字数を末尾から取り出す
            NSString *lastTailWord = [actuallyRenderedText substringFromIndex:actuallyRenderedText.length - seeMoreByteLength];
            
            // すべて全角のときはバイト数の半分の文字数
            int stringCount = 0;
            if (lastTailWord.length == [lastTailWord lengthOfBytesUsingEncoding:NSShiftJISStringEncoding]/2.0f) {
                stringCount = seeMoreByteLength/2.0f;
            
            } else {
                stringCount = seeMoreByteLength;
            }
            actuallyRenderedText = [actuallyRenderedText substringWithRange:NSMakeRange(0, actuallyRenderedRange.length - stringCount)];
        }

        // 省略文字をつけてセット
        NSMutableAttributedString *attrMutableString = [[NSMutableAttributedString alloc] init];
        NSAttributedString *string1 = [[NSAttributedString alloc] initWithString:actuallyRenderedText
                                                                      attributes:@{NSFontAttributeName:textView.font,
                                                                                   NSForegroundColorAttributeName:textView.textColor}];
        NSAttributedString *string2 = [[NSAttributedString alloc] initWithString:seeMoreString
                                                                      attributes:@{NSFontAttributeName:FONT_BASE,
                                                                                   NSForegroundColorAttributeName:[UIColor grayColor]}];
        [attrMutableString appendAttributedString:string1];
        [attrMutableString appendAttributedString:string2];
        textView.attributedText = attrMutableString;
    }
    return;
}

/**
 * 「」で囲み、最後を『...』で省略する
 */
+ (void)encloseTruncatingTail:(UILabel *)label maxHeight:(CGFloat)maxHeight
{
    int numberOfLines = (int)label.numberOfLines;

    // 省略するかどうか
    label.numberOfLines = 0;
    label.text = [NSString stringWithFormat:@"「%@」", label.text];
    CGSize fullSize = [label sizeThatFits:CGSizeMake((CGFloat)label.width, CGFLOAT_MAX)];
    if (fullSize.height > maxHeight) {
        // 一旦「」をはずす
        label.text = [label.text substringWithRange:NSMakeRange(1, label.text.length - 2)];
        
        // 表示文字数を取得
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:label.text
                                                                         attributes:@{NSFontAttributeName:label.font}];
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, label.width, maxHeight));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFRange actuallyRenderedRange  = CTFrameGetVisibleStringRange(frame);
        NSString *actuallyRenderedText = [label.text substringWithRange:NSMakeRange(0, actuallyRenderedRange.length)];
 
        // リリース
        CFRelease(frame);
        CFRelease(framesetter);
        CGPathRelease(path);

        // 最後の文字が改行であるとき、なぜかmaxHeightに収まっていないので、あれば消す
        if ([actuallyRenderedText isEqualToString:@""] == NO) {
            NSString *lastWord = [actuallyRenderedText substringFromIndex:actuallyRenderedText.length - 1];
            if ([lastWord isEqualToString:@"\n"] == YES) {
                actuallyRenderedText = [actuallyRenderedText substringWithRange:NSMakeRange(0, actuallyRenderedRange.length - 1)];
            }
        }
        
        // 省略文字のバイト数
        NSString *encloseString = @"「...」";
        int seeMoreByteLength = (int)[encloseString lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
        
        // 省略文字バイト数分の文字数を末尾から取り出す
        if ([actuallyRenderedText isEqualToString:@""] == NO) {
            NSString *lastTailWord = [actuallyRenderedText substringFromIndex:actuallyRenderedText.length - seeMoreByteLength];
        
            // すべて全角のときはバイト数の半分の文字数
            int stringCount = 0;
            if (lastTailWord.length == [lastTailWord lengthOfBytesUsingEncoding:NSShiftJISStringEncoding]/2) {
                stringCount = seeMoreByteLength/2;
                
            } else {
                stringCount = seeMoreByteLength;
            }
            actuallyRenderedText = [actuallyRenderedText substringWithRange:NSMakeRange(0, actuallyRenderedRange.length - stringCount)];
        }
            
        // 省略文字をつけてセット
        label.numberOfLines = numberOfLines;
        label.text = [NSString stringWithFormat:@"「%@...」", actuallyRenderedText];
    }
    return;
}

/**
 * ナビゲーションバーにボタンをセット
 */
+ (UIBarButtonItem *)setRightButton:(id)target action:(SEL)action imageName:(NSString *)imageName
{
    UIBarButtonItem *customBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:target
                                                                           action:action];
    return customBarButtonItem;
}

/**
 * ボタンの背景色を画像としてセット
 * ex) [button setBackgroundImage:[MPublicFunction imageWithColor:[UIColor magentaColor]] forState:UIControlStateNormal];
 */
+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - アニメーション

/**
 * ボタンのぽよんアニメーション
 */
+ (void)pushAnimation:(UIButton *)button completion:(void (^)(BOOL finished))completion
{
    [UIView animateKeyframesWithDuration:0.3f
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic
                              animations:^{
                                  CGRect originalFrame = button.frame;
                                  
                                  // 小さく
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:0.1
                                                                animations:^{
                                                                    button.frame = CGRectMake(button.x + 8,
                                                                                              button.y + 8,
                                                                                              button.width - 16,
                                                                                              button.height - 16);
                                                                }];
                                  completion(YES);
                                  
                                  // もどす
                                  [UIView addKeyframeWithRelativeStartTime:0.1
                                                          relativeDuration:0.2
                                                                animations:^{
                                                                    button.frame = originalFrame;
                                                                }];
                                  
                              } completion:^(BOOL finished) {
                                  
                              }];
    return;
}

/**
 * フェードイン
 * そもそものviewを 
 * view.alpha = 0.0f;
 * しておく
 */
+ (void)fadein:(UIView *)view
{
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         view.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
    return;
}

@end
