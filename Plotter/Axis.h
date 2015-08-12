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

@property (nonatomic,readonly) double minValue;
@property (nonatomic,readonly) double maxValue;
@property (nonatomic,readonly) double range;
@property (nonatomic,readonly) NSArray *seriesArray;
@property (nonatomic,readonly) Grid *grid;

- (void)addSeries:(Series *)series;
- (void)updateStats;

@end
