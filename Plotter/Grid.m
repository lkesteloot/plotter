//
//  Grid.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 8/10/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Grid.h"

// The set of numbers that we can use for grid values.
static double VALID_VALUES[] = { 1, 1.5, 2, 3, 4, 5, 6, 7.5, 8, 10 };
static int VALID_VALUE_COUNT = sizeof(VALID_VALUES)/sizeof(VALID_VALUES[0]);

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

- (id)initForDomainWithMin:(double)minValue andMax:(double)maxValue {
    self = [self init];

    if (self) {
	// The data lines themselves always go from the
	// far left to the far right of the plot. We choose grid value intervals
	// such that:
	//
	// - There are as few grid lines as possible.
	// - There are always at least five grid lines.
	// - The intervals are chosen from a set of nice numbers.
	// - The intervals go through 0.

	// Compute the range of values.
	double range = maxValue - minValue;
	if (range == 0) {
	    range = 4;
	}

	// At least five lines.
	_interval = [self roundDown:range / 4];

	// Start after the min value.
	_start = ceil(minValue/_interval)*_interval;

	// End after the max value.
	double last = floor(maxValue/_interval)*_interval;
	_lineCount = (int) floor((last - _start)/_interval + 0.5) + 1;

	// Figure out the zero line, if any.
	_zeroIndex = (int) floor((0 - _start)/_interval + 0.5);
    }

    return self;
}

- (double)roundUp:(double)value {
    double decade = pow(10, floor(log10(value)));

    value /= decade;

    // This will always break because we include "10" in the list:
    for (int i = 0; i < VALID_VALUE_COUNT; i++) {
	if (VALID_VALUES[i] >= value) {
	    value = VALID_VALUES[i];
	    break;
	}
    }

    value *= decade;

    return value;
}

- (double)roundDown:(double)value {
    double decade = pow(10, floor(log10(value)));

    value /= decade;

    // This will always break because we include "1" in the list:
    for (int i = VALID_VALUE_COUNT - 1; i >= 0; i--) {
	if (VALID_VALUES[i] <= value) {
	    value = VALID_VALUES[i];
	    break;
	}
    }

    value *= decade;

    return value;
}

- (NSString *)gridValueLabelFor:(double)value {
    return [_gridValueFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
}

@end
