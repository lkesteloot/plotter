//
//  Series.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/24/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Series.h"

static NSDictionary *COLOR_MAP = nil;
static NSCharacterSet *START_OPTIONS_CHARACTER_SET = nil;
static NSCharacterSet *TERMINATE_OPTION_CHARACTER_SET = nil;

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
	_color = nil;
	_hide = NO;
	_seriesType = SeriesTypeLeft;
	_derivative = 0;
	_log = NO;
	_date = NO;
        _zero = NO;
	_isImplicit = NO;

	// Initialize static objects.
	if (START_OPTIONS_CHARACTER_SET == nil) {
	    START_OPTIONS_CHARACTER_SET = [NSCharacterSet characterSetWithCharactersInString:@"["];
	}
	if (TERMINATE_OPTION_CHARACTER_SET == nil) {
	    TERMINATE_OPTION_CHARACTER_SET = [NSCharacterSet characterSetWithCharactersInString:@",]"];
	}
	if (COLOR_MAP == nil) {
	    COLOR_MAP = @{
			  @"blue": [[NSColor blueColor] blendedColorWithFraction:0.25 ofColor:[NSColor whiteColor]],
			  @"brown": [NSColor brownColor],
			  @"cyan": [NSColor cyanColor],
			  @"gray": [NSColor grayColor],
			  @"green": [NSColor greenColor],
			  @"magenta": [NSColor magentaColor],
			  @"orange": [NSColor orangeColor],
			  @"purple": [NSColor purpleColor],
			  @"red": [NSColor redColor],
			  @"white": [NSColor whiteColor],
			  @"yellow": [NSColor yellowColor],
			  };
	}
    }
    
    return self;
}

- (id)initAsCopyOf:(Series *)other {
    self = [self init];
    
    if (self) {
	_rawData = [NSMutableArray arrayWithArray:other->_rawData];
	_count = other->_count;
	_data = malloc(sizeof(double)*_count);
	for (int i = 0; i < _count; i++) {
	    _data[i] = other->_data[i];
	}
	_minValue = other->_minValue;
	_maxValue = other->_maxValue;
	_range = other->_range;
	_color = other->_color;
	_hide = other->_hide;
	_seriesType = other->_seriesType;
	_derivative = other->_derivative;
	_log = other->_log;
        _date = other->_date;
        _zero = other->_zero;
	_isImplicit = other->_isImplicit;
    }
    
    return self;
}

- (void)dealloc {
    free(_data);
    _data = nil;
}

- (void)setHeader:(NSString *)header {
    _header = header;
    
    // Parse header.
    NSScanner *scanner = [NSScanner scannerWithString:header];
    
    // Scan title.
    NSString *title;
    [scanner scanUpToCharactersFromSet:START_OPTIONS_CHARACTER_SET intoString:&title];
    if (!scanner.atEnd) {
	// We have options. Skip open bracket.
	[scanner scanCharactersFromSet:START_OPTIONS_CHARACTER_SET intoString:nil];
	
	// Scan each option. They're comma-separated.
	while (!scanner.atEnd) {
	    NSString *option;
	    [scanner scanUpToCharactersFromSet:TERMINATE_OPTION_CHARACTER_SET intoString:&option];
	    
	    if (option.length > 0) {
		option = [option lowercaseString];
		NSColor *color = [COLOR_MAP objectForKey:option];
		if (color != nil) {
		    _color = color;
		} else if ([option isEqualToString:@"hide"]) {
		    _hide = YES;
		} else if ([option isEqualToString:@"left"]) {
		    _seriesType = SeriesTypeLeft;
		} else if ([option isEqualToString:@"right"]) {
		    _seriesType = SeriesTypeRight;
		} else if ([option isEqualToString:@"domain"]) {
		    _seriesType = SeriesTypeDomain;
		} else if ([option isEqualToString:@"derivative"]) {
		    _derivative += 1;
		} else if ([option isEqualToString:@"log"]) {
		    _log = YES;
		} else if ([option isEqualToString:@"date"]) {
		    _date = YES;
                } else if ([option isEqualToString:@"zero"]) {
                    _zero = YES;
		} else {
		    NSLog(@"Unknown header option: %@", option);
		}
	    }
	    [scanner scanCharactersFromSet:TERMINATE_OPTION_CHARACTER_SET intoString:nil];
	}
    }

    // Clean up title in case there's a trailing space before the open bracket.
    _title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)addDataPoint:(double)value {
    [_rawData addObject:[NSNumber numberWithDouble:value]];
}

- (void)processData {
    [self convertToDoubles];
    [self computeStats];
}

- (void)convertToDoubles {
    // Convert to C array to avoid boxing/unboxing.
    _count = (int) _rawData.count;
    _data = malloc(sizeof(double)*_count);

    for (int i = 0; i < _count; i++) {
	NSNumber *number = [_rawData objectAtIndex:i];
	double value = [number doubleValue];
	_data[i] = value;
    }
    
    // Free this, we no longer need it.
    _rawData = nil;
}

- (void)computeStats {
    // Gather statistics.
    _minValue = 0;
    _maxValue = 0;

    for (int i = 0; i < _count; i++) {
	double value = _data[i];

	if (i == 0 && !_zero) {
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

    _range = _maxValue - _minValue;
}

- (double)valueAt:(int)index {
    return _data[index];
}

- (void)replaceWithMidpoints {
    if (_count > 0) {
	for (int i = 0; i < _count - 1; i++) {
	    _data[i] = (_data[i] + _data[i + 1])/2;
	}
	
	_count--;
    }
}

- (void)computeDerivativeWithDomain:(Series *)domainSeries {
    if (_count > 0) {
	for (int i = 0; i < _count - 1; i++) {
	    double dx = [domainSeries valueAt:(i + 1)] - [domainSeries valueAt:i];
	    if (dx == 0) {
		_data[i] = 0;
	    } else {
		_data[i] = (_data[i + 1] - _data[i])/dx;
	    }
	}
	
	_count--;
	_title = [_title stringByAppendingString:@"’"];
    }

    [self computeStats];
}

@end
