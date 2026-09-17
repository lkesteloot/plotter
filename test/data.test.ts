// Tests for the parsing that Data and Series do, covering the header options
// described in the README.

import { describe, expect, test } from "vitest";
import { Data } from "../src/core/data.js";
import { parseDate } from "../src/core/dates.js";
import { SeriesType } from "../src/core/series.js";
import { toCss } from "../src/core/colors.js";

describe("parsing", () => {
    test("reads columns separated by spaces or tabs", () => {
        const data = Data.parse("1.1 5\t234\n1.2 4.9 254\n");

        expect(data.dataPointCount).toBe(2);
        expect(data.seriesArray.length).toBe(3);
        expect(data.seriesArray[0]!.valueAt(1)).toBe(1.2);
        expect(data.seriesArray[2]!.valueAt(0)).toBe(234);
    });

    test("a trailing newline does not add a data point", () => {
        expect(Data.parse("1\n2\n3\n").dataPointCount).toBe(3);
        expect(Data.parse("1\n2\n3").dataPointCount).toBe(3);
        expect(Data.parse("1\n\n2\n\n").dataPointCount).toBe(2);
    });

    test("reads exponents and negatives", () => {
        const data = Data.parse("-1.5e3 2E-2\n");

        expect(data.seriesArray[0]!.valueAt(0)).toBe(-1500);
        expect(data.seriesArray[1]!.valueAt(0)).toBe(0.02);
    });

    test("keeps values that ran together", () => {
        const data = Data.parse("1.5-2.5 3\n");

        expect(data.seriesArray.length).toBe(3);
        expect(data.seriesArray[0]!.valueAt(0)).toBe(1.5);
        expect(data.seriesArray[1]!.valueAt(0)).toBe(-2.5);
        expect(data.seriesArray[2]!.valueAt(0)).toBe(3);
    });

    test("skips lines that aren't data, rather than mining them for numbers", () => {
        const data = Data.parse("1 2\nDone in 5 seconds\n3 4\n");

        expect(data.dataPointCount).toBe(2);
        expect(data.seriesArray.length).toBe(2);
        expect(data.seriesArray[1]!.valueAt(1)).toBe(4);
    });

    test("skips lines with a field that isn't a number", () => {
        const data = Data.parse("1 2\n3 N/A\n5 6\n");

        expect(data.dataPointCount).toBe(2);
        expect(data.seriesArray[0]!.valueAt(1)).toBe(5);
    });

    test("detects a header row", () => {
        const data = Data.parse("Growth\tAge\n1 2\n3 4\n");

        expect(data.dataPointCount).toBe(2);
        expect(data.seriesArray.map((s) => s.title)).toEqual(["Growth", "Age"]);
    });

    test("a numeric first row is data, not a header", () => {
        const data = Data.parse("1 2\n3 4\n");

        expect(data.dataPointCount).toBe(2);
        expect(data.seriesArray[0]!.title).toBeUndefined();
    });

    test("exponents alone do not look like a header", () => {
        const data = Data.parse("1e3 2e4\n5 6\n");

        expect(data.dataPointCount).toBe(2);
        expect(data.seriesArray[0]!.valueAt(0)).toBe(1000);
    });

    test("empty options force a numeric row to be a header", () => {
        const data = Data.parse("1[]\t2[]\n5 6\n");

        expect(data.dataPointCount).toBe(1);
        expect(data.seriesArray.map((s) => s.title)).toEqual(["1", "2"]);
    });
});

describe("header options", () => {
    test("color", () => {
        const data = Data.parse("A [red]\tB [purple]\n1 2\n");

        expect(toCss(data.seriesArray[0]!.color!)).toBe("rgb(255 0 0)");
        expect(toCss(data.seriesArray[1]!.color!)).toBe("rgb(159 64 159)");
    });

    test("hide removes the series", () => {
        const data = Data.parse("A\tB [hide]\tC\n1 2 3\n");

        expect(data.seriesArray.map((s) => s.title)).toEqual(["A", "C"]);
    });

    test("left and right axes", () => {
        const data = Data.parse("A [left]\tB [right]\tC\n1 2 3\n");

        expect(data.leftAxis.seriesArray.map((s) => s.title)).toEqual(["A", "C"]);
        expect(data.rightAxis.seriesArray.map((s) => s.title)).toEqual(["B"]);
    });

    test("multiple options, in any order, with spaces", () => {
        const series = Data.parse("A [ right , red , zero ]\n1\n").seriesArray[0]!;

        expect(series.seriesType).toBe(SeriesType.Right);
        expect(series.zero).toBe(true);
        expect(toCss(series.color!)).toBe("rgb(255 0 0)");
    });

    test("unknown options are ignored", () => {
        const series = Data.parse("A [bogus]\n1\n").seriesArray[0]!;

        expect(series.title).toBe("A");
        expect(series.color).toBeUndefined();
    });

    test("zero includes zero in the range", () => {
        const plain = Data.parse("A\n400\n410\n").leftAxis;
        const zeroed = Data.parse("A [zero]\n400\n410\n").leftAxis;

        expect(plain.minValue).toBe(400);
        expect(zeroed.minValue).toBe(0);
    });
});

describe("domain", () => {
    test("is implicitly the line number", () => {
        const data = Data.parse("5\n6\n7\n");
        const domain = data.domainSeriesForDerivative(0);

        expect(domain.isImplicit).toBe(true);
        expect(domain.count).toBe(3);
        expect(domain.valueAt(0)).toBe(1);
        expect(domain.valueAt(2)).toBe(3);
    });

    test("can be given explicitly", () => {
        const data = Data.parse("Year [domain]\tValue\n2000 5\n2010 6\n");
        const domain = data.domainSeriesForDerivative(0);

        expect(domain.isImplicit).toBe(false);
        expect(domain.valueAt(0)).toBe(2000);
        expect(data.leftAxis.seriesArray.map((s) => s.title)).toEqual(["Value"]);
    });
});

describe("derivatives", () => {
    test("first derivative shortens the series and marks the title", () => {
        // y = x^2 over 1, 2, 3, 4 has slopes 3, 5, 7.
        const data = Data.parse("X [domain]\tY [derivative]\n1 1\n2 4\n3 9\n4 16\n");
        const series = data.seriesArray[1]!;

        expect(series.title).toBe("Y’");
        expect(series.count).toBe(3);
        expect(series.valueAt(0)).toBe(3);
        expect(series.valueAt(1)).toBe(5);
        expect(series.valueAt(2)).toBe(7);
    });

    test("its domain is the midpoints", () => {
        const data = Data.parse("X [domain]\tY [derivative]\n1 1\n2 4\n3 9\n4 16\n");
        const domain = data.domainSeriesForDerivative(1);

        expect(domain.count).toBe(3);
        expect(domain.valueAt(0)).toBe(1.5);
        expect(domain.valueAt(2)).toBe(3.5);
    });

    test("second derivative", () => {
        const data = Data.parse("X [domain]\tY [derivative,derivative]\n1 1\n2 4\n3 9\n4 16\n");
        const series = data.seriesArray[1]!;

        expect(series.title).toBe("Y’’");
        expect(series.count).toBe(2);
        expect(series.valueAt(0)).toBe(2);
        expect(series.valueAt(1)).toBe(2);
    });
});

describe("dates", () => {
    test("are read as days since the epoch", () => {
        const data = Data.parse("2018-03-05 1\n2018-03-06 2\n");
        const series = data.seriesArray[0]!;

        expect(data.dataPointCount).toBe(2);
        expect(series.isDate).toBe(true);
        expect(series.valueAt(0)).toBe(17595);
        expect(series.valueAt(1)).toBe(17596);
        expect(data.seriesArray[1]!.isDate).toBe(false);
    });

    test("a column of dates is one column", () => {
        // The values would be three numbers each if we scanned for numbers.
        expect(Data.parse("2018-03-05 1\n").seriesArray.length).toBe(2);
    });

    test("a column is only a date column if every value is a date", () => {
        expect(Data.parse("2018-03-05\n2018-03-06\n").seriesArray[0]!.isDate).toBe(true);
        expect(Data.parse("2018-03-05\n17596\n").seriesArray[0]!.isDate).toBe(false);
        expect(Data.parse("17595\n2018-03-06\n").seriesArray[0]!.isDate).toBe(false);
    });

    test("a date domain gets a date grid", () => {
        const data = Data.parse(
            "Day [domain]\tValue\n2026-01-15 1\n2026-06-10 2\n2026-12-20 3\n");
        const grid = data.domainGrid!;

        expect(data.domainSeriesForDerivative(0).isDate).toBe(true);
        expect(grid.gridLines.map((gridLine) => grid.gridValueLabelFor(gridLine.value, false)))
            .toEqual(["2026-03", "2026-05", "2026-07", "2026-09", "2026-11"]);
    });

    test("zero does not drag a date axis back to 1970", () => {
        const series = Data.parse("Day [domain,zero]\n2026-01-15\n2026-12-20\n").seriesArray[0]!;

        expect(series.minValue).toBe(parseDate("2026-01-15"));
    });

    test("a derivative against dates is per day", () => {
        // Ten units over the five days from the 5th to the 10th.
        const data = Data.parse(
            "Day [domain]\tValue [derivative]\n2018-03-05 0\n2018-03-10 10\n");

        expect(data.seriesArray[1]!.valueAt(0)).toBe(2);
    });
});
