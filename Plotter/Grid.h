//
//  Grid.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 8/10/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>

// Represents a horizontal or vertical grid.
@interface Grid : NSObject

// The number of lines in the grid. Subtract one to get the number of intervals;
@property (nonatomic) int lineCount;

// Which line index represents zero, value-wise.
@property (nonatomic) int zeroIndex;

// The value between grid lines.
@property (nonatomic) double interval;

// The value of the first grid line.
@property (nonatomic) double start;

- (id)initForRangeWithMin:(double)minValue andMax:(double)maxValue;
- (id)initForDomainWithMin:(double)minValue andMax:(double)maxValue;

// Only publically visible for unit testing:
- (double)roundUp:(double)value;
- (double)roundDown:(double)value;

- (NSString *)gridValueLabelFor:(double)value;

@end
