//
//  HRPGTaskTableViewCell.m
//  Habitica
//
//  Created by Phillip Thelen on 05/09/15.
//  Copyright (c) 2015 Phillip Thelen. All rights reserved.
//

#import "HRPGTaskTableViewCell.h"
#import "Task.h"
#import "NSString+Emoji.h"
#import "UIColor+Habitica.h"

@implementation HRPGTaskTableViewCell

- (void)configureForTask:(Task *)task {
    self.titleLabel.text = [task.text stringByReplacingEmojiCheatCodesWithUnicode];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.titleLabel.textColor = [UIColor blackColor];
    self.subtitleLabel.textColor = [UIColor gray50];

    NSString *trimmedNotes = [task.notes stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (trimmedNotes && !trimmedNotes.length == 0) {
        self.subtitleLabel.text = trimmedNotes;
        self.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        self.titleNoteConstraint.constant = 6.0;
    } else {
        self.subtitleLabel.text = nil;
        self.titleNoteConstraint.constant = 0;
    }
    [self setNeedsLayout];
}

@end
