// Colors used to draw series, ported from Colors.m. Values match the AppKit
// system colors the original used, so plots look the same as before.

export interface Color {
    readonly r: number; // 0 to 1
    readonly g: number;
    readonly b: number;
}

export function rgb(r: number, g: number, b: number): Color {
    return { r, g, b };
}

// Mix "fraction" of "other" into "color". Equivalent to AppKit's
// blendedColorWithFraction:ofColor:.
export function blend(color: Color, fraction: number, other: Color): Color {
    return {
        r: color.r*(1 - fraction) + other.r*fraction,
        g: color.g*(1 - fraction) + other.g*fraction,
        b: color.b*(1 - fraction) + other.b*fraction,
    };
}

export function toCss(color: Color): string {
    const channel = (v: number) => Math.round(Math.max(0, Math.min(1, v))*255);
    return `rgb(${channel(color.r)} ${channel(color.g)} ${channel(color.b)})`;
}

export const WHITE = rgb(1, 1, 1);

const BLUE = blend(rgb(0, 0, 1), 0.25, WHITE);
const BROWN = rgb(0.6, 0.4, 0.2);
const CYAN = rgb(0, 1, 1);
const GRAY = rgb(0.5, 0.5, 0.5);
const GREEN = rgb(0, 1, 0);
const MAGENTA = rgb(1, 0, 1);
const ORANGE = rgb(1, 0.5, 0);
const PURPLE = blend(rgb(0.5, 0, 0.5), 0.25, WHITE);
const RED = rgb(1, 0, 0);
const YELLOW = rgb(1, 1, 0);

// The colors in the order they should be used by default.
export const COLORS: readonly Color[] = [
    GREEN,
    YELLOW,
    RED,
    CYAN,
    ORANGE,
    BLUE,
    MAGENTA,
    PURPLE,
    WHITE,
    BROWN,
    GRAY,
];

const COLORS_BY_NAME = new Map<string, Color>([
    ["blue", BLUE],
    ["brown", BROWN],
    ["cyan", CYAN],
    ["gray", GRAY],
    ["green", GREEN],
    ["magenta", MAGENTA],
    ["orange", ORANGE],
    ["purple", PURPLE],
    ["red", RED],
    ["white", WHITE],
    ["yellow", YELLOW],
]);

// Look up "blue", or undefined if the name isn't a color.
export function getColorByName(name: string): Color | undefined {
    return COLORS_BY_NAME.get(name);
}

// Color to use when we run out of colors.
export const FALLBACK_COLOR = WHITE;
