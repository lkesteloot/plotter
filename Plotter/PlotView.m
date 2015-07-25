//
//  PlotView.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "PlotView.h"

#define MARGIN 40

@interface PlotView () {
    Data *_data;
    NSColor *_backgroundColor;
    NSColor *_axisColor;
    NSColor *_majorGridColor;
    NSColor *_minorGridColor;
    NSArray *_plotColors;
    
    double _minValue;
    double _maxValue;
    double _range;
    NSUInteger _rowCount;
    NSUInteger _columnCount;
}

@end

@implementation PlotView

@dynamic data;

- (void)awakeFromNib {
    _data = nil;
    _minValue = 0;
    _maxValue = 0;
    _range = 0;
    
    _backgroundColor = [NSColor colorWithRed:0.2 green:0.18 blue:0.14 alpha:1.0];
    _axisColor = [_backgroundColor blendedColorWithFraction:0.2 ofColor:[NSColor whiteColor]];
    _majorGridColor = [_backgroundColor blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]];
    _minorGridColor = [_backgroundColor blendedColorWithFraction:0.02 ofColor:[NSColor whiteColor]];
    
    NSMutableArray *plotColors = [NSMutableArray array];
    [plotColors addObject:[_backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor greenColor]]];
    [plotColors addObject:[_backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor redColor]]];
    [plotColors addObject:[_backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor cyanColor]]];
    [plotColors addObject:[_backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor yellowColor]]];
    [plotColors addObject:[_backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor purpleColor]]];
    _plotColors = plotColors;
}

- (Data *)data {
    return _data;
}

- (void)setData:(Data *)data {
    _data = data;
    
    [self calibrateData];
    
    // Redraw.
    [self setNeedsDisplay:YES];
}

- (void)calibrateData {
    _rowCount = self.data.rowCount;
    _minValue = 0;
    _maxValue = 0;
    _columnCount = 0;
    BOOL firstValue = YES;

    for (NSUInteger rowIndex = 0; rowIndex < _rowCount; rowIndex++) {
	NSUInteger rowColumnCount = [self.data columnsForRow:rowIndex];
	if (rowColumnCount > _columnCount) {
	    _columnCount = rowColumnCount;
	}
	for (NSUInteger columnIndex = 0; columnIndex < rowColumnCount; columnIndex++) {
	    double value = [self.data valueAtRow:rowIndex andColumn:columnIndex];
	    if (value > _maxValue || firstValue) {
		_maxValue = value;
	    }
	    if (value < _minValue || firstValue) {
		_minValue = value;
	    }
	    
	    firstValue = NO;
	}
    }
    _range = _maxValue - _minValue;
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];

    if (_data == nil || _range == 0) {
	// XXX Draw something.
	return;
    }

    // Plot rectangle.
    NSRect plotRect = [self bounds];
    plotRect.origin.x += MARGIN;
    plotRect.origin.y += MARGIN;
    plotRect.size.width -= MARGIN*2;
    plotRect.size.height -= MARGIN*2;

    // Background.
    [_backgroundColor set];
    NSRectFill(rect);
    
    // Grid.
    [_minorGridColor set];
    double y = floor(_minValue*10)/10;
    double lastY = ceil(_maxValue*10)/10;
    while (y <= lastY) {
	NSBezierPath *axis = [NSBezierPath bezierPath];
	CGFloat axisY = plotRect.origin.y + (y - _minValue)/_range*plotRect.size.height;
	[axis moveToPoint:NSMakePoint(plotRect.origin.x, axisY)];
	[axis lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, axisY)];
	[axis setLineWidth:1.0];
	[axis stroke];
	y += 0.1;
    }
    
    // Axes.
    [_axisColor set];
    NSBezierPath *axis = [NSBezierPath bezierPath];
    [axis moveToPoint:NSMakePoint(plotRect.origin.x, plotRect.origin.y + plotRect.size.height)];
    [axis lineToPoint:NSMakePoint(plotRect.origin.x, plotRect.origin.y)];
    CGFloat axisY = plotRect.origin.y - _minValue/_range*plotRect.size.height;
    [axis moveToPoint:NSMakePoint(plotRect.origin.x, axisY)];
    [axis lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, axisY)];
    [axis setLineWidth:1.0];
    [axis stroke];

    // Draw each column.
    for (NSUInteger columnIndex = 0; columnIndex < _columnCount; columnIndex++) {
	NSBezierPath *line = [NSBezierPath bezierPath];
	BOOL firstPoint = YES;
	
	for (NSUInteger rowIndex = 0; rowIndex < _rowCount; rowIndex++) {
	    NSUInteger rowColumnCount = [self.data columnsForRow:rowIndex];
	    if (columnIndex < rowColumnCount) {
		double value = [self.data valueAtRow:rowIndex andColumn:columnIndex];
		// XXX Doesn't handle rowCount <= 1.
		NSPoint point = NSMakePoint(
					    plotRect.origin.x + rowIndex*plotRect.size.width/(_rowCount - 1),
					    plotRect.origin.y + (value - _minValue)*plotRect.size.height/_range
		);
		if (firstPoint) {
		    [line moveToPoint:point];
		    firstPoint = NO;
		} else {
		    [line lineToPoint:point];
		}
	    }
	}
	[line setLineWidth:2.0];
	NSColor *plotColor = [_plotColors objectAtIndex:(columnIndex % _plotColors.count)];
	[plotColor set];
	
	[line stroke];
    }
}

@end
