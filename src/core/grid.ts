// The grid lines drawn behind a plot, and the mapping between data values and
// positions along an axis. Ported from Grid.m.

// The set of numbers that we can use for grid intervals.
const VALID_VALUES = [1, 1.5, 2, 3, 4, 5, 6, 7.5, 8, 10];

// Number of lines in a range (vertical) grid.
const RANGE_LINE_COUNT = 5;

// The original used the current locale. We pin the locale so that plots and
// tests look the same everywhere.
const LOCALE = "en-US";

const GROUPED_FORMAT = new Intl.NumberFormat(LOCALE, {
    maximumFractionDigits: 2,
    useGrouping: true,
});
const UNGROUPED_FORMAT = new Intl.NumberFormat(LOCALE, {
    maximumFractionDigits: 2,
    useGrouping: false,
});

// A single line to draw on the grid.
export interface GridLine {
    readonly value: number;
    // Whether this is the zero line, which is drawn more prominently.
    readonly isZero: boolean;
    // Whether to label it. Log grids only label the powers of ten.
    readonly drawLabel: boolean;
}

// Round up to the next higher (or equal) value in VALID_VALUES, accounting
// for order of magnitude.
export function roundUp(value: number): number {
    const decade = Math.pow(10, Math.floor(Math.log10(value)));

    value /= decade;

    // This always finds one because we include "10" in the list.
    for (const validValue of VALID_VALUES) {
        if (validValue >= value) {
            value = validValue;
            break;
        }
    }

    return value*decade;
}

// Round down to the next lower (or equal) value in VALID_VALUES, accounting
// for order of magnitude.
export function roundDown(value: number): number {
    const decade = Math.pow(10, Math.floor(Math.log10(value)));

    value /= decade;

    // This always finds one because we include "1" in the list.
    for (let i = VALID_VALUES.length - 1; i >= 0; i--) {
        const validValue = VALID_VALUES[i]!;
        if (validValue <= value) {
            value = validValue;
            break;
        }
    }

    return value*decade;
}

// A horizontal or vertical grid. Use makeRangeGrid() or makeDomainGrid() to
// build one.
export class Grid {
    readonly gridLines: readonly GridLine[];
    // How many digits after the decimal point are meaningful at this scale.
    readonly fractionDigits: number;

    private readonly log: boolean;
    private readonly minValue: number;
    private readonly maxValue: number;
    private readonly logMinValue: number;
    private readonly logMaxValue: number;

    constructor(options: {
        gridLines: readonly GridLine[];
        log: boolean;
        minValue: number;
        maxValue: number;
        logMinValue?: number;
        logMaxValue?: number;
    }) {
        this.gridLines = options.gridLines;
        this.log = options.log;
        this.minValue = options.minValue;
        this.maxValue = options.maxValue;
        this.logMinValue = options.logMinValue ?? 0;
        this.logMaxValue = options.logMaxValue ?? 0;

        const delta = this.log
            ? this.logMaxValue - this.logMinValue
            : this.maxValue - this.minValue;

        // Enough digits to be meaningful on a grid.
        this.fractionDigits = delta > 0
            ? Math.max(0, -Math.ceil(Math.log10(delta)) + 1)
            : 2;
    }

    // Return 0.0 to 1.0 for where to plot this value along the grid.
    positionForValue(value: number): number {
        if (this.log) {
            return (Math.log10(value) - this.logMinValue)/(this.logMaxValue - this.logMinValue);
        }

        return (value - this.minValue)/(this.maxValue - this.minValue);
    }

    // Return the value at a position (0.0 to 1.0) along the grid.
    valueForPosition(position: number): number {
        if (this.log) {
            return Math.pow(10, position*(this.logMaxValue - this.logMinValue) + this.logMinValue);
        }

        return position*(this.maxValue - this.minValue) + this.minValue;
    }

    // What text to draw at this value. Dates are drawn without grouping, so
    // that a year shows as "2018" and not "2,018".
    gridValueLabelFor(value: number, isDate: boolean): string {
        const format = isDate ? UNGROUPED_FORMAT : GROUPED_FORMAT;

        // Intl formats negative zero as "-0"; the original did not.
        return format.format(value === 0 ? 0 : value);
    }

    // Take a value and round it to a nice value given the range of this grid.
    roundDisplayedValue(value: number): number {
        // Note that this uses fractionDigits, which is wrong (too low) in some
        // cases, like when the range is [0,3] it'll be zero and none of the
        // values will have fraction digits. Revisit when it causes a problem.
        const precision = Math.pow(10, -this.fractionDigits);

        return Math.floor(value/precision + 0.5)*precision;
    }
}

// Build the grid for a vertical (left or right) axis.
//
// Unlike the domain, the data lines don't necessarily go all the way to the top
// and bottom of the plot area. We always force the range to have five grid lines
// spaced evenly, and we scale the data to fit. For each axis:
//
// - The intervals are chosen from a set of nice numbers.
// - The intervals go through 0.
// - The data should be as large as possible vertically.
// - If the range of the range is 0, include 0 in the plot.
export function makeRangeGrid(minValue: number, maxValue: number): Grid {
    // Figure out the range (max - min). It must never be zero.
    let range = maxValue - minValue;
    if (range === 0) {
        // All data is the same. Include 0 in the plot.
        range = Math.abs(minValue);
        if (range === 0) {
            // All data is zero. Just pick integer grid lines.
            range = 4;
        }
    }

    // Initial guess for an interval, rounded up to the nearest nice number.
    let interval = roundUp(range/(RANGE_LINE_COUNT - 1));
    let start = Math.floor(minValue/interval)*interval;

    // See if we fit the range.
    while (start + interval*(RANGE_LINE_COUNT - 1) < maxValue) {
        // The floor for "start" made it so that we don't fit. Add that error to
        // our range and recompute.
        const newRange = range + minValue - start;

        interval = roundUp(newRange/(RANGE_LINE_COUNT - 1));
        start = Math.floor(minValue/interval)*interval;
    }

    const zeroIndex = Math.floor((0 - start)/interval + 0.5);

    const gridLines: GridLine[] = [];
    for (let i = 0; i < RANGE_LINE_COUNT; i++) {
        gridLines.push({
            value: start + interval*i,
            isZero: i === zeroIndex,
            drawLabel: true,
        });
    }

    return new Grid({
        gridLines,
        log: false,
        minValue: start,
        maxValue: start + (RANGE_LINE_COUNT - 1)*interval,
    });
}

// Build the grid for the horizontal axis. The data lines themselves always go
// from the far left to the far right of the plot, so the grid spans exactly the
// data.
export function makeDomainGrid(minValue: number, maxValue: number, log: boolean): Grid {
    const gridLines: GridLine[] = [];

    if (log) {
        // We have one grid line for each most-significant digit (e.g., 1, 2, 3,
        // ..., 9, 10, 20, 30, ..., 80, 90, 100, 200, ...).

        if (minValue <= 0 || maxValue <= 0) {
            throw new Error("Log plots require positive values.");
        }

        // Compute the first line we draw. E.g., 343 gives a decade of 100 and a
        // digit of 4 (for "400").
        let decade = Math.pow(10, Math.floor(Math.log10(minValue)));
        let digit = Math.ceil(minValue/decade);

        for (;;) {
            if (digit === 10) {
                digit = 1;
                decade *= 10;
            }

            const value = digit*decade;
            if (value > maxValue) {
                break;
            }

            gridLines.push({ value, isZero: false, drawLabel: digit === 1 });
            digit += 1;
        }

        return new Grid({
            gridLines,
            log: true,
            minValue,
            maxValue,
            logMinValue: Math.log10(minValue),
            logMaxValue: Math.log10(maxValue),
        });
    }

    // We choose grid value intervals such that:
    //
    // - There are as few grid lines as possible.
    // - There are always at least five grid lines.
    // - The intervals are chosen from a set of nice numbers.
    // - The intervals go through 0.
    let range = maxValue - minValue;
    if (range === 0) {
        range = 4;
    }

    // At least five lines.
    const interval = roundDown(range/4);

    // Start after the min value and end before the max value.
    const start = Math.ceil(minValue/interval)*interval;
    const last = Math.floor(maxValue/interval)*interval;
    const lineCount = Math.floor((last - start)/interval + 0.5) + 1;

    // Figure out the zero line, if any.
    const zeroIndex = Math.floor((0 - start)/interval + 0.5);

    for (let i = 0; i < lineCount; i++) {
        gridLines.push({
            value: start + interval*i,
            isZero: i === zeroIndex,
            drawLabel: true,
        });
    }

    return new Grid({ gridLines, log: false, minValue, maxValue });
}
