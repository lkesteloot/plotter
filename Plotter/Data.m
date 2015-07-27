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
    BOOL _firstLine;
    
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
	_firstLine = YES;
	_dataPointCount = 0;
    }

    return self;
}

- (void)newLine:(char *)line {
    char *s = line;
    
    // If it's the first line we see, and it contains letter, then it's a header row.
    if (_firstLine) {
	_firstLine = NO;
	if ([self containsLetters:line]) {
	    [self parseHeader:line];
	    return;
	}
    }

    [self newRow];
    while (YES) {
	char *end;
	double value = strtod(s, &end);
	if (end == s) {
	    break;
	}
	s = end;
	[self newValue:value];
    }
}

- (void)newRow {
    _currentColumn = 0;
    _dataPointCount++;
}

- (void)newValue:(double)value {
    Series *series = [self getNextSeries];
    [series addDataPoint:value];
}

- (Series *)getNextSeries {
    // Add new Series if necessary.
    if (_currentColumn >= _seriesArray.count) {
	[_seriesArray addObject:[[Series alloc] init]];
    }
    
    return [_seriesArray objectAtIndex:_currentColumn++];
}

// Whether this line contains letters. Skip the letter "e" because that
// could be the exponential (123e3). Also note that if the output
// contains "NaN" we'll think it's a title, but in that case the data
// is wrecked anyway.
- (BOOL)containsLetters:(char *)line {
    while (line != '\0') {
	char ch = tolower(*line);
	if (isalpha(ch) && ch != 'e') {
	    return YES;
	}
	
	line++;
    }

    return NO;
}

// Parse the header row. The headers must be separated by tabs.
- (void)parseHeader:(char *)line {
    while (*line != '\0') {
	char *header = line;

	char *tab = strchr(line, '\t');
	if (tab == nil) {
	    line = line + strlen(line);
	} else {
	    *tab = '\0';
	    line = tab + 1;
	}

	Series *series = [self getNextSeries];
	[series setHeader:[NSString stringWithCString:header encoding:NSUTF8StringEncoding]];
    }
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
