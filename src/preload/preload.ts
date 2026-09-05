// The only bridge between the main process and the renderer. The renderer has
// no Node access; all it can do is receive the text of a file to plot.

import { contextBridge, ipcRenderer } from "electron";

export interface PlotterApi {
    onData(callback: (message: { text: string; filename: string }) => void): void;
}

const api: PlotterApi = {
    onData(callback) {
        ipcRenderer.on("data", (_event, message) => callback(message));
    },
};

contextBridge.exposeInMainWorld("plotter", api);
