#!/usr/bin/env node
/* Renders Holos mockups to PNG at 2× (iPad Retina), next to each HTML file.
 *
 *   node design/kit/render.cjs design/HolosGrid/*.html
 *
 * Each page is sized from <body data-device>, and the shot is taken only once
 * kit.js has marked <body data-ready> (fonts loaded, icons swapped in).
 * Any console warning — such as a missing SF Symbol stand-in — is printed.
 */
const path = require("path");
let playwright;
try {
  playwright = require("playwright");
} catch {
  playwright = require("/opt/node22/lib/node_modules/playwright");
}

const SIZES = { "ipad": [1194, 834], "ipad-portrait": [834, 1194], "iphone": [393, 852] };

(async () => {
  const files = process.argv.slice(2).filter((f) => f.endsWith(".html"));
  if (!files.length) {
    console.error("usage: node design/kit/render.cjs <page.html>...");
    process.exit(1);
  }
  const browser = await playwright.chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1194, height: 834 }, deviceScaleFactor: 2 });
  let failures = 0;
  for (const file of files) {
    const page = await context.newPage();
    const warnings = [];
    page.on("console", (msg) => { if (msg.type() === "warning" || msg.type() === "error") warnings.push(msg.text()); });
    page.on("pageerror", (err) => warnings.push("page error: " + err.message));
    const url = "file://" + path.resolve(file);
    await page.goto(url, { waitUntil: "load" });
    const device = await page.evaluate(() => document.body.dataset.device || "ipad");
    const [w, h] = SIZES[device] || SIZES.ipad;
    await page.setViewportSize({ width: w, height: h });
    try {
      await page.waitForSelector("body[data-ready]", { timeout: 10000 });
    } catch {
      warnings.push("kit.js never marked the page ready (is kit.js included?)");
    }
    await page.waitForTimeout(150);
    const out = file.replace(/\.html$/, ".png");
    await page.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h } });
    console.log((warnings.length ? "WARN " : "ok   ") + out + (warnings.length ? "\n     " + warnings.join("\n     ") : ""));
    if (warnings.length) failures++;
    await page.close();
  }
  await browser.close();
  process.exit(failures ? 2 : 0);
})();
