/* Holos Words mockups: SwiftUI's lineLimit + minimumScaleFactor, emulated.
 *
 *   <b data-fit="0.6" data-lines="1">Українська</b>
 *
 * shrinks the text (size and line height together, as SwiftUI scales a Text)
 * until it fits its box in at most data-lines lines (default 1), never below
 * the minimum scale. If it still does not fit at the minimum, it is truncated
 * with "…", as SwiftUI does.
 *
 * data-maxh="half" also caps the height at half of its cell's free height. That
 * is what a SwiftUI VStack proposes to a SymbolCell's label (the least flexible
 * child goes first and is offered an equal share) before the picture takes the
 * rest — which is why labels shrink in very short cells.
 *
 * It runs once kit.js has loaded the fonts (body[data-ready]); render.cjs waits
 * 150 ms after that before the screenshot.
 */
(function () {
  function px(v) { return parseFloat(v) || 0; }

  function measure(el) {
    const range = document.createRange();
    range.selectNodeContents(el);
    const rects = Array.from(range.getClientRects()).filter(function (r) { return r.width > 0.5 && r.height > 0.5; });
    const tops = [];
    let right = -Infinity;
    rects.forEach(function (r) {
      if (!tops.some(function (t) { return Math.abs(t - r.top) < 3; })) tops.push(r.top);
      right = Math.max(right, r.right);
    });
    const cs = getComputedStyle(el);
    const box = el.getBoundingClientRect();
    const contentRight = box.right - px(cs.paddingRight) - px(cs.borderRightWidth);
    return { lines: tops.length, overflowX: right - contentRight, lineHeight: px(cs.lineHeight) };
  }

  function fit(el) {
    const min = parseFloat(el.dataset.fit) || 1;
    let lines = parseInt(el.dataset.lines || "1", 10);
    const cs = getComputedStyle(el);
    const size = px(cs.fontSize);
    const lh = px(cs.lineHeight) || size * 1.193;
    let maxh = 0;
    if (el.dataset.maxh === "half") {
      const cell = el.parentElement;
      const ccs = getComputedStyle(cell);
      const free = cell.clientHeight - px(ccs.paddingTop) - px(ccs.paddingBottom) - px(ccs.rowGap);
      maxh = free / 2;
    }

    // Measure unclamped and unwrapped as the line limit asks, never wider
    // than the container offers (a centred flex item would otherwise just grow).
    el.style.maxWidth = "100%";
    el.style.display = "block";
    el.style.webkitLineClamp = "none";
    el.style.overflow = "visible";
    el.style.whiteSpace = lines === 1 ? "nowrap" : "normal";
    el.style.overflowWrap = "normal";
    el.style.wordBreak = "normal";
    el.style.textOverflow = "clip";

    for (let s = 1; s >= min - 1e-6; s = Math.round((s - 0.01) * 100) / 100) {
      el.style.fontSize = (size * s) + "px";
      el.style.lineHeight = (lh * s) + "px";
      const m = measure(el);
      const fitsHeight = !maxh || m.lines * m.lineHeight <= maxh + 0.5;
      if (m.lines <= lines && m.overflowX <= 0.5 && fitsHeight) {
        el.dataset.scale = s.toFixed(2);
        el.style.overflow = "hidden";
        return;
      }
    }

    // At the minimum scale and still too big: SwiftUI truncates the tail.
    el.style.fontSize = (size * min) + "px";
    el.style.lineHeight = (lh * min) + "px";
    if (maxh) lines = Math.max(1, Math.min(lines, Math.floor((maxh + 0.5) / (lh * min))));
    el.style.overflow = "hidden";
    if (lines === 1) {
      el.style.whiteSpace = "nowrap";
      el.style.textOverflow = "ellipsis";
    } else {
      el.style.display = "-webkit-box";
      el.style.webkitBoxOrient = "vertical";
      el.style.webkitLineClamp = String(lines);
      el.style.overflowWrap = "anywhere";
    }
    el.dataset.scale = min.toFixed(2) + " truncated";
  }

  function run() {
    document.querySelectorAll("[data-fit]").forEach(fit);
    document.body.dataset.fitted = "1";
  }

  function whenReady() {
    if (document.body.dataset.ready) { run(); return; }
    new MutationObserver(function (_, observer) {
      if (document.body.dataset.ready) { observer.disconnect(); run(); }
    }).observe(document.body, { attributes: true, attributeFilter: ["data-ready"] });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", whenReady);
  } else {
    whenReady();
  }
})();
