//
//  Series.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/24/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Series.h"

static NSDictionary *COLOR_MAP = nil;

@interface Series () {
    NSString *_header;
    NSMutableArray *_rawData;
    double *_data;

    NSCharacterSet *_startOptionsCharacterSet;
    NSCharacterSet *_terminateOptionCharacterSet;
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

	// Start of options.
	_startOptionsCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"["];
	_terminateOptionCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@",]"];
	
	if (COLOR_MAP == nil) {
	    COLOR_MAP = @{
			  @"blue": [NSColor blueColor],
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
    [scanner scanUpToCharactersFromSet:_startOptionsCharacterSet intoString:&title];
    if (!scanner.atEnd) {
	// We have options. Skip open bracket.
	[scanner scanCharactersFromSet:_startOptionsCharacterSet intoString:nil];
	
	// Scan each option. They're comma-separated.
	while (!scanner.atEnd) {
	    NSString *option;
	    [scanner scanUpToCharactersFromSet:_terminateOptionCharacterSet intoString:&option];
	    
	    if (option.length > 0) {
		option = [option lowercaseString];
		NSColor *color = [COLOR_MAP objectForKey:option];
		if (color != nil) {
		    _color = color;
		} else if ([option isEqualToString:@"hide"]) {
		    _hide = YES;
		} else {
		    NSLog(@"Unknown header option: %@", option);
		}
	    }
	    [scanner scanCharactersFromSet:_terminateOptionCharacterSet intoString:nil];
	}
    }

    // Clean up title in case there's a trailing space before the open bracket.
    _title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
