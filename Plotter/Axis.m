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
	_seriesArray = [NSMutableArray array];
    }
    
    return self;
}

- (void)addSeries:(Series *)series {
    if (_seriesArray.count == 0) {
	_minValue = series.minValue;
	_maxValue = series.maxValue;
    } else {
	if (series.minValue < _minValue) {
	    _minValue = series.minValue;
	}
	if (series.maxValue > _maxValue) {
	    _maxValue = series.maxValue;
	}
    }
    
    _range = _maxValue - _minValue;

    [_seriesArray addObject:series];
}

- (NSArray *)seriesArray {
    return _seriesArray;
}

@end
