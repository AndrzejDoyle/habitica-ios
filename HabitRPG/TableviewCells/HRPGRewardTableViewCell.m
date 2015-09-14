//
//  HRPGRewardTableViewCell.m
//  Habitica
//
//  Created by Phillip Thelen on 13/09/15.
//  Copyright (c) 2015 Phillip Thelen. All rights reserved.
//

#import "HRPGRewardTableViewCell.h"
#import "MetaReward.h"
#import "Gear.h"
#import "Reward.h"
#import "UIColor+Habitica.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSString+Emoji.h"

@interface HRPGRewardTableViewCell ()

@property (nonatomic, copy) void (^tapAction)();

@end

@implementation HRPGRewardTableViewCell

- (void)configureForReward:(MetaReward *)reward withGoldOwned:(NSNumber *)gold {
    self.buyView.layer.borderWidth = 1.0;
    self.buyView.layer.cornerRadius = 5.0;
    
    self.titleLabel.text = [reward.text stringByReplacingEmojiCheatCodesWithUnicode];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    if (reward.notes && reward.notes.length > 0) {
        self.detailLabel.text = [reward.notes stringByReplacingEmojiCheatCodesWithUnicode];
        self.detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        self.titleNotesConstraint.constant = 4.0;
    } else {
        self.detailLabel.text = nil;
        self.titleNotesConstraint.constant = 0;
    }
    
    self.priceLabel.text = [reward.value stringValue];
    self.priceLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    if (self.buyButton.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBuyTap:)];
        [self.buyButton addGestureRecognizer:tapGestureRecognizer];
    }
    if ([reward.value floatValue] < 1 && [reward.value floatValue] > 0) {
        self.coinImageView.image = [UIImage imageNamed:@"silver_coin"];
        self.priceLabel.text = [NSString stringWithFormat:@"%.f", (([reward.value floatValue] - [reward.value integerValue]) * 100)];
    } else {
        self.coinImageView.image = [UIImage imageNamed:@"gold_coin"];
    }
    
    
    if ([reward.key isEqualToString:@"potion"]) {
        [self.shopImageView sd_setImageWithURL:[NSURL URLWithString:@"https://habitica-assets.s3.amazonaws.com/mobileApp/images/shop_potion.png"]
                     placeholderImage:[UIImage imageNamed:@"Placeholder"]];
    } else if ([reward.key isEqualToString:@"armoire"]) {
        [self.shopImageView sd_setImageWithURL:[NSURL URLWithString:@"https://habitica-assets.s3.amazonaws.com/mobileApp/images/shop_armoire.png"]
                     placeholderImage:[UIImage imageNamed:@"Placeholder"]];
    } else if (![reward.key isEqualToString:@"reward"]) {
        [self.shopImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://habitica-assets.s3.amazonaws.com/mobileApp/images/shop_%@.png", reward.key]]
                     placeholderImage:[UIImage imageNamed:@"Placeholder"]];
    }
    
    if ([gold floatValue] > [reward.value floatValue]) {
        self.buyView.layer.borderColor = [[UIColor purple300] CGColor];
        self.titleLabel.textColor = [UIColor blackColor];
        self.detailLabel.textColor = [UIColor gray50];
        self.priceLabel.textColor = [UIColor purple300];
        self.imageView.alpha = 1.0;
        self.backgroundColor = [UIColor whiteColor];
        self.buyButton.userInteractionEnabled = YES;
    } else {
        self.buyView.layer.borderColor = [[UIColor gray50] CGColor];
        self.titleLabel.textColor = [UIColor gray50];
        self.detailLabel.textColor = [UIColor gray50];
        self.priceLabel.textColor = [UIColor gray50];
        self.imageView.alpha = 0.8;
        self.backgroundColor = [UIColor gray500];
        self.buyButton.userInteractionEnabled = NO;
    }
}

- (void) handleBuyTap: (UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.tapAction) {
            self.tapAction();
        }
        [UIView animateWithDuration:0.15 animations:^() {
            self.buyView.backgroundColor = [UIColor purple500];
        }completion:^(BOOL completed) {
            [UIView animateWithDuration:0.15 delay:0.15 options:UIViewAnimationOptionAllowUserInteraction animations:^() {
                self.buyView.backgroundColor = [UIColor clearColor];
            }completion:nil];
        }];
    }
}

- (void)onPurchaseTap:(void (^)())actionBlock {
    self.tapAction = actionBlock;
}

@end
