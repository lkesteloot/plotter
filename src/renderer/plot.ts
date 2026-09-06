// Draws the plot on a canvas.
//
// The canvas origin is at the top left with y going down, while data values go
// up. Everything here is in canvas coordinates, so values map to y with
// yForValue(), which does the flip.

import { blend, type Color, COLORS, FALLBACK_COLOR, rgb, toCss, WHITE } from "../core/colors.js";
import { type Axis } from "../core/axis.js";
import { type Data } from "../core/data.js";
import { type Grid } from "../core/grid.js";
import { type Series, SeriesType } from "../core/series.js";

const MARGIN = 40;
const GRID_VALUES_MARGIN = 40;
const GRID_VALUE_PADDING = 10;
const PILL_V_PADDING = 1;

const LEGEND_LEADING = 20;
const LEGEND_LINE_LENGTH = 20;
const LEGEND_MARGIN = 5;

const SERIES_LINE_WIDTH = 2;

const BACKGROUND_COLOR = rgb(0.2, 0.18, 0.14);
const AXIS_COLOR = blend(BACKGROUND_COLOR, 0.6, WHITE);
const GRID_COLOR = blend(BACKGROUND_COLOR, 0.1, WHITE);
const LEGEND_COLOR = blend(BACKGROUND_COLOR, 0.5, WHITE);
const GRID_VALUE_COLOR = blend(BACKGROUND_COLOR, 0.4, WHITE);

const LEGEND_FONT = "14px Helvetica, sans-serif";
const GRID_VALUE_FONT = "14px Helvetica, sans-serif";

// A rectangle in canvas coordinates.
interface Rect {
    x: number;
    y: number;
    width: number;
    height: number;
}

// The vertical metrics of a font.
interface FontMetrics {
    ascent: number;
    descent: number;
    xHeight: number;
}

export class Plot {
    private readonly ctx: CanvasRenderingContext2D;
    private data: Data | undefined = undefined;
    // A message to show instead of a plot, when the file can't be plotted.
    private error: string | undefined = undefined;

    // The domain value the user last clicked on, if any.
    private clickedValue: number | undefined = undefined;

    constructor(private readonly canvas: HTMLCanvasElement) {
        const ctx = canvas.getContext("2d");
        if (ctx === null) {
            throw new Error("Can't get a 2D canvas context.");
        }
        this.ctx = ctx;

        canvas.addEventListener("mousedown", (event) => this.updatePicker(event));
        canvas.addEventListener("mousemove", (event) => {
            if (event.buttons !== 0) {
                this.updatePicker(event);
            }
        });
    }

    setData(data: Data): void {
        this.data = data;
        this.error = undefined;
        this.clickedValue = undefined;

        this.assignColors(data);
        this.draw();
    }

    // Show a message instead of a plot. Used when the data can't be plotted at
    // all, such as a log plot with non-positive values.
    setError(error: string): void {
        this.data = undefined;
        this.error = error;
        this.clickedValue = undefined;

        this.draw();
    }

    // Fill in the colors of series that didn't specify one, preferring colors
    // that aren't already used.
    private assignColors(data: Data): void {
        const usedColors = new Set<Color>();
        for (const series of data.seriesArray) {
            if (series.color !== undefined && series.seriesType !== SeriesType.Domain) {
                usedColors.add(series.color);
            }
        }

        let colorNumber = 0;
        for (const series of data.seriesArray) {
            if (series.color === undefined && series.seriesType !== SeriesType.Domain) {
                series.color = FALLBACK_COLOR;

                while (colorNumber < COLORS.length) {
                    const color = COLORS[colorNumber++]!;
                    if (!usedColors.has(color)) {
                        series.color = color;
                        usedColors.add(color);
                        break;
                    }
                }
            }

            // Desaturate against the background.
            if (series.color !== undefined) {
                series.color = blend(BACKGROUND_COLOR, 0.4, series.color);
            }
        }
    }

    private updatePicker(event: MouseEvent): void {
        const data = this.data;
        if (data === undefined || data.isEmpty || data.domainGrid === undefined) {
            return;
        }

        const bounds = this.canvas.getBoundingClientRect();
        const x = event.clientX - bounds.left;

        const plotRect = this.getPlotRect(data);
        const position = (x - plotRect.x)/plotRect.width;
        if (position >= 0 && position <= 1) {
            const grid = data.domainGrid;

            // Round to a value the grid could label. If the data is integers,
            // this snaps to integers.
            this.clickedValue = grid.roundDisplayedValue(grid.valueForPosition(position));
            this.draw();
        }
    }

    private getPlotRect(data: Data): Rect {
        const rect: Rect = {
            x: MARGIN,
            y: MARGIN,
            width: this.canvas.clientWidth - MARGIN*2,
            height: this.canvas.clientHeight - MARGIN*2,
        };

        if (data.leftAxis.seriesArray.length > 0) {
            rect.x += GRID_VALUES_MARGIN;
            rect.width -= GRID_VALUES_MARGIN;
        }
        if (data.rightAxis.seriesArray.length > 0) {
            rect.width -= GRID_VALUES_MARGIN;
        }
        if (!data.domainSeriesForDerivative(0).isImplicit) {
            // Leave room below the plot for the domain labels.
            rect.height -= GRID_VALUES_MARGIN;
        }

        return rect;
    }

    // Resize the backing store to the element, accounting for retina displays,
    // and redraw.
    resize(): void {
        const ratio = window.devicePixelRatio;

        this.canvas.width = Math.round(this.canvas.clientWidth*ratio);
        this.canvas.height = Math.round(this.canvas.clientHeight*ratio);
        this.ctx.setTransform(ratio, 0, 0, ratio, 0, 0);

        this.draw();
    }

    draw(): void {
        const ctx = this.ctx;

        // Draw the background even when there's no data, so the window isn't white.
        ctx.fillStyle = toCss(BACKGROUND_COLOR);
        ctx.fillRect(0, 0, this.canvas.clientWidth, this.canvas.clientHeight);

        if (this.error !== undefined) {
            this.drawMessage(this.error);
            return;
        }

        const data = this.data;
        if (data === undefined || data.isEmpty) {
            return;
        }

        const plotRect = this.getPlotRect(data);

        this.drawDomainGrid(data, plotRect);
        this.drawRangeGrid(data, plotRect);

        this.drawSeriesInAxis(data, data.leftAxis, plotRect);
        this.drawSeriesInAxis(data, data.rightAxis, plotRect);

        this.drawClicked(data, plotRect);
        this.drawLegend(data, plotRect);
    }

    // Center a line of text in the window.
    private drawMessage(message: string): void {
        const ctx = this.ctx;

        ctx.font = LEGEND_FONT;
        ctx.textBaseline = "middle";
        ctx.textAlign = "center";
        ctx.fillStyle = toCss(LEGEND_COLOR);
        ctx.fillText(message, this.canvas.clientWidth/2, this.canvas.clientHeight/2);
        ctx.textAlign = "left";
    }

    private xForValue(grid: Grid, value: number, plotRect: Rect): number {
        return plotRect.x + grid.positionForValue(value)*plotRect.width;
    }

    private yForValue(grid: Grid, value: number, plotRect: Rect): number {
        return plotRect.y + plotRect.height - grid.positionForValue(value)*plotRect.height;
    }

    private metricsFor(font: string): FontMetrics {
        const ctx = this.ctx;

        ctx.font = font;
        const metrics = ctx.measureText("x");

        return {
            ascent: metrics.fontBoundingBoxAscent,
            descent: metrics.fontBoundingBoxDescent,
            // The height of an "x" is, by definition, the x-height.
            xHeight: metrics.actualBoundingBoxAscent,
        };
    }

    private drawDomainGrid(data: Data, plotRect: Rect): void {
        const series = data.domainSeriesForDerivative(0);
        if (series.isImplicit || data.domainGrid === undefined) {
            // Don't draw a grid for an implicit series; the line numbers aren't
            // interesting.
            return;
        }

        const grid = data.domainGrid;
        for (const gridLine of grid.gridLines) {
            this.drawDomainGridLine({
                value: gridLine.value,
                lineColor: gridLine.isZero ? AXIS_COLOR : GRID_COLOR,
                label: gridLine.drawLabel
                    ? grid.gridValueLabelFor(gridLine.value, series.date)
                    : undefined,
                labelColor: GRID_VALUE_COLOR,
                grid,
                plotRect,
            });
        }
    }

    // Draw one vertical line, with an optional label below the plot. The label
    // gets a rounded background when labelBackgroundColor is given, which is how
    // the clicked value is distinguished from the grid.
    private drawDomainGridLine(options: {
        value: number;
        lineColor: Color;
        label: string | undefined;
        labelColor: Color;
        labelBackgroundColor?: Color;
        grid: Grid;
        plotRect: Rect;
    }): void {
        const ctx = this.ctx;
        const { plotRect } = options;

        const x = this.xForValue(options.grid, options.value, plotRect);

        ctx.strokeStyle = toCss(options.lineColor);
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(x, plotRect.y);
        ctx.lineTo(x, plotRect.y + plotRect.height);
        ctx.stroke();

        if (options.label === undefined) {
            return;
        }

        const font = GRID_VALUE_FONT;
        const metrics = this.metricsFor(font);

        ctx.font = font;
        ctx.textBaseline = "alphabetic";

        const width = ctx.measureText(options.label).width;
        const textX = x - width/2;
        const baseline = plotRect.y + plotRect.height + metrics.ascent + GRID_VALUE_PADDING;

        if (options.labelBackgroundColor !== undefined) {
            const height = metrics.ascent + metrics.descent + PILL_V_PADDING*2;
            const hPadding = height/2;

            ctx.fillStyle = toCss(options.labelBackgroundColor);
            ctx.beginPath();
            ctx.roundRect(textX - hPadding, baseline - metrics.ascent - PILL_V_PADDING,
                width + hPadding*2, height, height/2);
            ctx.fill();
        }

        ctx.fillStyle = toCss(options.labelColor);
        ctx.fillText(options.label, textX, baseline);
    }

    private drawRangeGrid(data: Data, plotRect: Rect): void {
        const ctx = this.ctx;

        const leftGrid = data.leftAxis.seriesArray.length > 0 ? data.leftAxis.grid : undefined;
        const rightGrid = data.rightAxis.seriesArray.length > 0 ? data.rightAxis.grid : undefined;

        // Both grids have the same number of lines, so we can use either one for
        // positioning and label the two axes independently.
        const grid = leftGrid ?? rightGrid;
        if (grid === undefined) {
            return;
        }

        const haveBothAxes = leftGrid !== undefined && rightGrid !== undefined;
        const leftColor = this.rangeLabelColor(data.leftAxis, haveBothAxes);
        const rightColor = this.rangeLabelColor(data.rightAxis, haveBothAxes);

        const metrics = this.metricsFor(GRID_VALUE_FONT);
        ctx.font = GRID_VALUE_FONT;
        ctx.textBaseline = "alphabetic";

        for (let i = 0; i < grid.gridLines.length; i++) {
            const leftGridLine = leftGrid?.gridLines[i];
            const rightGridLine = rightGrid?.gridLines[i];
            const gridLine = grid.gridLines[i]!;

            const y = this.yForValue(grid, gridLine.value, plotRect);

            ctx.strokeStyle = toCss(
                this.rangeGridLineColor(data, leftGridLine?.isZero ?? false,
                    rightGridLine?.isZero ?? false, haveBothAxes));
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(plotRect.x, y);
            ctx.lineTo(plotRect.x + plotRect.width, y);
            ctx.stroke();

            // Center the labels on the grid line. The +1 is because it sits a
            // little low otherwise for our font.
            const baseline = y + metrics.xHeight/2 + 1;

            if (leftGridLine !== undefined && leftGridLine.drawLabel) {
                const label = grid.gridValueLabelFor(gridLine.value, false);
                const width = ctx.measureText(label).width;

                ctx.fillStyle = toCss(leftColor);
                ctx.fillText(label, plotRect.x - width - GRID_VALUE_PADDING, baseline);
            }

            if (rightGridLine !== undefined && rightGridLine.drawLabel) {
                const label = grid.gridValueLabelFor(rightGridLine.value, false);

                ctx.fillStyle = toCss(rightColor);
                ctx.fillText(label, plotRect.x + plotRect.width + GRID_VALUE_PADDING, baseline);
            }
        }
    }

    // The zero line is drawn as an axis. When both axes are in use and their
    // zeros are at different heights, tint each one toward the series it belongs
    // to, so it's clear which axis it goes with.
    private rangeGridLineColor(data: Data, leftIsZero: boolean, rightIsZero: boolean,
                               haveBothAxes: boolean): Color {

        if (leftIsZero && rightIsZero) {
            return AXIS_COLOR;
        }

        for (const [isZero, axis] of [
            [leftIsZero, data.leftAxis],
            [rightIsZero, data.rightAxis],
        ] as const) {
            if (isZero) {
                const series = axis.seriesArray[0];
                if (haveBothAxes && axis.seriesArray.length === 1 && series?.color !== undefined) {
                    return blend(GRID_COLOR, 0.4, series.color);
                }
                return AXIS_COLOR;
            }
        }

        return GRID_COLOR;
    }

    // If there's only one series on an axis, draw its labels in that series'
    // color to make it easier to visually link them.
    private rangeLabelColor(axis: Axis, haveBothAxes: boolean): Color {
        const series = axis.seriesArray[0];

        if (haveBothAxes && axis.seriesArray.length === 1 && series?.color !== undefined) {
            return series.color;
        }

        return GRID_VALUE_COLOR;
    }

    private drawSeriesInAxis(data: Data, axis: Axis, plotRect: Rect): void {
        const ctx = this.ctx;

        const rangeGrid = axis.grid;
        const domainGrid = data.domainGrid;
        if (rangeGrid === undefined || domainGrid === undefined) {
            return;
        }

        for (const series of axis.seriesArray) {
            const domainSeries = data.domainSeriesForDerivative(series.derivative);

            ctx.strokeStyle = toCss(series.color ?? FALLBACK_COLOR);
            ctx.lineWidth = SERIES_LINE_WIDTH;
            ctx.beginPath();

            for (let i = 0; i < series.count; i++) {
                const x = this.xForValue(domainGrid, domainSeries.valueAt(i), plotRect);
                const y = this.yForValue(rangeGrid, series.valueAt(i), plotRect);

                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            }

            ctx.stroke();
        }
    }

    private drawLegend(data: Data, plotRect: Rect): void {
        const ctx = this.ctx;

        const metrics = this.metricsFor(LEGEND_FONT);
        ctx.font = LEGEND_FONT;
        ctx.textBaseline = "alphabetic";

        let baseline = plotRect.y + LEGEND_LEADING - metrics.descent;

        for (const series of data.seriesArray) {
            // The domain doesn't go into the legend.
            if (series.seriesType === SeriesType.Domain || series.title === undefined) {
                continue;
            }

            // Right-align the text against the sample line.
            const width = ctx.measureText(series.title).width;
            const textX = plotRect.x + plotRect.width
                - LEGEND_LINE_LENGTH - LEGEND_MARGIN*2 - width;

            ctx.fillStyle = toCss(LEGEND_COLOR);
            ctx.fillText(series.title, textX, baseline);

            // The sample line, centered on the text.
            const lineX = textX + width + LEGEND_MARGIN;
            const lineY = baseline - metrics.xHeight/2 - 1;

            ctx.strokeStyle = toCss(series.color ?? FALLBACK_COLOR);
            ctx.lineWidth = SERIES_LINE_WIDTH;
            ctx.beginPath();
            ctx.moveTo(lineX, lineY);
            ctx.lineTo(lineX + LEGEND_LINE_LENGTH, lineY);
            ctx.stroke();

            baseline += LEGEND_LEADING;
        }
    }

    private drawClicked(data: Data, plotRect: Rect): void {
        if (this.clickedValue === undefined || data.domainGrid === undefined) {
            return;
        }

        const series = data.domainSeriesForDerivative(0);
        const grid = data.domainGrid;

        this.drawDomainGridLine({
            value: this.clickedValue,
            lineColor: AXIS_COLOR,
            label: grid.gridValueLabelFor(this.clickedValue, series.date),
            labelColor: BACKGROUND_COLOR,
            labelBackgroundColor: GRID_VALUE_COLOR,
            grid,
            plotRect,
        });
    }
}
