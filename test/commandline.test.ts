import { describe, expect, test } from "vitest";
import { filenamesFromArgv } from "../src/main/commandline.js";

describe("command line", () => {
    test("packaged: argv is the binary then the files", () => {
        expect(filenamesFromArgv(
            ["/Applications/Plotter.app/Contents/MacOS/Plotter", "data.txt"], true))
            .toEqual(["data.txt"]);
    });

    test("development: argv is electron then the script then the files", () => {
        expect(filenamesFromArgv(
            ["/path/to/electron", "dist/main.js", "data.txt"], false))
            .toEqual(["data.txt"]);
    });

    test("several files", () => {
        expect(filenamesFromArgv(["Plotter", "a.txt", "b.txt"], true))
            .toEqual(["a.txt", "b.txt"]);
    });

    test("no files", () => {
        expect(filenamesFromArgv(["Plotter"], true)).toEqual([]);
    });

    test("ignores options, including the Finder's process serial number", () => {
        expect(filenamesFromArgv(
            ["Plotter", "--nodata", "-psn_0_12345", "data.txt"], true))
            .toEqual(["data.txt"]);
    });
});
