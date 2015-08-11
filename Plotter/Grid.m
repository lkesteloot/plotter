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

- (id)initForRangeWithMin:(double)minValue andMax:(double)maxValue {
    self = [self init];

    if (self) {
	// Unlike the domain, the data lines don't necessary go all the way to the
	// top and bottom of the plot area. We always force the range to have
	// five grid lines spaced evenly, and we scale the data to fit. For each axis:
	//
	// - The intervals are chosen from a set of nice numbers.
	// - The intervals go through 0.
	// - The data should be as large as possible vertically.
	// - If the range of the range is 0, include 0 in the plot.

	_lineCount = 5;

	// Figure out the range (max - min). It must never be zero.
	double range = maxValue - minValue;
	if (range == 0) {
	    // Include 0 in the plot.
	    range = fabs(minValue);
	    if (range == 0) {
		// Integer grid lines.
		range = 4;
	    }
	}

	// Initial guess for an interval.
	double interval = range / (_lineCount - 1);

	// Round up to the nearest nice number.
	interval = [self roundUp:interval];
	double start = floor(minValue/interval)*interval;

	// See if we fit the range.
	while (start + interval*(_lineCount - 1) < maxValue) {
	    // The floor for "start" made it so that we don't fit.
	    // Add that error to our range.
	    double newRange = range + minValue - start;

	    // And recompute.
	    interval = newRange / (_lineCount - 1);
	    interval = [self roundUp:interval];
	    start = floor(minValue/interval)*interval;
	}

	_interval = interval;
	_start = start;
	_zeroIndex = (int) floor((0 - _start)/interval + 0.5);
    }

    return self;
}

- (double)roundUp:(double)value {
    double decade = pow(10, floor(log10(value)));
    value = ceil(value / decade)*decade;

    return value;
}

- (NSString *)gridValueLabelFor:(double)value {
    return [_gridValueFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
}

@end
