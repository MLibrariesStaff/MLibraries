//
//  MToast.m
//  gsns
//
//  Created by n00874 on 2015/04/13.
//  Copyright (c) 2015年 cybird. All rights reserved.
//

#import "MToast.h"

@implementation MToast

+ (MToast *)showMToastView:(NSString *)body
{
    return [[self alloc] initToastView:body];
}

- (id)initToastView:(NSString *)body
{
    self = [self init];
    if (self) {
        
        UIWindow *window = [[UIApplication sharedApplication] delegate].window;
        CGFloat bgVewMargin = 15;
        CGFloat titleLabelMargin = 8;

        self.frame = CGRectMake(bgVewMargin, 0, window.frame.size.width - bgVewMargin*2, 0);
        self.backgroundColor = UIColor.darkGrayColor;
        self.layer.shadowOffset  = CGSizeMake(0, 0);
        self.layer.shadowColor   = UIColor.lightGrayColor.CGColor;
        self.layer.shadowOpacity = 0.9;
        self.layer.shadowRadius  = 2.0f;
        self.layer.cornerRadius  = 1.0f;
        [window addSubview:self];
        
        // タイトルをセット
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = CGRectMake(titleLabelMargin, titleLabelMargin, self.frame.size.width - titleLabelMargin*2, 0);
        titleLabel.backgroundColor = UIColor.clearColor;
        titleLabel.text            = body;
        titleLabel.textAlignment   = NSTextAlignmentLeft;
        titleLabel.font            = [UIFont systemFontOfSize:14];
        titleLabel.textColor       = UIColor.whiteColor;
        titleLabel.numberOfLines   = 0;
        titleLabel.lineBreakMode   = NSLineBreakByCharWrapping;
        [self addSubview:titleLabel];
        
        // 高さを調整
        CGSize size = [titleLabel sizeThatFits:CGSizeMake(titleLabel.frame.size.width,
                                                          window.frame.size.height - titleLabelMargin*6)];
        titleLabel.width  = size.width + 2;
        titleLabel.height = size.height + 4;
        self.width  = titleLabel.width + titleLabelMargin*2;
        self.height = size.height + titleLabelMargin*2 + 4;
        self.x      = (window.frame.size.width - self.width)/2;
        self.y      = window.frame.size.height - size.height - bgVewMargin*5;
        
        // 一度サイズを0にする
        self.transform = CGAffineTransformMakeScale(0.5, 0.5);
        self.alpha = 0.0f;
        
        // 大きく登場
        [UIView animateKeyframesWithDuration:0.2f
                                       delay:0.0
                                     options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction)
                                  animations:^{
                                      self.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                      self.alpha = 1.0f;
                                      
                                  } completion:^(BOOL finished) {
                                      
                                      // フェードアウト
                                      [UIView animateKeyframesWithDuration:0.5f
                                                                     delay:1.0
                                                                   options:(UIViewAnimationOptionCurveEaseIn
                                                                            | UIViewAnimationOptionBeginFromCurrentState)
                                                                animations:^{
                                                                    self.alpha = 0.0f;
                                                                    
                                                                // リムーブ
                                                                } completion:^(BOOL finished) {
                                                                    [self removeFromSuperview];
                                                                }];
                                  }];
    }
    return self;
}


@end
