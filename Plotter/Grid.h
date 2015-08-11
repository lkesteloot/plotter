//
//  Grid.h
//  Plotter
//
//  Created by Lawrence Kesteloot on 8/10/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Grid : NSObject

- (double)roundUp:(double)interval;
- (NSString *)gridValueLabelFor:(double)value;

@end
