// Generates icon/Plotter.icns from draw-icon.ts. Run with "make icon".
//
// This runs under Electron because that's where we have a canvas. It draws into
// a blank page and writes out the sizes that "iconutil" wants.

import { app, BrowserWindow } from "electron";
import { execFileSync } from "node:child_process";
import { mkdirSync, rmSync, writeFileSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const ICON_DIR = resolve(__dirname);
const ICONSET_DIR = resolve(ICON_DIR, "Plotter.iconset");
const ICNS = resolve(ICON_DIR, "Plotter.icns");

// The sizes in a macOS iconset, as [size in points, scale].
const SIZES: readonly [number, number][] = [
    [16, 1], [16, 2],
    [32, 1], [32, 2],
    [128, 1], [128, 2],
    [256, 1], [256, 2],
    [512, 1], [512, 2],
];

function iconsetName(size: number, scale: number): string {
    return `icon_${size}x${size}${scale === 1 ? "" : `@${scale}x`}.png`;
}

app.whenReady().then(async () => {
    const window = new BrowserWindow({ show: false, width: 100, height: 100 });
    await window.loadURL("about:blank");

    // Inject the drawing code, which defines plotterIcon().
    await window.webContents.executeJavaScript(
        readFileSync(resolve(ICON_DIR, "draw-icon.js"), "utf8"));

    rmSync(ICONSET_DIR, { recursive: true, force: true });
    mkdirSync(ICONSET_DIR, { recursive: true });

    for (const [size, scale] of SIZES) {
        const pixels = size*scale;
        const dataUrl: string = await window.webContents.executeJavaScript(
            `plotterIcon(${pixels})`);

        const filename = resolve(ICONSET_DIR, iconsetName(size, scale));
        writeFileSync(filename, Buffer.from(dataUrl.split(",")[1]!, "base64"));
        console.log(`${iconsetName(size, scale)} (${pixels}x${pixels})`);
    }

    execFileSync("iconutil", ["-c", "icns", ICONSET_DIR, "-o", ICNS]);
    console.log(`Wrote ${ICNS}`);

    app.exit(0);
});
