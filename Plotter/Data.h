//
//  Data.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Data : NSObject

// Array of NSMutableArray of NSNumber.
@property (nonatomic) NSMutableArray *rows;
@property (nonatomic,readonly) NSUInteger rowCount;

- (void)newRow;
- (void)newValue:(double)value;

- (NSUInteger)columnsForRow:(NSUInteger)rowIndex;
- (double)valueAtRow:(NSUInteger)rowIndex andColumn:(NSUInteger)columnIndex;

@end
