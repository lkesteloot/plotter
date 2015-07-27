//
//  Series.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/24/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Series.h"

@interface Series () {
    NSString *_header;
    NSMutableArray *_rawData;
    double *_data;
}

@end

@implementation Series

- (id)init {
    self = [super init];
    
    if (self) {
	_rawData = [NSMutableArray array];
	_count = 0;
	_data = nil;
	_minValue = 0;
	_maxValue = 0;
	_range = 0;
    }
    
    return self;
}

- (void)dealloc {
    free(_data);
    _data = nil;
}

- (void)setHeader:(NSString *)header {
    _header = header;
    _title = header;
}

- (void)addDataPoint:(double)value {
    [_rawData addObject:[NSNumber numberWithDouble:value]];
}

- (void)processData {
    // Convert to C array to avoid boxing/unboxing.
    _count = (int) _rawData.count;
    _data = malloc(sizeof(double)*_count);

    // Gather statistics.
    _minValue = 0;
    _maxValue = 0;

    for (int i = 0; i < _count; i++) {
	NSNumber *number = [_rawData objectAtIndex:i];
	double value = [number doubleValue];
	_data[i] = value;
	
	if (i == 0) {
	    _minValue = value;
	    _maxValue = value;
	} else {
	    if (value < _minValue) {
		_minValue = value;
	    }
	    if (value > _maxValue) {
		_maxValue = value;
	    }
	}
    }
    
    // Free this, we no longer need it.
    _rawData = nil;

    _range = _maxValue - _minValue;
}

- (double)valueAt:(int)index {
    return _data[index];
}

@end
