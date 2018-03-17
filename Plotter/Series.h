//
//  Series.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/24/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, SeriesType) {
    SeriesTypeLeft,
    SeriesTypeRight,
    SeriesTypeDomain
};

// A sequence of numbers in the input data.
@interface Series : NSObject

// The number of data points.
@property (nonatomic,readonly) int count;
// Minimum value of the points.
@property (nonatomic,readonly) double minValue;
// Maximum value of the points.
@property (nonatomic,readonly) double maxValue;
// Max minus min.
@property (nonatomic,readonly) double range;
// What the series should be called, or nil if not set.
@property (nonatomic,readonly) NSString *title;
// Color used to draw this series.
@property (nonatomic) NSColor *color;
// Whether to hide this series (omit it from the plot).
@property (nonatomic,readonly) BOOL hide;
// Whether to associate the series with the left or right axes, or even the domain.
@property (nonatomic,readonly) SeriesType seriesType;
// How many derivatives to take of the raw data.
@property (nonatomic,readonly) int derivative;
// Whether to draw this as a log plot. Data must be positive.
@property (nonatomic,readonly) BOOL log;
// Whether this represents a date, and specifically a year. Causes number to not be
// drawn with a comma ("2018" instead of "2,018").
@property (nonatomic,readonly) BOOL date;
// Whether the data was implicitly generated. For the domain only, if not specified
// explicitly in the input.
@property (nonatomic) BOOL isImplicit;

- (id)init;
- (id)initAsCopyOf:(Series *)other;

// Set various data from the header (e.g., "errors [right,red]").
- (void)setHeader:(NSString *)header;
// Add another data point to the series.
- (void)addDataPoint:(double)value;
// Process the data after all data points have been added.
- (void)processData;

// Return the value of the index. Only works after processData is called.
- (double)valueAt:(int)index;

// Replaces each point with the average of it and the next point. Reduces the
// number of points by one. Does not update the stats. This is for computing the
// domains of derivative series.
- (void)replaceWithMidpoints;

// Converts the series to its derivative, using the specified series for the domain
// (i.e., what the derivative is taken with respect to).
- (void)computeDerivativeWithDomain:(Series *)domainSeries;

@end
