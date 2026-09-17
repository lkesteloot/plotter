// The main process: owns the command line, the windows, and the menu.

import { app, BrowserWindow, dialog, Menu, shell } from "electron";
import { readFile } from "node:fs/promises";
import { basename, resolve } from "node:path";

import { filenamesFromArgv } from "./commandline.js";

// Matches the background of the plot, so there's no white flash on open.
const BACKGROUND_COLOR = "#332e24";

// Which file each window is showing, so File > Reload knows what to re-read.
const filenames = new Map<number, string>();

// Every window shows a file; we never open an empty one.
async function createWindow(filename: string): Promise<BrowserWindow> {
    const window = new BrowserWindow({
        width: 1000,
        height: 700,
        backgroundColor: BACKGROUND_COLOR,
        title: basename(filename),
        webPreferences: {
            preload: resolve(__dirname, "preload.js"),
        },
    });

    await window.loadFile(resolve(__dirname, "index.html"));

    filenames.set(window.id, resolve(filename));
    await loadData(window);

    window.on("closed", () => filenames.delete(window.id));

    return window;
}

// Read the window's file and hand the text to the renderer, which parses it.
async function loadData(window: BrowserWindow): Promise<void> {
    const filename = filenames.get(window.id);
    if (filename === undefined) {
        return;
    }

    try {
        const text = await readFile(filename, "utf8");
        window.webContents.send("data", { text, filename });
    } catch (error) {
        dialog.showMessageBox(window, {
            type: "error",
            message: `Can't read ${basename(filename)}`,
            detail: error instanceof Error ? error.message : String(error),
        });
    }
}

async function openFile(): Promise<void> {
    const result = await dialog.showOpenDialog({
        properties: ["openFile", "multiSelections"],
    });

    for (const filename of result.filePaths) {
        await createWindow(filename);
    }
}

// Whether any plot is showing. Used to decide whether there's any point in
// staying open.
function haveWindows(): boolean {
    return BrowserWindow.getAllWindows().length > 0;
}

function buildMenu(): void {
    const template: Electron.MenuItemConstructorOptions[] = [
        {
            role: "appMenu",
        },
        {
            label: "File",
            submenu: [
                { label: "Open…", accelerator: "Cmd+O", click: openFile },
                { type: "separator" },
                {
                    label: "Reload",
                    accelerator: "Cmd+R",
                    click: (_item, window) => {
                        if (window instanceof BrowserWindow) {
                            void loadData(window);
                        }
                    },
                },
                { type: "separator" },
                { role: "close" },
            ],
        },
        { role: "editMenu" },
        {
            label: "View",
            submenu: [
                { role: "toggleDevTools" },
                { type: "separator" },
                { role: "togglefullscreen" },
            ],
        },
        { role: "windowMenu" },
    ];

    Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

// Files opened by double-clicking in the Finder or dragging onto the icon.
const openFileQueue: string[] = [];
app.on("open-file", (event, filename) => {
    event.preventDefault();
    if (app.isReady()) {
        void createWindow(filename);
    } else {
        openFileQueue.push(filename);
    }
});

app.on("window-all-closed", () => app.quit());

app.whenReady().then(async () => {
    buildMenu();

    const filenames = [...filenamesFromArgv(process.argv, app.isPackaged), ...openFileQueue];
    for (const filename of filenames) {
        await createWindow(filename);
    }

    // We're usually launched from a terminal, which otherwise keeps the focus.
    // Do this before any dialog, so that it comes up in front.
    app.focus({ steal: true });

    if (!haveWindows()) {
        // Nothing to plot, and an empty window would be useless, so go straight
        // to the Open dialog. That's all the user could have done with it.
        await openFile();

        // They canceled the dialog, so there's nothing left to do. This matches
        // what we do when the last window is closed.
        if (!haveWindows()) {
            app.quit();
        }
    }
});

// Don't let the plot navigate anywhere; it's a local document, not a browser.
app.on("web-contents-created", (_event, contents) => {
    contents.setWindowOpenHandler(({ url }) => {
        void shell.openExternal(url);
        return { action: "deny" };
    });
});
