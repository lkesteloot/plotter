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
    NSColor *_legendColor;
    NSFont *_legendFont;
    NSArray *_plotColors;
}

@end

@implementation PlotView

@dynamic data;

- (void)awakeFromNib {
    _data = nil;
    
    _backgroundColor = [NSColor colorWithRed:0.2 green:0.18 blue:0.14 alpha:1.0];
    _axisColor = [_backgroundColor blendedColorWithFraction:0.2 ofColor:[NSColor whiteColor]];
    _majorGridColor = [_backgroundColor blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]];
    _minorGridColor = [_backgroundColor blendedColorWithFraction:0.03 ofColor:[NSColor whiteColor]];
    _legendColor = [_backgroundColor blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]];
    _legendFont = [NSFont fontWithName:@"Helvetica" size:14];
}

- (Data *)data {
    return _data;
}

- (void)setData:(Data *)data {
    _data = data;
    
    // Process the colors. We assume that this data's colors have never been processed before, and they
    // are either missing or fully saturated.
    NSMutableArray *plotColors = [NSMutableArray array];
    [plotColors addObject:[NSColor greenColor]];
    [plotColors addObject:[NSColor yellowColor]];
    [plotColors addObject:[NSColor redColor]];
    [plotColors addObject:[NSColor cyanColor]];
    [plotColors addObject:[NSColor purpleColor]];

    int colorNumber = 0;
    for (Series *series in data.seriesArray) {
	NSColor *color = series.color;
	if (color == nil) {
	    color = plotColors[colorNumber];
	    colorNumber = (colorNumber + 1) % plotColors.count;
	}
	
	// Desaturate.
	series.color = [_backgroundColor blendedColorWithFraction:0.4 ofColor:color];
    }

    // Redraw.
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];

    if (_data == nil || _data.seriesArray.count == 0 || _data.dataPointCount == 0) {
	// XXX Draw something.
	return;
    }
    
    Series *domainSeries = _data.domainSeries;

    // Plot rectangle.
    NSRect plotRect = [self bounds];
    plotRect.origin.x += MARGIN;
    plotRect.origin.y += MARGIN;
    plotRect.size.width -= MARGIN*2;
    plotRect.size.height -= MARGIN*2;

    // Draw background.
    [_backgroundColor set];
    NSRectFill(rect);

    // Draw axes.
    [_axisColor set];
    [self drawAxis:_data.leftAxis atX:plotRect.origin.x inPlotRect:plotRect];
    [self drawAxis:_data.rightAxis atX:(plotRect.origin.x + plotRect.size.width) inPlotRect:plotRect];

    // Draw each series.
    [self drawSeriesInAxis:_data.leftAxis inPlotRect:plotRect withDomain:domainSeries];
    [self drawSeriesInAxis:_data.rightAxis inPlotRect:plotRect withDomain:domainSeries];
    
    [self drawLegend:plotRect];
}

- (void)drawAxis:(Axis *)axis atX:(CGFloat)x inPlotRect:(CGRect)plotRect {
    NSArray *seriesArray = axis.seriesArray;

    // See if this axis has any series.
    if (seriesArray.count == 0) {
	return;
    }
    
    // Vertical axis.
    NSBezierPath *axisPath = [NSBezierPath bezierPath];
    [axisPath moveToPoint:NSMakePoint(x, plotRect.origin.y + plotRect.size.height)];
    [axisPath lineToPoint:NSMakePoint(x, plotRect.origin.y)];
    
    // Horizontal axis at zero.
    CGFloat axisY = plotRect.origin.y - axis.minValue/axis.range*plotRect.size.height;
    [axisPath moveToPoint:NSMakePoint(plotRect.origin.x, axisY)];
    [axisPath lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, axisY)];
    [axisPath setLineWidth:1.0];
    [axisPath stroke];
}

- (void)drawSeriesInAxis:(Axis *)axis inPlotRect:(CGRect)plotRect withDomain:(Series *)domainSeries {
    for (Series *series in axis.seriesArray) {
	[self drawSeries:series onAxis:axis inPlotRect:plotRect withDomain:domainSeries];
    }
}

- (void)drawSeries:(Series *)series onAxis:(Axis *)axis inPlotRect:(CGRect)plotRect withDomain:(Series *)domainSeries {
    NSBezierPath *line = [NSBezierPath bezierPath];
    BOOL firstPoint = YES;
    
    for (int j = 0; j < series.count; j++) {
	double domainValue = [domainSeries valueAt:j];
	double value = [series valueAt:j];
	
	// XXX Doesn't handle series.count <= 1.
	CGFloat x = plotRect.origin.x + (domainValue - domainSeries.minValue)*plotRect.size.width/domainSeries.range;
	CGFloat y = plotRect.origin.y + (value - axis.minValue)*plotRect.size.height/axis.range;
	NSPoint point = NSMakePoint(x, y);
	if (firstPoint) {
	    [line moveToPoint:point];
	    firstPoint = NO;
	} else {
	    [line lineToPoint:point];
	}
    }
    [line setLineWidth:2.0];
    [series.color set];
    [line stroke];
}

- (void)drawLegend:(NSRect)plotRect {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy]; // XXX store somewhere.
    [style setAlignment:NSRightTextAlignment];

    CGFloat leading = 20;
    CGFloat lineLength = 20;
    CGFloat margin = 5;
    CGFloat titleY = plotRect.origin.y + plotRect.size.height - leading;

    for (Series *series in _data.seriesArray) {
	NSString *title = series.title;
	
	if (title != nil) {
	    // The attributes for this legend text.
	    NSDictionary *attr = @{
				   NSForegroundColorAttributeName: _legendColor,
				   NSParagraphStyleAttributeName: style,
				   NSFontAttributeName: _legendFont
				   };

	    // The width of the legent text so we can right-align it.
	    NSSize size = [title sizeWithAttributes:attr];

	    // Draw the text. The point is the origin of the text, which is at the left of it and below the
	    // descenders (despite what the docs say).
	    NSPoint point = NSMakePoint(plotRect.origin.x + plotRect.size.width - lineLength - margin - size.width, titleY);
	    [title drawAtPoint:point withAttributes:attr];

	    // Where to draw our sample line.
	    CGFloat lineX = point.x + size.width + margin;
	    CGFloat lineY = titleY - _legendFont.descender + _legendFont.xHeight/2 + 1; // +1 cause it's too low otherwise for our font.

	    // Draw the line.
	    NSBezierPath *path = [NSBezierPath bezierPath];
	    [path moveToPoint:NSMakePoint(lineX, lineY)];
	    [path lineToPoint:NSMakePoint(lineX + lineLength, lineY)];
	    [series.color set];
	    [path setLineWidth:2.0];
	    [path stroke];

	    titleY -= leading;
	}
    }
}

@end
