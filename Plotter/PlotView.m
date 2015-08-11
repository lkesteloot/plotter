//
//  PlotView.m
//  Plotter
//
//  Created by Lawrence Kesteloot on 7/23/15.
//  Copyright (c) 2015 HeadCode. All rights reserved.
//

#import "PlotView.h"
#import "Grid.h"

#define MARGIN 40
#define GRID_VALUES_MARGIN 40
#define GRID_VALUE_PADDING 10

@interface PlotView () {
    Data *_data;
    NSColor *_backgroundColor;
    NSColor *_axisColor;
    NSColor *_gridColor;
    NSColor *_legendColor;
    NSFont *_legendFont;
    NSColor *_gridValueColor;
    NSFont *_gridValueFont;
    NSArray *_plotColors;
}

@end

@implementation PlotView

@dynamic data;

- (void)awakeFromNib {
    _data = nil;
    
    _backgroundColor = [NSColor colorWithRed:0.2 green:0.18 blue:0.14 alpha:1.0];
    _axisColor = [_backgroundColor blendedColorWithFraction:0.6 ofColor:[NSColor whiteColor]];
    _gridColor = [_backgroundColor blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]];
    _legendColor = [_backgroundColor blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]];
    _legendFont = [NSFont fontWithName:@"Helvetica" size:14];
    _gridValueColor = [_backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor whiteColor]];
    _gridValueFont = [NSFont fontWithName:@"Helvetica" size:14];
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
    
    // Plot rectangle.
    NSRect plotRect = [self bounds];
    plotRect.origin.x += MARGIN;
    plotRect.origin.y += MARGIN;
    plotRect.size.width -= MARGIN*2;
    plotRect.size.height -= MARGIN*2;
    if (_data.leftAxis.seriesArray.count > 0) {
	plotRect.origin.x += GRID_VALUES_MARGIN;
	plotRect.size.width -= GRID_VALUES_MARGIN;
    }
    if (_data.rightAxis.seriesArray.count > 0) {
	plotRect.size.width -= GRID_VALUES_MARGIN;
    }

    // Draw background.
    [_backgroundColor set];
    NSRectFill(rect);

    // Draw grid.
    [self drawDomainGridInPlotRect:plotRect];
    [self drawRangeGridInPlotRect:plotRect];

    // Draw each series.
    [self drawSeriesInAxis:_data.leftAxis inPlotRect:plotRect];
    [self drawSeriesInAxis:_data.rightAxis inPlotRect:plotRect];

    // Draw the legend.
    [self drawLegend:plotRect];
}

- (void)drawDomainGridInPlotRect:(CGRect)plotRect {
    Series *series = [_data domainSeriesForDerivative:0];
    if (series.isImplicit) {
	// Don't draw grid for implicit series.
	return;
    }

    double spacing = [self computeSpacingForSeries:series];
    double first = ceil(series.minValue/spacing)*spacing;
    double last = floor(series.maxValue/spacing)*spacing;
    int count = (int) floor((last - first)/spacing + 0.5) + 1;
    int zeroIndex = (int) floor((0 - first)/spacing + 0.5);
    NSLog(@"%g %g %g %d %d", spacing, first, last, count, zeroIndex);

    for (int i = 0; i < count; i++) {
	double value = first + i*spacing;
	int x = plotRect.origin.x + (value - series.minValue)*plotRect.size.width/series.range;

	if (i == zeroIndex) {
	    [_axisColor set];
	} else {
	    [_gridColor set];
	}

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(x, plotRect.origin.y)];
	[path lineToPoint:NSMakePoint(x, plotRect.origin.y + plotRect.size.height)];
	[path stroke];
    }
}

- (void)drawRangeGridInPlotRect:(CGRect)plotRect {
    // We always have exactly five lines.
    int count = 5;

    NSDictionary *attr = @{
			   NSForegroundColorAttributeName: _gridValueColor,
			   NSFontAttributeName: _gridValueFont
			   };

    for (int i = 0; i < count; i++) {
	int y = plotRect.origin.y + plotRect.size.height*i/4;

	if ((_data.leftAxis.seriesArray.count > 0 && _data.leftAxis.gridZeroIndex == i) ||
	    (_data.rightAxis.seriesArray.count > 0 && _data.rightAxis.gridZeroIndex == i)) {

	    [_axisColor set];
	} else {
	    [_gridColor set];
	}

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(plotRect.origin.x, y)];
	[path lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, y)];
	[path stroke];

	// Left grid values.
	if (_data.leftAxis.seriesArray.count > 0) {
	    double gridValue = _data.leftAxis.gridStart + i*_data.leftAxis.gridInterval;
	    NSString *gridValueStr = [_data.grid gridValueLabelFor:gridValue];
	    NSSize size = [gridValueStr sizeWithAttributes:attr];
	    CGFloat textY = y + _gridValueFont.descender - _gridValueFont.xHeight/2 - 1;
	    NSPoint point = NSMakePoint(plotRect.origin.x - size.width - GRID_VALUE_PADDING, textY);
	    [gridValueStr drawAtPoint:point withAttributes:attr];
	}

	// Right grid values.
	if (_data.rightAxis.seriesArray.count > 0) {
	    double gridValue = _data.rightAxis.gridStart + i*_data.rightAxis.gridInterval;
	    NSString *gridValueStr = [_data.grid gridValueLabelFor:gridValue];
	    CGFloat textY = y + _gridValueFont.descender - _gridValueFont.xHeight/2 - 1;
	    NSPoint point = NSMakePoint(plotRect.origin.x + plotRect.size.width + GRID_VALUE_PADDING, textY);
	    [gridValueStr drawAtPoint:point withAttributes:attr];
	}
    }
}

- (double)computeSpacingForSeries:(Series *)series {
    // We want at least five grid lines, which is four intervals.
    double spacing = series.range / 4;

    return spacing;
}

- (void)drawGridInPlotRect:(CGRect)plotRect {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(plotRect.origin.x, plotRect.origin.y)];
    [path lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, plotRect.origin.y)];
    [path lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, plotRect.origin.y + plotRect.size.height)];
    [path lineToPoint:NSMakePoint(plotRect.origin.x, plotRect.origin.y + plotRect.size.height)];
    [path lineToPoint:NSMakePoint(plotRect.origin.x, plotRect.origin.y)];
    [path stroke];
}

- (void)drawSeriesInAxis:(Axis *)axis inPlotRect:(CGRect)plotRect {
    for (Series *series in axis.seriesArray) {
	Series *domainSeries = [_data domainSeriesForDerivative:series.derivative];
	[self drawSeries:series onAxis:axis inPlotRect:plotRect withDomain:domainSeries];
    }
}

- (void)drawSeries:(Series *)series onAxis:(Axis *)axis inPlotRect:(CGRect)plotRect withDomain:(Series *)domainSeries {
    NSBezierPath *line = [NSBezierPath bezierPath];
    BOOL firstPoint = YES;

    // For remapping to the grid.
    double minGridValue = axis.gridStart;
    double gridRange = (axis.gridCount - 1)*axis.gridInterval;
    
    for (int j = 0; j < series.count; j++) {
	double domainValue = [domainSeries valueAt:j];
	double value = [series valueAt:j];
	
	// XXX Doesn't handle series.count <= 1.
	CGFloat x = plotRect.origin.x + (domainValue - domainSeries.minValue)*plotRect.size.width/domainSeries.range;
	CGFloat y = plotRect.origin.y + (value - minGridValue)*plotRect.size.height/gridRange;
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
    CGFloat leading = 20;
    CGFloat lineLength = 20;
    CGFloat margin = 5;
    CGFloat titleY = plotRect.origin.y + plotRect.size.height - leading;

    for (Series *series in _data.seriesArray) {
	// The domain doesn't go into the legend.
	if (series.seriesType == SeriesTypeDomain) {
	    continue;
	}

	NSString *title = series.title;
	
	if (title != nil) {
	    // The attributes for this legend text.
	    NSDictionary *attr = @{
				   NSForegroundColorAttributeName: _legendColor,
				   NSFontAttributeName: _legendFont
				   };

	    // The width of the legent text so we can right-align it.
	    NSSize size = [title sizeWithAttributes:attr];

	    // Draw the text. The point is the origin of the text, which is at the left of it and below the
	    // descenders (despite what the docs say).
	    NSPoint point = NSMakePoint(plotRect.origin.x + plotRect.size.width - lineLength - 2*margin - size.width, titleY);
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
