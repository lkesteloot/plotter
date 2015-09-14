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
    
    // Domain series for derivative n.
    NSMutableArray *_derivativeDomainSeries;
    
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
	_derivativeDomainSeries = [NSMutableArray array];
	_domainGrid = nil;

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
		if (_derivativeDomainSeries.count != 0) {
		    NSLog(@"Cannot have more than one domain series.");
		} else {
		    [_derivativeDomainSeries addObject:series];
		}
		break;
	}
    }
    
    // Generate a domain series if one wasn't specified.
    if (_derivativeDomainSeries.count == 0) {
	Series *domainSeries = [[Series alloc] init];

	domainSeries.isImplicit = YES;

	// One point for each line.
	for (int i = 1; i <= _dataPointCount; i++) {
	    [domainSeries addDataPoint:i];
	}
	[domainSeries processData];
	
	[_derivativeDomainSeries addObject:domainSeries];
    }
    
    // Generate domain series for derivative range series.
    for (Series *series in _seriesArray) {
	int derivative = series.derivative;
	
	// Compute derivatives up to needed one, so we don't have any nils, which aren't allowed by NSArray.
	for (int d = (int) _derivativeDomainSeries.count; d <= derivative; d++) {
	    Series *previousDomain = [_derivativeDomainSeries objectAtIndex:(d - 1)];
	    Series *newDomain = [[Series alloc] initAsCopyOf:previousDomain];
	    
	    [newDomain replaceWithMidpoints];

	    [_derivativeDomainSeries addObject:newDomain];
	}
    }
    
    // Generate derivatives of range series.
    for (Series *series in _seriesArray) {
	if (series.seriesType != SeriesTypeDomain) {
	    for (int d = 0; d < series.derivative; d++) {
		Series *domainSeries = [_derivativeDomainSeries objectAtIndex:d];
		[series computeDerivativeWithDomain:domainSeries];
	    }
	}
    }
    
    // Compute axis stats now that we've computed the derivatives. Also computes the vertical grid.
    [_leftAxis updateStats];
    [_rightAxis updateStats];

    // Compute the domain grid lines we'll be showing when plotting.
    Series *domainSeries = [_derivativeDomainSeries objectAtIndex:0];
    _domainGrid = [[Grid alloc] initForDomainWithMin:domainSeries.minValue andMax:domainSeries.maxValue andLog:domainSeries.log];
}

- (int)dataPointCount {
    return _dataPointCount;
}

- (Series *)domainSeriesForDerivative:(int)derivative {
    return [_derivativeDomainSeries objectAtIndex:derivative];
}

@end
