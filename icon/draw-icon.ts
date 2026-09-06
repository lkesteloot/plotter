// Draws the app icon procedurally, so that it's generated rather than checked in
// as a picture, using the same Canvas 2D that draws the plots.
//
// Bundled as an IIFE and injected into a blank page by make-icon.ts, which is
// how it gets a canvas to draw on.

import { blend, type Color, rgb, toCss, WHITE } from "../src/core/colors.js";

const WIDTH = 1024;
const HEIGHT = 1024;
// Geometry to match the macOS app icons: an 824x824 body in a 1024x1024 canvas,
// with corners rounded by about 23% of the width, and a small, faint shadow.
// The radius is the circular arc that best fits the shape macOS itself draws,
// whose corners are very slightly non-circular.
const MARGIN = 100;
const RADIUS = 193;
const SHADOW_SIZE = 14;
const SHADOW_OFFSET = 9;
// The shadow is a little wider than the body, not just nudged down.
const SHADOW_SPREAD = 5;
const SHADOW_COLOR = "rgb(0 0 0)";
const SHADOW_OPACITY = 0.19;
const INTERNAL_WIDTH = WIDTH - 2*MARGIN;
const INTERNAL_HEIGHT = HEIGHT - 2*MARGIN;
const AXIS_LINE_WIDTH = 16;
const DATA_LINE_WIDTH = 32;

// Match the colors in the plot itself, though less desaturated so that the icon
// reads at small sizes.
const BACKGROUND_COLOR = rgb(0.2, 0.18, 0.14);
const AXIS_COLOR = blend(BACKGROUND_COLOR, 0.6, WHITE);
const DATA_COLOR_1 = blend(BACKGROUND_COLOR, 0.6, rgb(0, 1, 0));
const DATA_COLOR_2 = blend(BACKGROUND_COLOR, 0.6, rgb(1, 1, 0));

// The two curves, a sine and a cosine over the width of the icon. They're drawn
// past the margins and clipped, so they run off the edges.
function sineY(x: number): number {
    return curveY(x, Math.sin);
}

function cosineY(x: number): number {
    return curveY(x, Math.cos);
}

function curveY(x: number, fn: (t: number) => number): number {
    const t = 4*(x - MARGIN - INTERNAL_WIDTH/2)/INTERNAL_WIDTH;

    return MARGIN + INTERNAL_HEIGHT/2 - fn(t)*INTERNAL_HEIGHT/2*0.75;
}

function drawCurve(ctx: CanvasRenderingContext2D, fn: (x: number) => number, color: Color): void {
    ctx.strokeStyle = toCss(color);
    ctx.lineWidth = DATA_LINE_WIDTH;
    ctx.lineJoin = "round";
    ctx.lineCap = "round";

    ctx.beginPath();
    for (let x = 0; x <= WIDTH; x++) {
        if (x === 0) {
            ctx.moveTo(x, fn(x));
        } else {
            ctx.lineTo(x, fn(x));
        }
    }
    ctx.stroke();
}

// Draw the icon at its full size. Smaller icons are scaled down from this master
// rather than drawn again at each size.
function drawMaster(ctx: CanvasRenderingContext2D): void {
    ctx.save();
    ctx.globalAlpha = SHADOW_OPACITY;
    ctx.drawImage(makeShadow(), 0, 0);
    ctx.restore();

    // Everything else is clipped to the rounded rect.
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(MARGIN, MARGIN, WIDTH - MARGIN*2, HEIGHT - MARGIN*2, RADIUS);
    ctx.clip();

    ctx.fillStyle = toCss(BACKGROUND_COLOR);
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    ctx.strokeStyle = toCss(AXIS_COLOR);
    ctx.lineWidth = AXIS_LINE_WIDTH;
    ctx.beginPath();
    ctx.moveTo(WIDTH/2, 0);
    ctx.lineTo(WIDTH/2, HEIGHT);
    ctx.moveTo(0, HEIGHT/2);
    ctx.lineTo(WIDTH, HEIGHT/2);
    ctx.stroke();

    // Green on top.
    drawCurve(ctx, cosineY, DATA_COLOR_2);
    drawCurve(ctx, sineY, DATA_COLOR_1);

    ctx.restore();
}

// The shadow: the same rounded rect, blurred and nudged downward. It's drawn on
// its own canvas because blurring a shape blurs its color along with its alpha,
// which leaves the gray drifting by a few levels at the edges. Compositing flat
// gray through the blurred shape keeps the color exactly constant.
function makeShadow(): HTMLCanvasElement {
    const canvas = makeCanvas(WIDTH, HEIGHT);
    const ctx = get2dContext(canvas);

    ctx.filter = `blur(${SHADOW_SIZE}px)`;
    ctx.fillStyle = SHADOW_COLOR;
    ctx.beginPath();
    ctx.roundRect(MARGIN - SHADOW_SPREAD, MARGIN + SHADOW_OFFSET - SHADOW_SPREAD,
        WIDTH - MARGIN*2 + SHADOW_SPREAD*2, HEIGHT - MARGIN*2 + SHADOW_SPREAD*2,
        RADIUS + SHADOW_SPREAD);
    ctx.fill();
    ctx.filter = "none";

    ctx.globalCompositeOperation = "source-in";
    ctx.fillStyle = SHADOW_COLOR;
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    return canvas;
}

function get2dContext(canvas: HTMLCanvasElement): CanvasRenderingContext2D {
    const ctx = canvas.getContext("2d");
    if (ctx === null) {
        throw new Error("Can't get a 2D canvas context.");
    }

    return ctx;
}

function makeCanvas(width: number, height: number): HTMLCanvasElement {
    const canvas = document.createElement("canvas");

    canvas.width = width;
    canvas.height = height;

    return canvas;
}

// Shrink by halving repeatedly rather than in one step. Going from 1024 straight
// down to 16 aliases badly: the curves break into dashes and the axes disappear.
// Every size we need is a power of two, so the halves land exactly.
function shrinkTo(image: HTMLCanvasElement, size: number): HTMLCanvasElement {
    let current = image;

    while (current.width > size) {
        const width = Math.max(size, Math.floor(current.width/2));
        const smaller = makeCanvas(width, width);
        const ctx = get2dContext(smaller);

        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";
        ctx.drawImage(current, 0, 0, width, width);

        current = smaller;
    }

    return current;
}

// Return the icon at the given size as a PNG data URL.
function plotterIcon(size: number): string {
    const master = makeCanvas(WIDTH, HEIGHT);
    drawMaster(get2dContext(master));

    return shrinkTo(master, size).toDataURL("image/png");
}

// Injected into a blank page, so hand the function to whoever asks for it.
(globalThis as unknown as { plotterIcon: (size: number) => string }).plotterIcon = plotterIcon;
