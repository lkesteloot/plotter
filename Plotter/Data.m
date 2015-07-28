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
    
    // Characters we use to detect a header.
    NSCharacterSet *_headerCharacterSet;
    
    // Characters we use to separate data fields.
    NSCharacterSet *_dataSeparatorCharacterSet;
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
