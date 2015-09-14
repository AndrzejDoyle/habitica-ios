//
//  NSDate+DaysSince.m
//  Habitica
//
//  Created by Phillip Thelen on 11/04/15.
//  Copyright (c) 2015 Phillip Thelen. All rights reserved.
//

#import "NSDate+DaysSince.h"

@implementation NSDate (Screenshot)

- (NSNumber*)daysSinceDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    if (date == nil) {
        date = [NSDate date];
    }

    NSDate *fromDate;
    NSDate *toDate;
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:date];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:self];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [NSNumber numberWithInteger:[difference day]];
}

@end

