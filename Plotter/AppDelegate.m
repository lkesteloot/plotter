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
    Data *data = [self loadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_DATA_NOTIFICATION object:data];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (Data *)loadData {
    Data *data = [[Data alloc] init];

    char buf[1024]; // XXX bad limit.
    while (gets(buf)) { // XXX Don't use gets().
	[data newLine:buf];
    }
    
    [data processData];

    return data;
}

@end
