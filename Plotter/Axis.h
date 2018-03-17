//
//  Axis.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/25/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Series.h"
#import "Grid.h"

// Left or right vertical axis.
@interface Axis : NSObject

// The lowest value we must display.
@property (nonatomic,readonly) double minValue;
// The largest value we must display.
@property (nonatomic,readonly) double maxValue;
// Max minus min.
@property (nonatomic,readonly) double range;
// The series displayed by this axis.
@property (nonatomic,readonly) NSArray *seriesArray;
// The grid used for this axis.
@property (nonatomic,readonly) Grid *grid;

// Add another series to be displayed by this axis.
- (void)addSeries:(Series *)series;
// Update the stats and creates the grid after all series have been added.
- (void)updateStats;

@end
