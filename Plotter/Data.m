//
//  Data.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Data.h"

@interface Data () {
    NSMutableArray *_seriesArray;

    // Used during loading.
    int _currentColumn;
    BOOL _firstLine;
    
    // The number of data points in any series (all the same).
    int _dataPointCount;
    
    // Characters we use to detect a header.
    NSCharacterSet *_headerCharacterSet;
    
    // Characters we use to separate data fields.
    NSCharacterSet *_dataSeparatorCharacterSet;
}

@end

@implementation Data

@dynamic dataPointCount;

- (id)init {
    self = [super init];

    if (self) {
	_seriesArray = [NSMutableArray array];
	_leftAxis = [[Axis alloc] init];
	_rightAxis = [[Axis alloc] init];
	_currentColumn = 0;
	_firstLine = YES;
	_dataPointCount = 0;
	
	// All letters except for "e", which might be an exponent (123e4). Also include brackets so that
	// if the user wants to have a header that's entirely numeric, they can add empty options to force
	// it to be recognized as a header.
	_headerCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdfghijklmnopqrstuvwxyz[]"];
	
	// Currently either spaces or tabs, though we should be more robust about this.
	_dataSeparatorCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t"];
    }

    return self;
}

- (void)newLine:(NSString *)line {
    // If it's the first line we see, and it contains letter, then it's a header row.
    if (_firstLine) {
	_firstLine = NO;
	if ([self containsLetters:line]) {
	    [self parseHeader:line];
	    return;
	}
    }

    // Else parse it as a data row. These can be separated by tabs or spaces.
    [self newRow];
    NSScanner *scanner = [NSScanner scannerWithString:line];
    while (!scanner.atEnd) {
	// Skip whitespace.
	[scanner scanCharactersFromSet:_dataSeparatorCharacterSet intoString:nil];
	
	// Scan a double.
	double value;
	BOOL success = [scanner scanDouble:&value];
	if (success) {
	    [self newValue:value];
	}
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
- (BOOL)containsLetters:(NSString *)line {
    NSRange range = [line rangeOfCharacterFromSet:_headerCharacterSet options:NSCaseInsensitiveSearch];
    return range.location != NSNotFound;
}

// Parse the header row. The headers must be separated by tabs.
- (void)parseHeader:(NSString *)line {
    NSArray *headers = [line componentsSeparatedByString:@"\t"];
    
    for (NSString *header in headers) {
	Series *series = [self getNextSeries];
	[series setHeader:header];
    }
}

- (void)processData {
    // Remove hidden series.
    NSMutableArray *newSeriesArray = [NSMutableArray array];
    for (Series *series in _seriesArray) {
	if (!series.hide) {
	    [newSeriesArray addObject:series];
	}
    }
    _seriesArray = newSeriesArray;
    _domainSeries = nil;

    // Process and make axes.
    for (Series *series in _seriesArray) {
	[series processData];
	switch (series.seriesType) {
	    case SeriesTypeLeft:
		[self.leftAxis addSeries:series];
		break;
		
	    case SeriesTypeRight:
		[self.rightAxis addSeries:series];
		break;
		
	    case SeriesTypeDomain:
		if (_domainSeries != nil) {
		    NSLog(@"Cannot have more than one domain series.");
		} else {
		    _domainSeries = series;
		}
		break;
	}
    }
    
    // Generate a domain series if one wasn't specified.
    if (_domainSeries == nil) {
	_domainSeries = [[Series alloc] init];

	// One point for each line.
	for (int i = 1; i <= _dataPointCount; i++) {
	    [_domainSeries addDataPoint:i];
	}
	[_domainSeries processData];
    }
}

- (int)dataPointCount {
    return _dataPointCount;
}

@end
