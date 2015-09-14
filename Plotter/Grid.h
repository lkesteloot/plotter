//
//  Grid.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 8/10/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GridLine : NSObject

@property (nonatomic,readonly) double value;
@property (nonatomic,readonly) BOOL isZero;
@property (nonatomic,readonly) BOOL drawLabel;

@end


// Represents a horizontal or vertical grid.
@interface Grid : NSObject

// Array of GridLine objects.
@property (nonatomic) NSArray *gridLines;

- (id)initForRangeWithMin:(double)minValue andMax:(double)maxValue;
- (id)initForDomainWithMin:(double)minValue andMax:(double)maxValue andLog:(BOOL)log;

// Only publically visible for unit testing:
- (double)roundUp:(double)value;
- (double)roundDown:(double)value;

// Return 0.0 to 1.0 for where to plot this value.
- (CGFloat)positionFor:(double)value;

- (NSString *)gridValueLabelFor:(double)value;

@end
