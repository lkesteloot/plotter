//
//  Series.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/24/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Series : NSObject

@property (nonatomic,readonly) int count;
@property (nonatomic,readonly) double minValue;
@property (nonatomic,readonly) double maxValue;
@property (nonatomic,readonly) double range;
@property (nonatomic,readonly) NSString *title;
@property (nonatomic) NSColor *color;
@property (nonatomic,readonly) BOOL hide;
@property (nonatomic,readonly) BOOL isRightAxis;

- (void)setHeader:(NSString *)header;
- (void)addDataPoint:(double)value;
- (void)processData;

- (double)valueAt:(int)index;

@end
