//
//  AppDelegate.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Data.h"

NSString *NEW_DATA_NOTIFICATION = @"NEW_DATA_NOTIFICATION";

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    BOOL nodata = [arguments containsObject:@"--nodata"];

    if (!nodata) {
	Data *data = [self loadData];
	[[NSNotificationCenter defaultCenter] postNotificationName:NEW_DATA_NOTIFICATION object:data];
    }
}

- (Data *)loadData {
    NSFileHandle *stdin = [NSFileHandle fileHandleWithStandardInput];
    NSData *inputData = [stdin readDataToEndOfFile];
    NSString *input = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
    NSArray *lines = [input componentsSeparatedByString:@"\n"];
    
    Data *data = [[Data alloc] init];
    for (NSString *line in lines) {
	[data newLine:line];
    }
    [data processData];

    return data;
}

@end
