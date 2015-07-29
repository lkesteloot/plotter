//
//  Axis.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/25/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Axis.h"

@implementation Axis

- (id)init {
    self = [super init];
    
    if (self) {
	_hasSeries = NO;
	_minValue = 0;
	_maxValue = 0;
	_range = 0;
    }
    
    return self;
}

- (void)addSeries:(Series *)series {
    if (!_hasSeries) {
	_minValue = series.minValue;
	_maxValue = series.maxValue;
	_hasSeries = YES;
    } else {
	if (series.minValue < _minValue) {
	    _minValue = series.minValue;
	}
	if (series.maxValue > _maxValue) {
	    _maxValue = series.maxValue;
	}
    }
    
    _range = _maxValue - _minValue;
}

@end
