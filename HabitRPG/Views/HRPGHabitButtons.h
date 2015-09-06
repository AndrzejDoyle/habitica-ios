//
//  HRPGHabitButton.h
//  Habitica
//
//  Created by viirus on 22.03.15.
//  Copyright (c) 2015 Phillip Thelen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task.h"

@interface HRPGHabitButtons : UIView

- (void)configureForTask:(Task *) task;

- (void)onUpAction:(void (^)())actionBlock;
- (void)onDownAction:(void (^)())actionBlock;

@end
