// Wires the window up to the plot.

import { Data } from "../core/data.js";
import { Plot } from "./plot.js";
import { type PlotterApi } from "../preload/preload.js";

declare global {
    interface Window {
        plotter: PlotterApi;
    }
}

const canvas = document.querySelector<HTMLCanvasElement>("#plot");
if (canvas === null) {
    throw new Error("Can't find the canvas.");
}

const plot = new Plot(canvas);
plot.resize();

window.addEventListener("resize", () => plot.resize());

window.plotter.onData(({ text, filename }) => {
    document.title = filename.replace(/^.*\//, "");

    try {
        plot.setData(Data.parse(text));
    } catch (error) {
        // Bad data, such as a log plot with non-positive values. Show it in the
        // window; a modal alert would block the renderer.
        console.error(error);
        plot.setError(error instanceof Error ? error.message : String(error));
    }
});
