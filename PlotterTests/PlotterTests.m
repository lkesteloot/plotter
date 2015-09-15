//
//  PlotterTests.m
//  PlotterTests
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "Grid.h"

@interface PlotterTests : XCTestCase

@end

@implementation PlotterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGridRoundUp {
    Grid *grid = [[Grid alloc] init];

    XCTAssertEqual([grid roundUp:1], 1);
    XCTAssertEqual([grid roundUp:4], 4);
    XCTAssertEqual([grid roundUp:4.1], 5);
    XCTAssertEqual([grid roundUp:.99], 1);
    XCTAssertEqual([grid roundUp:10], 10);
    XCTAssertEqual([grid roundUp:9.9], 10);
    XCTAssertEqual([grid roundUp:86], 100);
    XCTAssertEqual([grid roundUp:123], 150);
    XCTAssertEqual([grid roundUp:1234], 1500);
}

- (void)testGridRoundDown {
    Grid *grid = [[Grid alloc] init];

    XCTAssertEqual([grid roundDown:1], 1);
    XCTAssertEqual([grid roundDown:4], 4);
    XCTAssertEqual([grid roundDown:4.1], 4);
    XCTAssertEqual([grid roundDown:3.9], 3);
    XCTAssertEqual([grid roundDown:.99], .8);
    XCTAssertEqual([grid roundDown:10], 10);
    XCTAssertEqual([grid roundDown:9.9], 8);
    XCTAssertEqual([grid roundDown:86], 80);
    XCTAssertEqual([grid roundDown:123], 100);
    XCTAssertEqual([grid roundDown:1234], 1000);
}

- (void)checkGridLine:(Grid *)grid atIndex:(int)index hasValue:(double)value isZero:(BOOL)isZero drawLabel:(BOOL)drawLabel {

    GridLine *gridLine = [grid.gridLines objectAtIndex:index];

    XCTAssertEqual(gridLine.value, value);
    XCTAssertEqual(gridLine.isZero, isZero);
    XCTAssertEqual(gridLine.drawLabel, drawLabel);
}

- (void)testGridRange {
    Grid *grid;

    grid = [[Grid alloc] initForRangeWithMin:0 andMax:5];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:1.5 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:3 isZero:NO drawLabel:YES];

    grid = [[Grid alloc] initForRangeWithMin:-1 andMax:24];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:-8 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:8 isZero:NO drawLabel:YES];

    grid = [[Grid alloc] initForRangeWithMin:-92.5853 andMax:2450.74];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:-1000 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:1000 isZero:NO drawLabel:YES];
}

- (void)testGridDomain {
    Grid *grid;

    grid = [[Grid alloc] initForDomainWithMin:0 andMax:4 andLog:NO];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:1 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:2 isZero:NO drawLabel:YES];

    grid = [[Grid alloc] initForDomainWithMin:0 andMax:4.1 andLog:NO];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:1 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:2 isZero:NO drawLabel:YES];

    grid = [[Grid alloc] initForDomainWithMin:-0.1 andMax:4 andLog:NO];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:1 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:2 isZero:NO drawLabel:YES];

    grid = [[Grid alloc] initForDomainWithMin:-0.1 andMax:30.1 andLog:NO];
    XCTAssertEqual(grid.gridLines.count, 5);
    [self checkGridLine:grid atIndex:0 hasValue:0 isZero:YES drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:7.5 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:2 hasValue:15 isZero:NO drawLabel:YES];

    grid = [[Grid alloc] initForDomainWithMin:1 andMax:1000 andLog:YES];
    XCTAssertEqual(grid.gridLines.count, 28);
    [self checkGridLine:grid atIndex:0 hasValue:1 isZero:NO drawLabel:YES];
    [self checkGridLine:grid atIndex:1 hasValue:2 isZero:NO drawLabel:NO];
    [self checkGridLine:grid atIndex:2 hasValue:3 isZero:NO drawLabel:NO];
    [self checkGridLine:grid atIndex:27 hasValue:1000 isZero:NO drawLabel:YES];
}

- (void)testGridValueStrings {
    Grid *grid = [[Grid alloc] init];

    XCTAssertEqualObjects([grid gridValueLabelFor:0], @"0");
    XCTAssertEqualObjects([grid gridValueLabelFor:5], @"5");
    XCTAssertEqualObjects([grid gridValueLabelFor:1234], @"1,234");
    XCTAssertEqualObjects([grid gridValueLabelFor:0.1], @"0.1");
    XCTAssertEqualObjects([grid gridValueLabelFor:0.23], @"0.23");
    XCTAssertEqualObjects([grid gridValueLabelFor:100.1], @"100.1");
}

@end
