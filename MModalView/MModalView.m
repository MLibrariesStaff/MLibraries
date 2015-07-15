//
//  MModalView.m
//
//  Created by maichi on 2014/07/10.
//  Version:1.0

#import "MModalView.h"

@implementation MModalView
{
    UIView *_modalView;
    BOOL _isCloseButton;
}

/**
 * モーダルを表示
 */
+ (MModalView *)showModalView:(UIView *)modalView isCloseButton:(BOOL)isCloseButton
{
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    MModalView *mModalView =[[self alloc] initModalView:modalView isCloseButton:isCloseButton];
    mModalView.frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
    [window addSubview:mModalView];
    
    [mModalView show];

    return mModalView;
}

/**
 * モーダルを非表示
 */
+ (void)dismissModalView
{
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    
    MModalView *mModalView;
    NSEnumerator *subviewsEnum = window.subviews.reverseObjectEnumerator;
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            mModalView = (MModalView *)subview;
            if (mModalView) {
                [mModalView dismiss];
            }
        }
    }
    return;
}

#pragma mark - private function

- (id)initModalView:(UIView *)modalView isCloseButton:(BOOL)isCloseButton
{
    self = [self init];
    if (self) {
        UIWindow *window = [[UIApplication sharedApplication] delegate].window;
        self.frame     = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
        _modalView     = modalView;
        _isCloseButton = isCloseButton;
        [self setView];
    }
    return self;
}

- (void)setView
{
    CGRect bounds = self.superview.bounds;
    self.center = CGPointMake(bounds.size.width / 2.0f, bounds.size.height / 2.0f);
    if ([self.superview isKindOfClass:UIWindow.class]
        && UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        self.bounds = (CGRect){CGPointZero, {bounds.size.height, bounds.size.width}};
        
    } else {
        self.bounds = (CGRect){CGPointZero, bounds.size};
    }
    
    self.hidden = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // モーダルをセット
    [self addSubview:_modalView];
    [self applyMotionEffects];
    
    // とじるボタン
    if (_isCloseButton == YES) {
        UIImage *closeImage = [UIImage imageNamed:@"close"];
        UIImageView *closeImageView = [[UIImageView alloc] init];
        closeImageView.frame = CGRectMake(10, 12, closeImage.size.width, closeImage.size.height);
        closeImageView.backgroundColor = [UIColor clearColor];
        closeImageView.image = closeImage;
        
        UIButton *dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(_modalView.frame.size.width - closeImage.size.width - 20,
                                                                   0, closeImage.size.width + 20, closeImage.size.height + 20)];
        dismissButton.backgroundColor = [UIColor clearColor];
        [dismissButton addTarget:self action:@selector(onPushDismissButton:) forControlEvents:UIControlEventTouchUpInside];
        dismissButton.showsTouchWhenHighlighted = YES;
        dismissButton.enabled = YES;
        [dismissButton addSubview:closeImageView];
        
        [_modalView addSubview:dismissButton];
    }
    
    [self tintColorDidChange];
    return;
}

/**
 * 表示
 */
- (void)show
{
    CGAffineTransform transform = CGAffineTransformMakeScale(1.3f, 1.3f);
    _modalView.transform = transform;
    _modalView.alpha     = 0.5f;
    
    self.backgroundColor = UIColor.clearColor;
    self.hidden = NO;
    
    void (^animBlock)() = ^{
        _modalView.transform = CGAffineTransformIdentity;
        _modalView.alpha     = 1.0f;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    };
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:animBlock
                     completion:nil];
    return;
}

/**
 * 非表示
 */
- (void)dismiss
{
    [self hide:YES completion:^{
        [self removeFromSuperview];
    }];
    return;
}

- (void)hide:(BOOL)animated completion:(void(^)())completionBlock
{
    _modalView.transform = CGAffineTransformIdentity;
    _modalView.alpha     = 1.0f;
    
    void(^animBlock)() = ^{
        CGAffineTransform transform = CGAffineTransformMakeScale(0.6f, 0.6f);
        _modalView.transform = transform;
        _modalView.alpha     = 0.0f;
        self.backgroundColor = UIColor.clearColor;
    };
    
    void(^animCompletionBlock)(BOOL) = ^(BOOL finished) {
        self.hidden = YES;
        if (completionBlock) {
            completionBlock();
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:animBlock
                         completion:animCompletionBlock];
    } else {
        animBlock();
        animCompletionBlock(YES);
    }
    return;
}

#pragma mark - Helper to create UIMotionEffects

- (UIInterpolatingMotionEffect *)motionEffectWithKeyPath:(NSString *)keyPath type:(UIInterpolatingMotionEffectType)type
{
    UIInterpolatingMotionEffect *effect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:keyPath type:type];
    effect.minimumRelativeValue = @(-10);
    effect.maximumRelativeValue = @(10);
    return effect;
}

- (void)applyMotionEffects
{
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[[self motionEffectWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis],
                                        [self motionEffectWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis]];
    [_modalView addMotionEffect:motionEffectGroup];
    return;
}

#pragma mark - UIButton pushed

/**
 * 閉じるボタン
 */
- (void)onPushDismissButton:(id)sender
{
    [self dismiss];
    return;
}
    
@end
