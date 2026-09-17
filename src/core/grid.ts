// The grid lines drawn behind a plot, and the mapping between data values and
// positions along an axis.

import { DatePrecision, epochDayFor, formatDate, ymdFor } from "./dates.js";

// The set of numbers that we can use for grid intervals.
const VALID_VALUES = [1, 1.5, 2, 3, 4, 5, 6, 7.5, 8, 10];

// Number of lines in a range (vertical) grid.
const RANGE_LINE_COUNT = 5;

// How far apart the lines of a date grid are. Short steps are a number of days;
// longer ones are a number of months, since months and years aren't a fixed
// number of days. A year is 12 months.
interface DateStep {
    unit: "day" | "month";
    count: number;
}

function days(count: number): DateStep {
    return { unit: "day", count };
}

function months(count: number): DateStep {
    return { unit: "month", count };
}

// The steps we can use between the lines of a date grid, in increasing size:
// days, weeks, months, quarters, half-years, then years. No step is much more
// than twice the one before it, so that we never draw many more lines than we
// wanted, since date labels are wide.
const DATE_STEPS: readonly DateStep[] = [
    days(1), days(2), days(3), days(5), days(7), days(14),
    months(1), months(2), months(3), months(6),
    months(12), months(24), months(60), months(120), months(240), months(600),
];

// The average length of a month, for comparing steps of different units. Only
// used to choose a step; the lines themselves land on real month boundaries.
const DAYS_PER_MONTH = 365.25/12;

// 1970-01-05 was a Monday. Weekly grids are drawn on Mondays, to match the ISO
// dates we label them with.
const MONDAY_EPOCH_DAY = 4;

// Pinned rather than following the current locale, so that plots and tests look
// the same everywhere.
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
    // Set when the values are dates, in which case it says how much of each
    // date the labels show.
    private readonly datePrecision: DatePrecision | undefined;

    constructor(options: {
        gridLines: readonly GridLine[];
        log: boolean;
        minValue: number;
        maxValue: number;
        logMinValue?: number;
        logMaxValue?: number;
        datePrecision?: DatePrecision;
    }) {
        this.gridLines = options.gridLines;
        this.log = options.log;
        this.minValue = options.minValue;
        this.maxValue = options.maxValue;
        this.logMinValue = options.logMinValue ?? 0;
        this.logMaxValue = options.logMaxValue ?? 0;
        this.datePrecision = options.datePrecision;

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

    // What text to draw at this value. Years are drawn without grouping, so
    // that one shows as "2018" and not "2,018".
    gridValueLabelFor(value: number, isYear: boolean): string {
        if (this.datePrecision !== undefined) {
            return formatDate(value, this.datePrecision);
        }

        const format = isYear ? UNGROUPED_FORMAT : GROUPED_FORMAT;

        // Intl formats negative zero as "-0", which looks wrong on an axis.
        return format.format(value === 0 ? 0 : value);
    }

    // Take a value and round it to a nice value given the range of this grid.
    roundDisplayedValue(value: number): number {
        if (this.datePrecision !== undefined) {
            // We don't plot anything finer than a day.
            return Math.floor(value + 0.5);
        }

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

// How big a step to put between the lines of a date grid covering this many
// days. Like the numeric domain grid, we want as few lines as possible but at
// least five, so we take the largest step that fits four times.
function dateStepFor(range: number): DateStep {
    // Ranges of many centuries run off the end of the table.
    const largest = DATE_STEPS[DATE_STEPS.length - 1]!;
    if (lengthOf(largest) <= range/4) {
        return longDateStepFor(range);
    }

    let step = DATE_STEPS[0]!;

    for (const candidate of DATE_STEPS) {
        if (lengthOf(candidate) <= range/4) {
            step = candidate;
        }
    }

    return step;
}

// The step for a range longer than the table covers: one, two or five times a
// power of ten years, whichever is the largest that fits.
function longDateStepFor(range: number): DateStep {
    const years = range/4/365.25;
    const decade = Math.pow(10, Math.floor(Math.log10(years)));
    const digit = years/decade;

    const multiple = digit >= 5 ? 5 : digit >= 2 ? 2 : 1;

    return months(Math.round(multiple*decade)*12);
}

// The approximate length of a step, in days.
function lengthOf(step: DateStep): number {
    return step.unit === "day" ? step.count : step.count*DAYS_PER_MONTH;
}

// How much of each date to show for a grid with this step. Lines a year or more
// apart are all on January 1st, so the month and day would be noise.
function datePrecisionFor(step: DateStep): DatePrecision {
    if (step.unit === "day") {
        return DatePrecision.Day;
    }

    return step.count < 12 ? DatePrecision.Month : DatePrecision.Year;
}

// Build the grid for a horizontal axis whose values are dates (as days since the
// epoch). Like the numeric domain grid, it spans exactly the data. The lines land
// on calendar boundaries: the first of the month for monthly and longer steps,
// and Mondays for weekly ones.
export function makeDateDomainGrid(minValue: number, maxValue: number): Grid {
    const step = dateStepFor(maxValue - minValue);
    const gridLines: GridLine[] = [];

    if (step.unit === "day") {
        // Weeks are drawn on Mondays; shorter steps just start at the first
        // multiple of the step, which keeps them from moving as data is added.
        const phase = step.count%7 === 0 ? MONDAY_EPOCH_DAY%step.count : 0;
        const start = Math.ceil((minValue - phase)/step.count)*step.count + phase;

        for (let value = start; value <= maxValue; value += step.count) {
            gridLines.push({ value, isZero: false, drawLabel: true });
        }
    } else {
        // Count months since year 0 so that we can align to a multiple of the
        // step: every third month, every other January, and so on.
        const ymd = ymdFor(minValue);
        let month = Math.ceil((ymd.year*12 + ymd.month - 1)/step.count)*step.count;

        for (;;) {
            const year = Math.floor(month/12);
            const value = epochDayFor(year, month - year*12 + 1, 1);
            if (value > maxValue) {
                break;
            }

            // The first aligned month can start before the data does.
            if (value >= minValue) {
                gridLines.push({ value, isZero: false, drawLabel: true });
            }

            month += step.count;
        }
    }

    return new Grid({
        gridLines,
        log: false,
        minValue,
        maxValue,
        datePrecision: datePrecisionFor(step),
    });
}
