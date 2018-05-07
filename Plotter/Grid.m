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

@implementation GridLine

- (id)initWithValue:(double)value isZero:(BOOL)isZero drawLabel:(BOOL)drawLabel {
    self = [super init];

    if (self) {
	_value = value;
	_isZero = isZero;
	_drawLabel = drawLabel;
    }

    return self;
}

@end

@interface Grid ()

@property (nonatomic, readonly) BOOL log;
@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;
@property (nonatomic) double logMinValue;
@property (nonatomic) double logMaxValue;
@property (nonatomic) NSNumberFormatter *gridValueFormatter;

@end

@implementation Grid

- (id)init {
    self = [super init];

    if (self) {
	_gridLines = [NSMutableArray array];
	_logMinValue = 0;
	_logMaxValue = 0;

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
	NSMutableArray *gridLines = (NSMutableArray *) _gridLines;

	_log = NO;

	// Unlike the domain, the data lines don't necessary go all the way to the
	// top and bottom of the plot area. We always force the range to have
	// five grid lines spaced evenly, and we scale the data to fit. For each axis:
	//
	// - The intervals are chosen from a set of nice numbers.
	// - The intervals go through 0.
	// - The data should be as large as possible vertically.
	// - If the range of the range is 0, include 0 in the plot.

	int lineCount = 5;

	// Figure out the range (max - min). It must never be zero.
	double range = maxValue - minValue;
	if (range == 0) {
	    // All data is the same. Include 0 in the plot.
	    range = fabs(minValue);
	    if (range == 0) {
		// All data is zero. Just pick integer grid lines.
		range = 4;
	    }
	}

	// Initial guess for an interval.
	double interval = range / (lineCount - 1);

	// Round up to the nearest nice number.
	interval = [self roundUp:interval];
	double start = floor(minValue/interval)*interval;

	// See if we fit the range.
	while (start + interval*(lineCount - 1) < maxValue) {
	    // The floor for "start" made it so that we don't fit.
	    // Add that error to our range.
	    double newRange = range + minValue - start;

	    // And recompute.
	    interval = newRange / (lineCount - 1);
	    interval = [self roundUp:interval];
	    start = floor(minValue/interval)*interval;
	}

	int zeroIndex = (int) floor((0 - start)/interval + 0.5);

	for (int i = 0; i < lineCount; i++) {
	    double value = start + interval*i;
	    [gridLines addObject:[[GridLine alloc] initWithValue:value isZero:(i == zeroIndex) drawLabel:YES]];
	}

	_minValue = start;
	_maxValue = start + (lineCount - 1)*interval;
    }

    return self;
}

- (id)initForDomainWithMin:(double)minValue andMax:(double)maxValue andLog:(BOOL)log {
    self = [self init];

    if (self) {
	// The data lines themselves always go from the
	// far left to the far right of the plot.
	_minValue = minValue;
	_maxValue = maxValue;
	_log = log;

	NSMutableArray *gridLines = (NSMutableArray *) _gridLines;

	if (_log) {
	    // We have one grid line for each most-significant digit
	    // (e.g., 1, 2, 3, ..., 9, 10, 20, 30, ..., 80, 90, 100, 200, ...).

	    if (minValue <= 0 || maxValue <= 0) {
		NSLog(@"Log plots require positive values.");
		exit(1);
	    }

	    // Compute the first line we draw.

	    // E.g., 343 will return 100 here.
	    double decade = pow(10, floor(log10(minValue)));

	    // E.g., 343 will return 4 here (for "400").
	    int digit = (int) ceil(minValue / decade);

	    _logMinValue = log10(minValue);
	    _logMaxValue = log10(maxValue);

	    while (YES) {
		if (digit == 10) {
		    digit = 1;
		    decade *= 10;
		}

		double value = digit*decade;
		if (value > maxValue) {
		    break;
		}

		[gridLines addObject:[[GridLine alloc] initWithValue:value isZero:NO drawLabel:(digit == 1)]];
		digit += 1;
	    }
	} else {
	    // We choose grid value intervals such that:
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
	    double interval = [self roundDown:range / 4];

	    // Start after the min value.
	    double start = ceil(minValue/interval)*interval;

	    // End after the max value.
	    double last = floor(maxValue/interval)*interval;
	    int lineCount = (int) floor((last - start)/interval + 0.5) + 1;

	    // Figure out the zero line, if any.
	    int zeroIndex = (int) floor((0 - start)/interval + 0.5);

	    for (int i = 0; i < lineCount; i++) {
		double value = start + interval*i;
		[gridLines addObject:[[GridLine alloc] initWithValue:value isZero:(i == zeroIndex) drawLabel:YES]];
	    }
	}
    }

    return self;
}

// Round up to the next higher (or equal) value in VALID_VALUES (accounting
// for order of magnitude).
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

// Round down to the next lower (or equal) value in VALID_VALUES (accounting
// for order of magnitude).
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

- (CGFloat)positionForValue:(double)value {
    double position;

    if (_log) {
	double logValue = log10(value);

	position = (logValue - _logMinValue) / (_logMaxValue - _logMinValue);
    } else {
	position = (value - _minValue) / (_maxValue - _minValue);
    }

    return position;
}

- (double)valueForPosition:(CGFloat)position {
    double value;

    if (_log) {
        // Untested.
        double logValue = position*(_logMaxValue - _logMinValue) + _logMinValue;
        value = pow(10, logValue);
    } else {
        value = position*(_maxValue - _minValue) + _minValue;
    }

    return value;
}

- (NSString *)gridValueLabelFor:(double)value isDate:(BOOL)isDate {
    if (isDate) {
	[_gridValueFormatter setGroupingSize:0];
    } else {
	[_gridValueFormatter setGroupingSize:3];
    }
    return [_gridValueFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
}

@end
