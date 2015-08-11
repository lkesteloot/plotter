//
//  Grid.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 8/10/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Grid.h"

@interface Grid ()

@property (nonatomic) NSNumberFormatter *gridValueFormatter;

@end

@implementation Grid

- (id)init {
    self = [super init];

    if (self) {
	_gridValueFormatter = [[NSNumberFormatter alloc] init];
	[_gridValueFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[_gridValueFormatter setGroupingSize:3];
	[_gridValueFormatter setCurrencySymbol:@""];
	[_gridValueFormatter setLocale:[NSLocale currentLocale]];
	[_gridValueFormatter setMaximumFractionDigits:2];
    }

    return self;
}

- (double)roundUp:(double)interval {
    double mag = pow(10, floor(log10(interval)));
    interval = ceil(interval / mag)*mag;

    return interval;
}

- (NSString *)gridValueLabelFor:(double)value {
    return [_gridValueFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
}

@end
