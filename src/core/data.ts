// Parses the input file into series, axes and grids. Ported from Data.m.

import { Axis } from "./axis.js";
import { Grid, makeDomainGrid } from "./grid.js";
import { Series, SeriesType } from "./series.js";

// Letters we use to detect a header row. All letters except for "e", which
// might be an exponent (123e4). Also includes brackets so that a header that's
// entirely numeric can be forced by adding empty options.
const HEADER_RE = /[a-df-z[\]]/i;

// Any number we'd find in a data row, including exponents. Scanning for these
// rather than splitting on whitespace means a run-together pair like "1.5-2.5"
// still reads as two values.
const NUMBER_RE = /[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?/g;

// All the data we load from the input.
export class Data {
    // Every series has the same number of data points.
    seriesArray: Series[] = [];
    readonly leftAxis = new Axis();
    readonly rightAxis = new Axis();

    // The number of data points in any series.
    dataPointCount = 0;

    // Domain series, indexed by how many derivatives have been taken.
    private readonly derivativeDomainSeries: Series[] = [];
    // The grid for the horizontal axis. Created by processData().
    domainGrid: Grid | undefined = undefined;

    // What column to write to next.
    private currentColumn = 0;
    // Whether we're still waiting for the first non-blank line.
    private firstLine = true;

    // Parse an entire input file.
    static parse(text: string): Data {
        const data = new Data();

        for (const line of text.split("\n")) {
            data.newLine(line);
        }
        data.processData();

        return data;
    }

    newLine(line: string): void {
        // If it's the first line we see, and it contains letters, then it's a
        // header row.
        if (this.firstLine && line.trim().length > 0) {
            this.firstLine = false;
            if (HEADER_RE.test(line)) {
                this.parseHeader(line);
                return;
            }
        }

        const values = line.match(NUMBER_RE);
        if (values === null) {
            // Blank line. Don't create a row for it, or a trailing newline would
            // add a phantom data point at the end of the plot.
            return;
        }

        this.currentColumn = 0;
        this.dataPointCount++;

        for (const value of values) {
            this.getNextSeries().addDataPoint(Number(value));
        }
    }

    // Parse the header row. The headers must be separated by tabs.
    private parseHeader(line: string): void {
        for (const header of line.split("\t")) {
            this.getNextSeries().setHeader(header);
        }
    }

    private getNextSeries(): Series {
        // Add a new Series if necessary.
        while (this.currentColumn >= this.seriesArray.length) {
            this.seriesArray.push(new Series());
        }

        return this.seriesArray[this.currentColumn++]!;
    }

    // Process the data once all lines have been read.
    processData(): void {
        // Remove hidden series.
        this.seriesArray = this.seriesArray.filter((series) => !series.hide);

        // Process and make axes.
        for (const series of this.seriesArray) {
            series.processData();

            switch (series.seriesType) {
                case SeriesType.Left:
                    this.leftAxis.addSeries(series);
                    break;

                case SeriesType.Right:
                    this.rightAxis.addSeries(series);
                    break;

                case SeriesType.Domain:
                    if (this.derivativeDomainSeries.length !== 0) {
                        console.warn("Cannot have more than one domain series.");
                    } else {
                        this.derivativeDomainSeries.push(series);
                    }
                    break;
            }
        }

        // Generate a domain series if one wasn't specified. One point per line.
        if (this.derivativeDomainSeries.length === 0) {
            const domainSeries = new Series();

            domainSeries.isImplicit = true;
            for (let i = 1; i <= this.dataPointCount; i++) {
                domainSeries.addDataPoint(i);
            }
            domainSeries.processData();

            this.derivativeDomainSeries.push(domainSeries);
        }

        // Generate domain series for the derivative range series. Each is the
        // midpoints of the one before it.
        for (const series of this.seriesArray) {
            for (let d = this.derivativeDomainSeries.length; d <= series.derivative; d++) {
                const newDomain = Series.copyOf(this.derivativeDomainSeries[d - 1]!);

                newDomain.replaceWithMidpoints();
                this.derivativeDomainSeries.push(newDomain);
            }
        }

        // Generate derivatives of the range series.
        for (const series of this.seriesArray) {
            if (series.seriesType !== SeriesType.Domain) {
                for (let d = 0; d < series.derivative; d++) {
                    series.computeDerivativeWithDomain(this.derivativeDomainSeries[d]!);
                }
            }
        }

        // Compute axis stats now that we've computed the derivatives. This also
        // computes the vertical grids.
        this.leftAxis.updateStats();
        this.rightAxis.updateStats();

        // Compute the domain grid lines we'll show when plotting.
        const domainSeries = this.derivativeDomainSeries[0]!;
        this.domainGrid = makeDomainGrid(
            domainSeries.minValue, domainSeries.maxValue, domainSeries.log);
    }

    domainSeriesForDerivative(derivative: number): Series {
        return this.derivativeDomainSeries[derivative]!;
    }

    // Whether there's anything worth drawing.
    get isEmpty(): boolean {
        return this.seriesArray.length === 0 || this.dataPointCount === 0;
    }
}
