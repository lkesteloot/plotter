// A left or right vertical axis.

import { Grid, makeRangeGrid } from "./grid.js";
import { type Series } from "./series.js";

export class Axis {
    // The series displayed by this axis.
    readonly seriesArray: Series[] = [];

    // The lowest and largest values we must display.
    minValue = 0;
    maxValue = 0;
    // Max minus min.
    range = 0;
    // The grid used for this axis. Created by updateStats().
    grid: Grid | undefined = undefined;

    addSeries(series: Series): void {
        this.seriesArray.push(series);
    }

    // Update the stats and create the grid after all series have been added.
    updateStats(): void {
        let first = true;

        for (const series of this.seriesArray) {
            if (first) {
                this.minValue = series.minValue;
                this.maxValue = series.maxValue;
                first = false;
            } else {
                this.minValue = Math.min(this.minValue, series.minValue);
                this.maxValue = Math.max(this.maxValue, series.maxValue);
            }
        }

        this.range = this.maxValue - this.minValue;
        this.grid = makeRangeGrid(this.minValue, this.maxValue);
    }
}
