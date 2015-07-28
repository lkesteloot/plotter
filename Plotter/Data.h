//
//  Data.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Series.h"
#import "Axis.h"

@interface Data : NSObject

// To fill the data.
- (void)newLine:(NSString *)line;
- (void)newRow;
- (void)newValue:(double)value;

// To process the data once filled.
- (void)processData;

// To fetch the data. Every series will have the same number of data points.
@property (nonatomic,readonly) int seriesCount;
@property (nonatomic,readonly) int dataPointCount;
- (Series *)seriesAtIndex:(int)index;

// Plot info.
@property (nonatomic,readonly) Axis *axis;

@end
