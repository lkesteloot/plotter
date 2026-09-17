// Tests for parsing and formatting the dates described in the README.

import { describe, expect, test } from "vitest";
import { DatePrecision, epochDayFor, formatDate, parseDate, ymdFor } from "../src/core/dates.js";

describe("parseDate", () => {
    test("returns days since the epoch", () => {
        expect(parseDate("1970-01-01")).toBe(0);
        expect(parseDate("1969-12-31")).toBe(-1);
        expect(parseDate("2018-03-05")).toBe(17595);
        expect(parseDate("2020-02-29")).toBe(18321);
    });

    test("is not fooled by the local timezone", () => {
        // This is the hour that would show up as the day before if we used
        // local time anywhere.
        expect(parseDate("2018-03-05")! - parseDate("2018-03-04")!).toBe(1);
        expect(formatDate(parseDate("2018-03-05")!, DatePrecision.Day)).toBe("2018-03-05");
    });

    test("rejects fields that aren't dates", () => {
        expect(parseDate("2018")).toBeUndefined();
        expect(parseDate("20180305")).toBeUndefined();
        expect(parseDate("03-05-2018")).toBeUndefined();
        expect(parseDate("2018-3-5")).toBeUndefined();
        expect(parseDate("2018-03-05x")).toBeUndefined();
        expect(parseDate("-1.5e3")).toBeUndefined();
    });

    test("rejects dates that don't exist", () => {
        expect(parseDate("2018-13-01")).toBeUndefined();
        expect(parseDate("2018-00-01")).toBeUndefined();
        expect(parseDate("2018-02-30")).toBeUndefined();
        expect(parseDate("2019-02-29")).toBeUndefined();
        expect(parseDate("2018-04-31")).toBeUndefined();
    });

    test("handles early years, which Date treats as the 20th century", () => {
        expect(ymdFor(parseDate("0099-06-15")!)).toEqual({ year: 99, month: 6, day: 15 });
    });
});

describe("formatDate", () => {
    test("shows only what the precision calls for", () => {
        const epochDay = parseDate("2018-03-05")!;

        expect(formatDate(epochDay, DatePrecision.Day)).toBe("2018-03-05");
        expect(formatDate(epochDay, DatePrecision.Month)).toBe("2018-03");
        expect(formatDate(epochDay, DatePrecision.Year)).toBe("2018");
    });

    test("pads early years", () => {
        expect(formatDate(epochDayFor(99, 6, 15), DatePrecision.Year)).toBe("0099");
    });

    test("truncates the fractional days that derivatives produce", () => {
        expect(formatDate(parseDate("2018-03-05")! + 0.5, DatePrecision.Day)).toBe("2018-03-05");
    });
});

describe("epochDayFor", () => {
    test("rolls months over into the neighboring years", () => {
        expect(epochDayFor(2018, 13, 1)).toBe(epochDayFor(2019, 1, 1));
        expect(epochDayFor(2018, 0, 1)).toBe(epochDayFor(2017, 12, 1));
    });
});
