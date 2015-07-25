//
//  Series.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/24/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Series : NSObject

@property (nonatomic,readonly) int count;
@property (nonatomic,readonly) double minValue;
@property (nonatomic,readonly) double maxValue;
@property (nonatomic,readonly) double range;

- (void)addDataPoint:(double)value;
- (void)processData;

- (double)valueAt:(int)index;

@end
