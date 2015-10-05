//
//  HRPGExplanationView.m
//  Habitica
//
//  Created by Phillip Thelen on 05/10/15.
//  Copyright © 2015 Phillip Thelen. All rights reserved.
//

#import "HRPGExplanationView.h"
#import "HRPGSpeechBubbleView.h"

@interface HRPGExplanationView ()

@property UIImageView *justinView;
@property HRPGSpeechbubbleView *speechBubbleView;

@end

@implementation HRPGExplanationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        self.dimColor = [UIColor colorWithWhite:0 alpha:0.6];
        
        self.justinView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"justin"]];
        self.justinView.userInteractionEnabled = NO;
        [self addSubview:self.justinView];
        
        self.speechBubbleView = [[HRPGSpeechbubbleView alloc] init];
        self.speechBubbleTextColor = [UIColor blackColor];
        [self addSubview:self.speechBubbleView];
        
        UIGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:gestureRecognizer];
    }
    
    return self;
}

- (void)displayOnView:(UIView *)view animated:(BOOL)animated {
    [view addSubview:self];
    self.frame = view.frame;
    
    CGFloat speechBubbleHeight = [self.speechBubbleText boundingRectWithSize:CGSizeMake(self.frame.size.width-96, MAXFLOAT)
                                                                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                        attributes:@{
                                                                                                                                     NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                                                                                                     }
                                                                                                                           context:nil].size.height + 32;
    self.justinView.frame = CGRectMake(10, self.frame.size.height, 42, 63);
    self.speechBubbleView.frame = CGRectMake(60, self.frame.size.height-20, 0, 0);
    self.speechBubbleView.alpha = 0;
    [UIView animateWithDuration:0.4 animations:^() {
        self.backgroundColor = self.dimColor;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^() {
            self.justinView.frame = CGRectMake(10, self.frame.size.height-50, 42, 63);
        } completion:^(BOOL completed) {
            [UIView animateWithDuration:0.3 animations:^() {
                self.speechBubbleView.alpha = 1.0;
                self.speechBubbleView.frame = CGRectMake(60, self.frame.size.height-speechBubbleHeight-20, self.frame.size.width-80, speechBubbleHeight);
            } completion:^(BOOL completed) {
                self.speechBubbleView.text = self.speechBubbleText;
            }];
        }];
    }];
}

- (void)dismissAnimated:(BOOL)animated {
    [UIView animateWithDuration:0.4 animations:^() {
        self.alpha = 0;
    }completion:^(BOOL completed) {
        [self removeFromSuperview];
    }];
}

- (void)setSpeechBubbleTextColor:(UIColor *)speechBubbleTextColor {
    _speechBubbleTextColor = speechBubbleTextColor;
    self.speechBubbleView.textColor = speechBubbleTextColor;
}

- (void) handleTap:(UIGestureRecognizer *)recognizer {
    [self dismissAnimated:YES];
}

@end
