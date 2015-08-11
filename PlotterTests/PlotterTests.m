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

- (void)testGrid {
    Grid *grid = [[Grid alloc] init];

    XCTAssertEqual([grid roundUp:1], 1, @"");
    XCTAssertEqual([grid roundUp:4], 4, @"");
    XCTAssertEqual([grid roundUp:4.1], 5, @"");
    XCTAssertEqual([grid roundUp:.99], 1, @"");
    XCTAssertEqual([grid roundUp:10], 10, @"");
    XCTAssertEqual([grid roundUp:9.9], 10, @"");
    XCTAssertEqual([grid roundUp:86], 90, @"");
    XCTAssertEqual([grid roundUp:123], 200, @"");
    XCTAssertEqual([grid roundUp:1234], 2000, @"");
}

- (void)testGridValueStrings {
    Grid *grid = [[Grid alloc] init];

    XCTAssertEqualObjects([grid gridValueLabelFor:0], @"0", @"");
    XCTAssertEqualObjects([grid gridValueLabelFor:5], @"5", @"");
    XCTAssertEqualObjects([grid gridValueLabelFor:1234], @"1,234", @"");
    XCTAssertEqualObjects([grid gridValueLabelFor:0.1], @"0.1", @"");
    XCTAssertEqualObjects([grid gridValueLabelFor:0.23], @"0.23", @"");
    XCTAssertEqualObjects([grid gridValueLabelFor:100.1], @"100.1", @"");
}

@end
