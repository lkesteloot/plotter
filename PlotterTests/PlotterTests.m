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

- (void)testGridRange {
    Grid *grid;

    grid = [[Grid alloc] initForRangeWithMin:0 andMax:5];
    XCTAssertEqual(grid.interval, 1.5);
    XCTAssertEqual(grid.start, 0);
    XCTAssertEqual(grid.zeroIndex, 0);

    grid = [[Grid alloc] initForRangeWithMin:-1 andMax:24];
    XCTAssertEqual(grid.interval, 8);
    XCTAssertEqual(grid.start, -8);
    XCTAssertEqual(grid.zeroIndex, 1);

    grid = [[Grid alloc] initForRangeWithMin:-92.5853 andMax:2450.74];
    XCTAssertEqual(grid.interval, 1000);
    XCTAssertEqual(grid.start, -1000);
    XCTAssertEqual(grid.zeroIndex, 1);
}

- (void)testGridDomain {
    Grid *grid;

    grid = [[Grid alloc] initForDomainWithMin:0 andMax:4];
    XCTAssertEqual(grid.lineCount, 5);
    XCTAssertEqual(grid.interval, 1);
    XCTAssertEqual(grid.start, 0);
    XCTAssertEqual(grid.zeroIndex, 0);

    grid = [[Grid alloc] initForDomainWithMin:0 andMax:4.1];
    XCTAssertEqual(grid.lineCount, 5);
    XCTAssertEqual(grid.interval, 1);
    XCTAssertEqual(grid.start, 0);
    XCTAssertEqual(grid.zeroIndex, 0);

    grid = [[Grid alloc] initForDomainWithMin:-0.1 andMax:4];
    XCTAssertEqual(grid.lineCount, 5);
    XCTAssertEqual(grid.interval, 1);
    XCTAssertEqual(grid.start, 0);
    XCTAssertEqual(grid.zeroIndex, 0);

    grid = [[Grid alloc] initForDomainWithMin:-0.1 andMax:30.1];
    XCTAssertEqual(grid.lineCount, 5);
    XCTAssertEqual(grid.interval, 7.5);
    XCTAssertEqual(grid.start, 0);
    XCTAssertEqual(grid.zeroIndex, 0);
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
