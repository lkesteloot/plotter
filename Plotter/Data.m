//
//  Data.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "Data.h"

@implementation Data

@dynamic rowCount;

- (id)init {
    self = [super init];

    if (self) {
	_rows = [NSMutableArray array];
    }

    return self;
}

- (void)newRow {
    [self.rows addObject:[NSMutableArray array]];
}

- (void)newValue:(double)value {
    NSMutableArray *lastRow = [self.rows lastObject];
    if (lastRow == nil) {
	@throw([NSException exceptionWithName:@"empty data" reason:@"must call newRow first" userInfo:nil]);
    }

    [lastRow addObject:[NSNumber numberWithDouble:value]];
}

- (NSUInteger)rowCount {
    return self.rows.count;
}

- (NSUInteger)columnsForRow:(NSUInteger)rowIndex {
    NSArray *row = [self.rows objectAtIndex:rowIndex];
    return row.count;
}

- (double)valueAtRow:(NSUInteger)rowIndex andColumn:(NSUInteger)columnIndex {
    NSArray *row = [self.rows objectAtIndex:rowIndex];
    NSNumber *value = [row objectAtIndex:columnIndex];
    return [value doubleValue];
}

@end
