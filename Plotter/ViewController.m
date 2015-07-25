//
//  ViewController.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "ViewController.h"
#import "PlotView.h"
#import "AppDelegate.h"

@interface ViewController ()

// Override with more specific type.
@property (nonatomic) PlotView *view;

@end


@implementation ViewController

@dynamic view;

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(dataChanged:)
						 name:NEW_DATA_NOTIFICATION
					       object:nil];

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (void)dataChanged:(NSNotification *)notification {
    Data *data = notification.object;
    self.view.data = data;
}

@end
