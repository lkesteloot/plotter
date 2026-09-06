import { describe, expect, test } from "vitest";
import { Grid, type GridLine, makeDomainGrid, makeRangeGrid, roundDown, roundUp } from "../src/core/grid.js";

function checkGridLine(grid: Grid, index: number,
                       value: number, isZero: boolean, drawLabel: boolean, label: string): void {

    const gridLine = grid.gridLines[index] as GridLine;

    expect(gridLine.value).toBeCloseTo(value, 5);
    expect(gridLine.isZero).toBe(isZero);
    expect(gridLine.drawLabel).toBe(drawLabel);
    expect(grid.gridValueLabelFor(gridLine.value, false)).toBe(label);
}

// A grid that has no data, for testing the pure functions on it.
function emptyGrid(): Grid {
    return new Grid({ gridLines: [], log: false, minValue: 0, maxValue: 0 });
}

describe("roundUp", () => {
    test("rounds up to a nice number", () => {
        expect(roundUp(1)).toBe(1);
        expect(roundUp(4)).toBe(4);
        expect(roundUp(4.1)).toBe(5);
        expect(roundUp(.99)).toBe(1);
        expect(roundUp(10)).toBe(10);
        expect(roundUp(9.9)).toBe(10);
        expect(roundUp(86)).toBe(100);
        expect(roundUp(123)).toBe(150);
        expect(roundUp(1234)).toBe(1500);
    });
});

describe("roundDown", () => {
    test("rounds down to a nice number", () => {
        expect(roundDown(1)).toBe(1);
        expect(roundDown(4)).toBe(4);
        expect(roundDown(4.1)).toBe(4);
        expect(roundDown(3.9)).toBe(3);
        expect(roundDown(.99)).toBeCloseTo(.8, 10);
        expect(roundDown(10)).toBe(10);
        expect(roundDown(9.9)).toBe(8);
        expect(roundDown(86)).toBe(80);
        expect(roundDown(123)).toBe(100);
        expect(roundDown(1234)).toBe(1000);
    });
});

describe("range grid", () => {
    test("zero to five", () => {
        const grid = makeRangeGrid(0, 5);
        expect(grid.gridLines.length).toBe(5);
        checkGridLine(grid, 0, 0, true, true, "0");
        checkGridLine(grid, 1, 1.5, false, true, "1.5");
        checkGridLine(grid, 2, 3, false, true, "3");
    });

    test("straddling zero", () => {
        const grid = makeRangeGrid(-1, 24);
        expect(grid.gridLines.length).toBe(5);
        checkGridLine(grid, 0, -8, false, true, "-8");
        checkGridLine(grid, 1, 0, true, true, "0");
        checkGridLine(grid, 2, 8, false, true, "8");
    });

    test("large range uses grouping", () => {
        const grid = makeRangeGrid(-92.5853, 2450.74);
        expect(grid.gridLines.length).toBe(5);
        checkGridLine(grid, 0, -1000, false, true, "-1,000");
        checkGridLine(grid, 1, 0, true, true, "0");
        checkGridLine(grid, 2, 1000, false, true, "1,000");
    });

    test("fraction digits", () => {
        expect(makeRangeGrid(0.03, 4.09).fractionDigits).toBe(0);
    });

    test("small range", () => {
        const grid = makeRangeGrid(0.03, 2.09);
        expect(grid.gridLines.length).toBe(5);
        checkGridLine(grid, 0, 0, true, true, "0");
        checkGridLine(grid, 1, 0.6, false, true, "0.6");
        checkGridLine(grid, 2, 1.2, false, true, "1.2");
    });
});

describe("domain grid", () => {
    test.each([
        ["exact", 0, 4],
        ["max just past a line", 0, 4.1],
        ["min just below zero", -0.1, 4],
    ])("%s", (_name, minValue, maxValue) => {
        const grid = makeDomainGrid(minValue, maxValue, false);
        expect(grid.gridLines.length).toBe(5);
        checkGridLine(grid, 0, 0, true, true, "0");
        checkGridLine(grid, 1, 1, false, true, "1");
        checkGridLine(grid, 2, 2, false, true, "2");
    });

    test("wider range", () => {
        const grid = makeDomainGrid(-0.1, 30.1, false);
        expect(grid.gridLines.length).toBe(5);
        checkGridLine(grid, 0, 0, true, true, "0");
        checkGridLine(grid, 1, 7.5, false, true, "7.5");
        checkGridLine(grid, 2, 15, false, true, "15");
    });

    test("log labels only the powers of ten", () => {
        const grid = makeDomainGrid(1, 1000, true);
        expect(grid.gridLines.length).toBe(28);
        checkGridLine(grid, 0, 1, false, true, "1");
        checkGridLine(grid, 1, 2, false, false, "2");
        checkGridLine(grid, 2, 3, false, false, "3");
        checkGridLine(grid, 27, 1000, false, true, "1,000");
    });

    test("log requires positive values", () => {
        expect(() => makeDomainGrid(0, 100, true)).toThrow(/positive/);
    });
});

describe("value labels", () => {
    test("formats numbers", () => {
        const grid = emptyGrid();

        expect(grid.gridValueLabelFor(0, false)).toBe("0");
        expect(grid.gridValueLabelFor(5, false)).toBe("5");
        expect(grid.gridValueLabelFor(1234, false)).toBe("1,234");
        expect(grid.gridValueLabelFor(0.1, false)).toBe("0.1");
        expect(grid.gridValueLabelFor(0.23, false)).toBe("0.23");
        expect(grid.gridValueLabelFor(100.1, false)).toBe("100.1");
    });

    test("dates omit the thousands separator", () => {
        const grid = emptyGrid();

        expect(grid.gridValueLabelFor(2018, false)).toBe("2,018");
        expect(grid.gridValueLabelFor(2018, true)).toBe("2018");
    });
});

describe("positions", () => {
    test("linear round trip", () => {
        const grid = makeRangeGrid(0, 5);

        expect(grid.positionForValue(0)).toBeCloseTo(0, 10);
        expect(grid.positionForValue(6)).toBeCloseTo(1, 10);
        expect(grid.valueForPosition(0.5)).toBeCloseTo(3, 10);
    });

    test("log round trip", () => {
        const grid = makeDomainGrid(1, 1000, true);

        expect(grid.positionForValue(1)).toBeCloseTo(0, 10);
        expect(grid.positionForValue(10)).toBeCloseTo(1/3, 10);
        expect(grid.positionForValue(1000)).toBeCloseTo(1, 10);
        expect(grid.valueForPosition(2/3)).toBeCloseTo(100, 10);
    });
});
