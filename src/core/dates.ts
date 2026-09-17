// Dates in the input, in "YYYY-MM-DD" format.
//
// We store them as days since 1970-01-01, so that the rest of the program can
// treat them as ordinary numbers: they subtract to a number of days, derivatives
// come out per day, and the grid can do arithmetic on them. Everything here is
// in UTC, so that a date never shifts to the day before in a western timezone.

// A whole field that's a date. The ranges are checked in parseDate().
const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

const MS_PER_DAY = 24*60*60*1000;

// A year, month (1 to 12), and day (1 to 31).
export interface Ymd {
    year: number;
    month: number;
    day: number;
}

// How much of a date to show in a label. Grid lines a year apart don't need to
// repeat the month and day.
export enum DatePrecision {
    Day,
    Month,
    Year,
}

// Convert a year, month, and day to days since the epoch. Months outside of 1 to
// 12 roll over into the neighboring years, which is how the grid steps by month.
export function epochDayFor(year: number, month: number, day: number): number {
    // Not Date.UTC(), which maps years 0 to 99 to the 20th century.
    const date = new Date(0);
    date.setUTCFullYear(year, month - 1, day);

    return date.getTime()/MS_PER_DAY;
}

// Split days since the epoch into a year, month, and day. Fractional days (which
// come from the domain of a derivative) are truncated to the day they're in.
export function ymdFor(epochDay: number): Ymd {
    const date = new Date(Math.floor(epochDay)*MS_PER_DAY);

    return {
        year: date.getUTCFullYear(),
        month: date.getUTCMonth() + 1,
        day: date.getUTCDate(),
    };
}

// Parse a field as a date, returning days since the epoch, or undefined if it's
// not a date at all.
export function parseDate(field: string): number | undefined {
    const match = DATE_RE.exec(field);
    if (match === null) {
        return undefined;
    }

    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);

    const epochDay = epochDayFor(year, month, day);

    // Reject dates that don't exist, like February 30th, which would otherwise
    // roll over into the next month.
    const ymd = ymdFor(epochDay);
    if (ymd.year !== year || ymd.month !== month || ymd.day !== day) {
        return undefined;
    }

    return epochDay;
}

// Format days since the epoch, showing only the fields that the precision calls
// for: "2018-03-05", "2018-03", or "2018".
export function formatDate(epochDay: number, precision: DatePrecision): string {
    const ymd = ymdFor(epochDay);

    const year = String(ymd.year).padStart(4, "0");
    if (precision === DatePrecision.Year) {
        return year;
    }

    const month = String(ymd.month).padStart(2, "0");
    if (precision === DatePrecision.Month) {
        return `${year}-${month}`;
    }

    return `${year}-${month}-${String(ymd.day).padStart(2, "0")}`;
}
