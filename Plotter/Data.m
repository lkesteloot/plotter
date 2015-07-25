//
//  Data.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Data.h"

@interface Data () {
    // Array of Series objects.
    NSMutableArray *_seriesArray;

    // Used during loading.
    int _currentColumn;
    
    // The number of data points in any series (all the same).
    int _dataPointCount;
}

@end

@implementation Data

@dynamic seriesCount;
@dynamic dataPointCount;

- (id)init {
    self = [super init];

    if (self) {
	_seriesArray = [NSMutableArray array];
	_axis = [[Axis alloc] init];
	_currentColumn = 0;
	_dataPointCount = 0;
    }

    return self;
}

- (void)newRow {
    _currentColumn = 0;
    _dataPointCount++;
}

- (void)newValue:(double)value {
    // Add new Series if necessary.
    if (_currentColumn >= _seriesArray.count) {
	[_seriesArray addObject:[[Series alloc] init]];
    }

    Series *series = [_seriesArray objectAtIndex:_currentColumn];
    [series addDataPoint:value];
    _currentColumn++;
}

- (void)processData {
    for (NSUInteger i = 0; i < _seriesArray.count; i++) {
	Series *series = [_seriesArray objectAtIndex:i];
	[series processData];
	[self.axis addSeries:series];
    }
}

- (int)seriesCount {
    return (int) _seriesArray.count;
}

- (int)dataPointCount {
    return _dataPointCount;
}

- (Series *)seriesAtIndex:(int)index {
    return [_seriesArray objectAtIndex:index];
}

@end
