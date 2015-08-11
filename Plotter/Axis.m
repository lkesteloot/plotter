//
//  Axis.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/25/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Axis.h"

@interface Axis () {
    NSMutableArray *_seriesArray;
}

@end

@implementation Axis

@dynamic seriesArray;

- (id)init {
    self = [super init];
    
    if (self) {
	_minValue = 0;
	_maxValue = 0;
	_range = 0;
	_grid = nil;
	_seriesArray = [NSMutableArray array];
    }
    
    return self;
}

- (void)addSeries:(Series *)series {
    [_seriesArray addObject:series];
}

- (void)updateStats {
    BOOL first = YES;

    for (Series *series in _seriesArray) {
	if (first) {
	    _minValue = series.minValue;
	    _maxValue = series.maxValue;
	    first = NO;
	} else {
	    if (series.minValue < _minValue) {
		_minValue = series.minValue;
	    }
	    if (series.maxValue > _maxValue) {
		_maxValue = series.maxValue;
	    }
	}
    }

    _range = _maxValue - _minValue;

    _grid = [[Grid alloc] initForRangeWithMin:_minValue andMax:_maxValue];
}

- (NSArray *)seriesArray {
    return _seriesArray;
}

@end
