//
//  MModalView.h
//
//  Created by maichi on 2014/07/10.
//  Version:1.0
/*
    [how to use]
 
    #import "MModalView.h"
 
    ・UIViewでモーダル表示したいviewをつくり、showModalで表示
    [MModalView showModalView:modalView isCloseButton:YES];
 
    ・isCloseButtonがYESだと右上にcloseボタンあり、NOだとなし
    ・自作ボタンをつけた場合はボタンのpushアクションでdismiss
    [MModalView dismissModalView];
 
    // sample code
    UIView *modalView = [[UIView alloc] init];
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    modalView.frame = CGRectMake((window.frame.size.width - 300)/2, (window.frame.size.height - 400)/2, 300, 400);
    modalView.backgroundColor = [UIColor whiteColor];
    [MModalView showModalView:modalView isCloseButton:YES];
 
 */

#import <UIKit/UIKit.h>

@interface MModalView : UIView

+ (MModalView *)showModalView:(UIView *)modalView isCloseButton:(BOOL)isCloseButton;
+ (void)dismissModalView;


@end
