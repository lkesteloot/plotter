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
#define PILL_V_PADDING 1

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

    // For clicked locations.
    BOOL _clicked;
    double _domainClickValue;
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

    _clicked = NO;
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
    [plotColors addObject:[[NSColor purpleColor] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]]];
    [plotColors addObject:[[NSColor blueColor] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]]];

    int colorNumber = 0;
    for (Series *series in data.seriesArray) {
	NSColor *color = series.color;
	if (color == nil && series.seriesType != SeriesTypeDomain) {
	    color = plotColors[colorNumber];
	    colorNumber = (colorNumber + 1) % plotColors.count;
	}
	
	// Desaturate.
	series.color = [_backgroundColor blendedColorWithFraction:0.4 ofColor:color];
    }

    // Redraw.
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    [self updatePicker:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self updatePicker:event];
}

- (void)updatePicker:(NSEvent *)event {
    if (_data == nil || _data.seriesArray.count == 0 || _data.dataPointCount == 0) {
        return;
    }

    // Convert to view coordinates.
    NSPoint viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];

    // Plot rectangle.
    NSRect plotRect = [self getPlotRect];

    // Convert to value, based on grid.
    Grid *grid = _data.domainGrid;
    CGFloat position = (viewPoint.x - plotRect.origin.x)/plotRect.size.width;
    if (position >= 0 && position <= 1) {
        _clicked = YES;
        // Let's round to an integer, since my data is currently integers. If this changes
        // we can have the series keep track of whether all data were integers and
        // round automatically.
        _domainClickValue = [grid roundDisplayedValue:[grid valueForPosition:position]];
        self.needsDisplay = YES;
    }
}

- (NSRect)getPlotRect {
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
    Series *domainSeries = [_data domainSeriesForDerivative:0];
    if (!domainSeries.isImplicit) {
        plotRect.origin.y += GRID_VALUES_MARGIN;
        plotRect.size.height -= GRID_VALUES_MARGIN;
    }

    return plotRect;
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];

    if (_data == nil || _data.seriesArray.count == 0 || _data.dataPointCount == 0) {
	// XXX Draw something.
	return;
    }
    
    // Plot rectangle.
    NSRect plotRect = [self getPlotRect];

    // Draw background.
    [_backgroundColor set];
    NSRectFill(rect);

    // Draw grid.
    [self drawDomainGridInPlotRect:plotRect];
    [self drawRangeGridInPlotRect:plotRect];

    // Draw each series.
    [self drawSeriesInAxis:_data.leftAxis inPlotRect:plotRect];
    [self drawSeriesInAxis:_data.rightAxis inPlotRect:plotRect];

    // Draw the clicked point.
    [self drawClickedInPlotRect:plotRect];

    // Draw the legend.
    [self drawLegend:plotRect];
}

- (void)drawDomainGridInPlotRect:(CGRect)plotRect {
    Series *series = [_data domainSeriesForDerivative:0];
    if (series.isImplicit) {
	// Don't draw grid for implicit series.
        return;
    }

    Grid *grid = _data.domainGrid;
    for (GridLine *gridLine in grid.gridLines) {
        NSColor *color = gridLine.isZero ? _axisColor : _gridColor;
        NSString *label = gridLine.drawLabel ? [grid gridValueLabelFor:gridLine.value isDate:series.date] : nil;
        [self drawDomainGridLine:gridLine.value
                       lineColor:color
                           label:label
                      labelColor:_gridValueColor
            labelBackgroundColor:nil
                       labelFont:_gridValueFont
                            grid:grid
                      inPlotRect:plotRect];
    }
}

- (void)drawDomainGridLine:(double)value
                 lineColor:(NSColor *)lineColor
                     label:(NSString *)label
                labelColor:(NSColor *)labelColor
      labelBackgroundColor:(NSColor *)labelBackgroundColor
                 labelFont:(NSFont *)labelFont
                      grid:(Grid *)grid
                inPlotRect:(CGRect)plotRect {

    float x = plotRect.origin.x + [grid positionForValue:value]*plotRect.size.width;

    // Draw vertical line.
    [lineColor set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(x, plotRect.origin.y)];
    [path lineToPoint:NSMakePoint(x, plotRect.origin.y + plotRect.size.height)];
    [path stroke];

    // Draw label.
    if (label != nil) {
        NSDictionary *attr = @{
                               NSForegroundColorAttributeName: labelColor,
                               NSFontAttributeName: labelFont
                               };

        NSSize size = [label sizeWithAttributes:attr];
        CGFloat textX = x - size.width/2;
        CGFloat textY = plotRect.origin.x - labelFont.ascender + labelFont.descender - GRID_VALUE_PADDING;
        NSPoint point = NSMakePoint(textX, textY);

        if (labelBackgroundColor != nil) {
            [labelBackgroundColor set];

            CGFloat height = size.height + 2*PILL_V_PADDING;
            CGFloat hPadding = height/2;
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path appendBezierPathWithRoundedRect:NSMakeRect(textX - hPadding, textY - PILL_V_PADDING, size.width + 2*hPadding, height) xRadius:height/2 yRadius:height/2];
            [path fill];
        }

        [label drawAtPoint:point withAttributes:attr];
    }
}

- (void)drawRangeGridInPlotRect:(CGRect)plotRect {
    Grid *leftGrid = _data.leftAxis.seriesArray.count > 0 ? _data.leftAxis.grid : nil;
    Grid *rightGrid = _data.rightAxis.seriesArray.count > 0 ? _data.rightAxis.grid : nil;

    // Either grid.
    Grid *grid = leftGrid != nil ? leftGrid : rightGrid;
    if (grid == nil) {
	return;
    }

    // Will be the same for all grids (5).
    NSUInteger lineCount = [grid.gridLines count];

    // Figure out whether we're displaying on both axes.
    BOOL haveBothAxes = _data.leftAxis.seriesArray.count > 0 && _data.rightAxis.seriesArray.count > 0;

    NSDictionary *leftAttr = [self makeRangeLabelAttrForAxis:_data.leftAxis haveBothAxes:haveBothAxes];
    NSDictionary *rightAttr = [self makeRangeLabelAttrForAxis:_data.rightAxis haveBothAxes:haveBothAxes];

    for (int i = 0; i < lineCount; i++) {
	GridLine *leftGridLine = [leftGrid.gridLines objectAtIndex:i];
	GridLine *rightGridLine = [rightGrid.gridLines objectAtIndex:i];
	GridLine *gridLine = [grid.gridLines objectAtIndex:i];

	int y = plotRect.origin.y + [grid positionForValue:gridLine.value]*plotRect.size.height;

	NSColor *gridLineColor;
	if (leftGridLine.isZero && rightGridLine.isZero) {
	    gridLineColor = _axisColor;
	} else if (leftGridLine.isZero) {
	    if (haveBothAxes && _data.leftAxis.seriesArray.count == 1) {
		Series *series = [_data.leftAxis.seriesArray objectAtIndex:0];
		gridLineColor = [_gridColor blendedColorWithFraction:0.4 ofColor:series.color];
	    } else {
		gridLineColor = _axisColor;
	    }
	} else if (rightGridLine.isZero) {
	    if (haveBothAxes && _data.rightAxis.seriesArray.count == 1) {
		Series *series = [_data.rightAxis.seriesArray objectAtIndex:0];
		gridLineColor = [_gridColor blendedColorWithFraction:0.4 ofColor:series.color];
	    } else {
		gridLineColor = _axisColor;
	    }
	} else {
	    gridLineColor = _gridColor;
	}
	[gridLineColor set];

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(plotRect.origin.x, y)];
	[path lineToPoint:NSMakePoint(plotRect.origin.x + plotRect.size.width, y)];
	[path stroke];

	// Left grid values.
	if (leftGridLine != nil && leftGridLine.drawLabel) {
	    NSString *gridValueStr = [grid gridValueLabelFor:gridLine.value isDate:NO];
	    NSSize size = [gridValueStr sizeWithAttributes:leftAttr];
	    CGFloat textY = y + _gridValueFont.descender - _gridValueFont.xHeight/2 - 1;
	    NSPoint point = NSMakePoint(plotRect.origin.x - size.width - GRID_VALUE_PADDING, textY);
	    [gridValueStr drawAtPoint:point withAttributes:leftAttr];
	}

	// Right grid values.
	if (rightGridLine != nil && rightGridLine.drawLabel) {
	    NSString *gridValueStr = [grid gridValueLabelFor:rightGridLine.value isDate:NO];
	    CGFloat textY = y + _gridValueFont.descender - _gridValueFont.xHeight/2 - 1;
	    NSPoint point = NSMakePoint(plotRect.origin.x + plotRect.size.width + GRID_VALUE_PADDING, textY);
	    [gridValueStr drawAtPoint:point withAttributes:rightAttr];
	}
    }
}

// Return an attribute dictionary for the labels for this axis.
- (NSDictionary *)makeRangeLabelAttrForAxis:(Axis *)axis haveBothAxes:(BOOL)haveBothAxes {
    NSColor *textColor;

    // If there's only one series for an axis, draw the labels in that color
    // to make it easier to visually link them.
    if (haveBothAxes && axis.seriesArray.count == 1) {
	Series *series = [axis.seriesArray objectAtIndex:0];
	textColor = series.color;
    } else {
	textColor = _gridValueColor;
    }

    return @{
	     NSForegroundColorAttributeName: textColor,
	     NSFontAttributeName: _gridValueFont
	     };
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
    Grid *rangeGrid = axis.grid;
    BOOL firstPoint = YES;
    NSPoint previousPoint = NSMakePoint(0, 0);

    [series.color set];
    [NSBezierPath setDefaultLineWidth:2];
    for (int j = 0; j < series.count; j++) {
	double domainValue = [domainSeries valueAt:j];
	double value = [series valueAt:j];
	
	CGFloat x = plotRect.origin.x + [_data.domainGrid positionForValue:domainValue]*plotRect.size.width;
	CGFloat y = plotRect.origin.y + [rangeGrid positionForValue:value]*plotRect.size.height;
	NSPoint point = NSMakePoint(x, y);
	if (firstPoint) {
	    firstPoint = NO;
	} else {
	    [NSBezierPath strokeLineFromPoint:previousPoint toPoint:point];
	}
	previousPoint = point;
    }
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

- (void)drawClickedInPlotRect:(CGRect)plotRect {
    if (!_clicked) {
        return;
    }

    Series *series = [_data domainSeriesForDerivative:0];
    Grid *grid = _data.domainGrid;

    NSString *label = [grid gridValueLabelFor:_domainClickValue isDate:series.date];
    [self drawDomainGridLine:_domainClickValue
                   lineColor:_axisColor
                       label:label
                  labelColor:_backgroundColor
        labelBackgroundColor:_gridValueColor
                   labelFont:_gridValueFont
                        grid:grid
                  inPlotRect:plotRect];
}

@end
