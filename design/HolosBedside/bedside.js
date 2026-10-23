/* Holos Bedside mockups — the parts of the SwiftUI layout that HTML cannot
 * express in CSS alone. Include after ../kit/kit.js.
 *
 *  <i data-face="2" data-size="30"></i>   PainFace(level:) — AnswerCell.swift
 *  <div data-bodymap data-lit="head">      BodyMapFigure — BodyMap.swift
 *  <div data-dash="28,2,10 8,rgba(…)">     strokeBorder(style: StrokeStyle(dash:))
 *  <b data-fit="2" data-min="0.45">        .lineLimit(2).minimumScaleFactor(0.45)
 *  <div class="chat" data-scroll="bottom"> ChatView's scrollTo(last, anchor: .bottom)
 *  <div class="chat" data-scroll="center:id">  scrollTo(replaying, anchor: .center)
 */
(function () {
  const INK = "#12141A";

  /* PainFace: a circle, a ring of 4 % (at least 1.5 pt), two capsule eyes and
     one quadratic mouth of 6 % (at least 2 pt). Drawn in a 100-unit box. */
  const FACE = {
    0: { fill: "#C7EDC2", curve: 0.9 },   // WordKind.action.tint
    1: { fill: "#FFED9E", curve: 0.15 },  // WordKind.people.tint
    2: { fill: "#FFD9AD", curve: -0.55 }, // WordKind.thing.tint
    3: { fill: "#FFC2BD", curve: -1 },    // WordKind.urgent.tint
  };
  function faceSVG(level, sizePt) {
    const f = FACE[level] || FACE[3];
    const size = sizePt || 120;
    const ring = (Math.max(size * 0.04, 1.5) / size) * 100;
    const mouth = (Math.max(size * 0.06, 2) / size) * 100;
    const eyeH = level >= 3 ? 4 : 12;
    const eyeY = 40 - eyeH / 2;
    const cy = 68 + 20 * f.curve;
    return '<svg class="face" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">' +
      '<circle cx="50" cy="50" r="50" fill="' + f.fill + '"/>' +
      '<circle cx="50" cy="50" r="' + (50 - ring / 2) + '" fill="none" stroke="' + INK + '" stroke-width="' + ring + '"/>' +
      '<rect x="31" y="' + eyeY + '" width="9" height="' + eyeH + '" rx="' + Math.min(4.5, eyeH / 2) + '" fill="' + INK + '"/>' +
      '<rect x="60" y="' + eyeY + '" width="9" height="' + eyeH + '" rx="' + Math.min(4.5, eyeH / 2) + '" fill="' + INK + '"/>' +
      '<path d="M30 68 Q50 ' + cy + ' 70 68" fill="none" stroke="' + INK + '" stroke-width="' + mouth + '" stroke-linecap="round"/>' +
      "</svg>";
  }
  function drawFaces() {
    document.querySelectorAll("i[data-face]").forEach(function (el) {
      const wrap = document.createElement("span");
      wrap.className = "facewrap " + (el.className || "");
      wrap.innerHTML = faceSVG(+el.dataset.face, el.dataset.size ? +el.dataset.size : 0);
      if (el.getAttribute("style")) wrap.setAttribute("style", el.getAttribute("style"));
      el.replaceWith(wrap);
    });
  }

  /* BodyMapFigure: unit rects of a width × 1.8 width figure, each a
     continuous rounded rect (radius 0.38 of its short side, 0.5 for the
     head) with a strokeBorder: rust 55 % at 2 pt, the guide terracotta at
     4 pt, the lit region yellow with a 5 pt black keyline. The back is
     dashed [6, 4] and filled with the chat colour. */
  const PARTS = [
    ["back", 0.23, 0.15, 0.54, 0.36, true],
    ["head", 0.37, 0.0, 0.26, 0.14],
    ["chest", 0.28, 0.165, 0.44, 0.16],
    ["stomach", 0.28, 0.335, 0.44, 0.16],
    ["arm", 0.07, 0.17, 0.13, 0.34],
    ["arm", 0.80, 0.17, 0.13, 0.34],
    ["leg", 0.29, 0.52, 0.19, 0.47],
    ["leg", 0.52, 0.52, 0.19, 0.47],
  ];
  function drawBodyMaps() {
    document.querySelectorAll("[data-bodymap]").forEach(function (box) {
      const lit = box.dataset.lit || "";
      const guide = box.dataset.guide || "";
      const w = Math.min(box.clientWidth, box.clientHeight / 1.8);
      const h = w * 1.8;
      let s = '<svg width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + " " + h + '" xmlns="http://www.w3.org/2000/svg">';
      PARTS.forEach(function (p) {
        const region = p[0];
        const x = p[1] * w, y = p[2] * h, pw = p[3] * w, ph = p[4] * h, dashed = !!p[5];
        const isLit = lit === region;
        const isGuide = guide === region && !isLit;
        const r = Math.min(pw, ph) * (region === "head" ? 0.5 : 0.38);
        const fill = isLit ? "#FFCC00" : (region === "back" ? "#F7EBD9" : "#FFDBC2");
        const lw = isLit ? 5 : (isGuide ? 4 : 2);
        const stroke = isLit ? "#000" : (isGuide ? "#B85438" : "rgba(143, 56, 33, 0.55)");
        const dash = dashed && !isLit ? ' stroke-dasharray="6 4"' : "";
        s += '<rect x="' + x + '" y="' + y + '" width="' + pw + '" height="' + ph + '" rx="' + r + '" fill="' + fill + '"/>';
        s += '<rect x="' + (x + lw / 2) + '" y="' + (y + lw / 2) + '" width="' + (pw - lw) + '" height="' + (ph - lw) +
          '" rx="' + Math.max(0, r - lw / 2) + '" fill="none" stroke="' + stroke + '" stroke-width="' + lw + '"' + dash + "/>";
      });
      box.innerHTML = s + "</svg>";
    });
  }

  /* strokeBorder with a dash: "radius,lineWidth,dash pattern,colour". */
  function drawDashes() {
    document.querySelectorAll("[data-dash]").forEach(function (el) {
      const parts = el.dataset.dash.split(",");
      const r = +parts[0], lw = +parts[1], dash = parts[2], color = parts.slice(3).join(",");
      const w = el.offsetWidth, h = el.offsetHeight;
      const svg = '<svg class="dash" viewBox="0 0 ' + w + " " + h + '" xmlns="http://www.w3.org/2000/svg"><rect x="' + lw / 2 + '" y="' + lw / 2 +
        '" width="' + (w - lw) + '" height="' + (h - lw) + '" rx="' + (r - lw / 2) + '" fill="none" stroke="' + color +
        '" stroke-width="' + lw + '" stroke-dasharray="' + dash + '"/></svg>';
      el.insertAdjacentHTML("beforeend", svg);
    });
  }

  /* lineLimit + minimumScaleFactor: shrink in 1 % steps until the text fits
     its width (no word overflowing), its line limit and, for a word in a
     vertical AnswerCell, the half of the cell's height a VStack offers it
     before the flexible picture takes the rest. */
  function fitText() {
    document.querySelectorAll("[data-fit]").forEach(function (el) {
      const lines = +el.dataset.fit;
      const min = el.dataset.min ? +el.dataset.min : 0.45;
      const cs = getComputedStyle(el);
      const base = el.dataset.base ? +el.dataset.base : parseFloat(cs.fontSize);
      const ratio = el.dataset.ratio ? +el.dataset.ratio : parseFloat(cs.lineHeight) / parseFloat(cs.fontSize);
      el.dataset.base = base;
      el.dataset.ratio = ratio;
      let maxH = Infinity;
      if (el.dataset.maxh === "half") {
        const p = el.parentElement, ps = getComputedStyle(p);
        const inner = p.clientHeight - parseFloat(ps.paddingTop) - parseFloat(ps.paddingBottom);
        maxH = (inner - parseFloat(ps.rowGap || ps.gap || 0)) / 2;
      }
      let scale = 1;
      for (; scale >= min - 1e-9; scale -= 0.01) {
        const fs = base * scale, lh = fs * ratio;
        el.style.fontSize = fs + "px";
        el.style.lineHeight = lh + "px";
        const h = el.offsetHeight;  // whole line boxes, not the glyphs' ink
        if (el.scrollWidth <= el.clientWidth + 0.5 && Math.round(h / lh) <= lines && h <= maxH + 0.5) break;
      }
      if (scale < min) {
        const fs = base * min;
        el.style.fontSize = fs + "px";
        el.style.lineHeight = fs * ratio + "px";
        el.style.display = "-webkit-box";
        el.style.webkitBoxOrient = "vertical";
        el.style.webkitLineClamp = String(lines);
        el.style.overflow = "hidden";
        console.info("fit: clamped", el.textContent);
      }
      el.dataset.scale = scale.toFixed(2);
    });
  }

  /* ScrollViewReader.scrollTo(id, anchor:), clamped like a real scroll view. */
  function scrollChats() {
    document.querySelectorAll(".chat[data-scroll]").forEach(function (chat) {
      const how = chat.dataset.scroll;
      const max = Math.max(0, chat.scrollHeight - chat.clientHeight);
      let top = 0;
      if (how === "bottom") {
        const items = chat.querySelectorAll(".lines > *");
        const last = items[items.length - 1];
        if (last) top = last.offsetTop + last.offsetHeight - chat.clientHeight;
      } else if (how.indexOf("center:") === 0) {
        const target = document.getElementById(how.slice(7));
        if (target) top = target.offsetTop + target.offsetHeight / 2 - chat.clientHeight / 2;
      }
      chat.scrollTop = Math.min(max, Math.max(0, top));
    });
  }

  function layoutPass() {
    fitText();
    drawBodyMaps();
    drawDashes();
    scrollChats();
  }

  function start() {
    drawFaces();
    const faces = ["400 20px Nunito", "600 20px Nunito", "700 20px Nunito", "800 20px Nunito", "900 20px Nunito"];
    Promise.all(faces.map(function (f) { return document.fonts.load(f, "Aa Дд Її"); }))
      .then(function () { return document.fonts.ready; })
      .then(layoutPass);
  }

  window.bedside = { faceSVG: faceSVG };
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
