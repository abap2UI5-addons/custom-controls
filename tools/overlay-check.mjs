// Runs tools/overlay-check.html in a headless Chromium and fails on any FAIL.
//
// The unit tests cover the arithmetic; this covers the part only a layout
// engine can answer - whether the SVG overlay actually sits on the image, and
// whether a click at a point in the picture lands on the region drawn there.
// It found a real one already: the overlay's alignment depends on the image
// being `width: 100%` inside the frame, which the renderer now says out loud.
//
// No npm package involved. Chromium is looked up in the usual places, and when
// there is none the check reports that and exits 0 - a developer without a
// browser should not be blocked, and CI has one.
//
// Run: npm run check:browser
import { existsSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const PAGE = join(ROOT, "tools", "overlay-check.html");

function findChromium() {
  const fromEnv = process.env.CHROMIUM_PATH || process.env.CHROME_PATH;
  if (fromEnv && existsSync(fromEnv)) return fromEnv;

  const fixed = [
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "/usr/bin/google-chrome",
    "/usr/bin/google-chrome-stable",
    "/opt/google/chrome/chrome",
  ];
  for (const path of fixed) if (existsSync(path)) return path;

  // the Playwright browser pool, whose directories carry a build number
  const pool = process.env.PLAYWRIGHT_BROWSERS_PATH || "/opt/pw-browsers";
  if (existsSync(pool)) {
    for (const entry of readdirSync(pool)) {
      const path = join(pool, entry, "chrome-linux", "chrome");
      if (existsSync(path)) return path;
    }
  }
  return null;
}

const chromium = findChromium();
if (!chromium) {
  console.log("overlay-check: no Chromium found, skipping (set CHROMIUM_PATH to run it)");
  process.exit(0);
}

console.log(`overlay-check: ${chromium}`);

const dom = execFileSync(
  chromium,
  [
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    // the page reads the control sources next to it; without this the fetch is
    // blocked as a cross-origin request from file://
    "--allow-file-access-from-files",
    // let the async checks finish before the DOM is dumped
    "--virtual-time-budget=10000",
    "--dump-dom",
    `file://${PAGE}`,
  ],
  { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], maxBuffer: 32 * 1024 * 1024 },
);

const out = /<pre id="out">([\s\S]*?)<\/pre>/.exec(dom)?.[1] ?? "";
const lines = out
  .replace(/&lt;/g, "<")
  .replace(/&gt;/g, ">")
  .replace(/&amp;/g, "&")
  .split("\n")
  .map((line) => line.trim())
  .filter(Boolean);

lines.forEach((line) => console.log(`  ${line}`));

// An empty result means the page threw before it could report anything - that
// is a failure, not a pass with nothing to say.
if (!lines.length) {
  console.error("overlay-check: the page produced no result");
  process.exit(1);
}

const failed = lines.filter((line) => !line.startsWith("PASS"));
if (failed.length) {
  console.error(`overlay-check: ${failed.length} check(s) failed`);
  process.exit(1);
}

console.log(`overlay-check: ${lines.length} checks passed`);
