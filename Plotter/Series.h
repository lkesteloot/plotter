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

@interface Series : NSObject

@property (nonatomic,readonly) int count;
@property (nonatomic,readonly) double minValue;
@property (nonatomic,readonly) double maxValue;
@property (nonatomic,readonly) double range;
@property (nonatomic,readonly) NSString *title;
@property (nonatomic) NSColor *color;
@property (nonatomic,readonly) BOOL hide;
@property (nonatomic,readonly) SeriesType seriesType;
@property (nonatomic,readonly) int derivative;

- (id)init;
- (id)initAsCopyOf:(Series *)other;

- (void)setHeader:(NSString *)header;
- (void)addDataPoint:(double)value;
- (void)processData;

- (double)valueAt:(int)index;

// Does not change the stats.
- (void)replaceWithMidpoints;

- (void)computeDerivativeWithDomain:(Series *)domainSeries;

@end
