/* Holos Room mockups — the board drawn over the room art.
 *
 * A port of Board/RoomCanvas.swift and its layers, so every screen lays the
 * room out the way the code does:
 *  - the 10:7 room aspect-fitted into its slot and scaled from room space
 *    (RoomCanvas: scale = width / 1000);
 *  - the spotlight veil with its rounded hole, the hotspot frame grown by
 *    8 room points and corner radius 26·scale + 6 (RoomCanvas.veil, SpotlightVeil);
 *  - the lit hotspot's scan ring, or the open hotspot's 4-pt outline, and the
 *    name pills (HotspotLayer);
 *  - the speech bubbles hung from their speaker, slid sideways to stay in the
 *    room, below the speaker near the top edge (RoomCanvas.placed, SpeechBubble);
 *  - the ring of phrases and its dotted threads, positions from
 *    RingLayout.positions and RingLayout.cellSize unchanged (PhraseRing.swift);
 *  - the guide marker on the next thing to press (GuideMarker), and on a phone
 *    the ring as a panel of cells (RingSheet).
 *
 * It runs once kit.js has loaded the fonts (body[data-ready]): the ring cells
 * fit their labels the way SymbolCell's minimumScaleFactor does, which needs
 * the real font.
 */
(function () {
  "use strict";

  const SPACE = { w: 1000, h: 700 };

  // Vocabulary+Ward.swift and Vocabulary+Home.swift: hotspot frames and pill
  // points in room space; RoomPlace.speakerAt.
  const PLACES = {
    ward: {
      speakerAt: [236, 380],
      hotspots: [
        { id: "ward.window", en: "Window", uk: "Вікно", frame: [20, 44, 300, 284], label: [170, 292] },
        { id: "ward.bed", en: "Bed", uk: "Ліжко", frame: [140, 330, 450, 270], label: [430, 360] },
        { id: "ward.body", en: "My body", uk: "Моє тіло", frame: [345, 66, 160, 212], label: [425, 254] },
        { id: "ward.phone", en: "Phone", uk: "Телефон", frame: [548, 132, 172, 142], label: [634, 262] },
        { id: "ward.table", en: "Bedside table", uk: "Тумбочка", frame: [598, 306, 192, 294], label: [690, 566] },
        { id: "ward.nurse", en: "Nurse", uk: "Медсестра", frame: [800, 80, 186, 452], label: [890, 510] },
      ],
    },
    home: {
      speakerAt: [506, 296],
      hotspots: [
        { id: "home.fridge", en: "Fridge", uk: "Холодильник", frame: [20, 160, 170, 440], label: [105, 196] },
        { id: "home.kettle", en: "Kettle", uk: "Чайник", frame: [190, 318, 178, 280], label: [278, 560] },
        { id: "home.photo", en: "Family photo", uk: "Сімейне фото", frame: [402, 72, 206, 166], label: [505, 226] },
        { id: "home.sofa", en: "Sofa", uk: "Диван", frame: [398, 360, 324, 240], label: [612, 578] },
        { id: "home.tv", en: "TV", uk: "Телевізор", frame: [606, 104, 220, 150], label: [716, 242] },
        { id: "home.door", en: "Door", uk: "Двері", frame: [836, 98, 158, 434], label: [915, 508] },
      ],
    },
  };
  const NURSE_BUBBLE_AT = [852, 176]; // "Beside the nurse's face, in the doorway."
  const GO_BACK = { en: "Go back", uk: "Назад" }; // CoreCopy.goBack

  // ---------- RingLayout (PhraseRing.swift), unchanged ----------

  function ringPositions(count, center, radius, cell, bounds) {
    if (count <= 0) return [];
    const midX = bounds.x + bounds.w / 2, midY = bounds.y + bounds.h / 2;
    if (!(bounds.w > cell.w + 12 && bounds.h > cell.h + 12)) {
      return Array.from({ length: count }, () => ({ x: midX, y: midY }));
    }
    const towardsMiddle = Math.atan2(midY - center.y, midX - center.x);
    const span = Math.min(Math.PI * 1.3, (count - 1) * 0.9);
    const step = count > 1 ? span / (count - 1) : 0;
    const start = towardsMiddle - span / 2;
    const inset = {
      minX: bounds.x + cell.w / 2 + 6, maxX: bounds.x + bounds.w - cell.w / 2 - 6,
      minY: bounds.y + cell.h / 2 + 6, maxY: bounds.y + bounds.h - cell.h / 2 - 6,
    };
    const clamped = (p) => ({
      x: Math.min(Math.max(p.x, inset.minX), inset.maxX),
      y: Math.min(Math.max(p.y, inset.minY), inset.maxY),
    });
    let points = [];
    for (let i = 0; i < count; i++) {
      const angle = start + step * i;
      points.push(clamped({ x: center.x + radius * Math.cos(angle), y: center.y + radius * Math.sin(angle) }));
    }
    const gap = 10;
    for (let round = 0; round < 24; round++) {
      let moved = false;
      for (let a = 0; a < points.length; a++) {
        for (let b = a + 1; b < points.length; b++) {
          const dx = points[b].x - points[a].x, dy = points[b].y - points[a].y;
          const overlapX = cell.w + gap - Math.abs(dx), overlapY = cell.h + gap - Math.abs(dy);
          if (!(overlapX > 0 && overlapY > 0)) continue;
          moved = true;
          if (overlapX < overlapY) {
            const push = overlapX / 2 * (dx >= 0 ? 1 : -1);
            points[a].x -= push; points[b].x += push;
          } else {
            const push = overlapY / 2 * (dy >= 0 ? 1 : -1);
            points[a].y -= push; points[b].y += push;
          }
        }
      }
      points = points.map(clamped);
      if (!moved) break;
    }
    return points;
  }

  function cellSize(scale) {
    const w = Math.min(Math.max(150 * scale, 108), 172);
    return { w: w, h: w * 0.84 };
  }

  // ---------- helpers ----------

  function el(tag, className, parent) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (parent) parent.appendChild(node);
    return node;
  }
  function icon(name) { return window.kit.icon(name); }
  function px(node, styles) { for (const k in styles) node.style[k] = typeof styles[k] === "number" ? styles[k] + "px" : styles[k]; }
  function hotspot(place, id) { return place.hotspots.find((h) => h.id === id); }
  function scaled(frame, s) { return { x: frame[0] * s, y: frame[1] * s, w: frame[2] * s, h: frame[3] * s }; }
  function roundedRectPath(r, radius) {
    const x = r.x, y = r.y, w = r.w, h = r.h, k = radius;
    return "M" + (x + k) + " " + y + "H" + (x + w - k) + "A" + k + " " + k + " 0 0 1 " + (x + w) + " " + (y + k) +
      "V" + (y + h - k) + "A" + k + " " + k + " 0 0 1 " + (x + w - k) + " " + (y + h) +
      "H" + (x + k) + "A" + k + " " + k + " 0 0 1 " + x + " " + (y + h - k) +
      "V" + (y + k) + "A" + k + " " + k + " 0 0 1 " + (x + k) + " " + y + "Z";
  }
  // RoomCanvas's ZStack order, back to front: art, veil, hotspots and pills,
  // bubbles, ring threads, ring cells. Each layer is its own stacking context,
  // so the kit's raised .lit ring stays inside its layer.
  const Z = { veil: 1, hotspots: 2, bubbles: 3, threads: 4, ring: 5 };
  function svgLayer(w, h, parent, z) {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("class", "layer");
    svg.style.zIndex = z;
    svg.setAttribute("width", w); svg.setAttribute("height", h);
    svg.setAttribute("viewBox", "0 0 " + w + " " + h);
    parent.appendChild(svg);
    return svg;
  }
  function svgNode(tag, attrs, parent) {
    const node = document.createElementNS("http://www.w3.org/2000/svg", tag);
    for (const k in attrs) node.setAttribute(k, attrs[k]);
    parent.appendChild(node);
    return node;
  }

  // GuideMarker: its top edge on `top`, centred on x.
  function guideMarker(parent, x, top) {
    const g = el("div", "guide", parent);
    g.appendChild(icon("arrow.down"));
    px(g, { left: x - 17, top: top });
    return g;
  }

  // RingCell: a SymbolCell (or BackCell), its shadow, the "opens more" badge.
  function ringCell(item, cfg) {
    const wrap = el("div", "rcell");
    const lang = cfg.lang || "en";
    const cell = el("div", item.back ? "cell backcell" : "cell k-" + item.kind, wrap);
    cell.appendChild(icon(item.back ? "arrow.uturn.backward" : item.symbol));
    el("b", "", cell).textContent = item.back ? GO_BACK[lang] : item.label;
    if (!item.back && cfg.ringLit === item.id) cell.classList.add("lit");
    if (item.back && cfg.ringLit === item.id) cell.classList.add("lit");
    if (item.more) el("span", "morebadge", wrap).appendChild(icon("chevron.right"));
    return wrap;
  }

  // SymbolCell's label: .title3 rounded bold, lineLimit(2), minimumScaleFactor(0.55).
  // The VStack offers the label half of the height left after the 6-pt spacing
  // (it is the less flexible child); the symbol takes the rest.
  function fitLabels(scope) {
    scope.querySelectorAll(".rcell > .cell:not(.backcell)").forEach(function (cell) {
      const b = cell.querySelector("b");
      const width = cell.clientWidth - 20;
      const share = (cell.clientHeight - 20 - 6) / 2;
      let size = 20;
      for (; size >= 11; size -= 0.25) {
        const line = size * 1.193;
        b.style.fontSize = size + "px";
        b.style.lineHeight = line + "px";
        b.style.display = "block";
        b.style.webkitLineClamp = "unset";
        b.style.width = width + "px";
        const lines = Math.round(b.scrollHeight / line);
        const fits = lines <= 2 && b.scrollHeight <= share + 0.5 && b.scrollWidth <= width + 0.5;
        if (fits) break;
      }
      b.style.display = ""; b.style.webkitLineClamp = ""; b.style.width = "";
      if (size < 11) b.style.fontSize = "11px";
    });
  }

  // ---------- the canvas ----------

  function build(cfg) {
    const place = PLACES[cfg.place];
    const lang = cfg.lang || "en";
    const narrow = document.body.classList.contains("narrow");
    const room = document.getElementById("room");
    const sheet = document.getElementById("ringsheet");

    // RingSheet first, on a phone: it takes the chips' place under the room,
    // so it decides how much height the room's slot has.
    if (narrow && sheet && cfg.ring) {
      const h3 = el("h3", "", sheet);
      h3.textContent = cfg.sheetTitle || hotspot(place, cfg.open)[lang];
      const grid = el("div", "grid", sheet);
      cfg.ring.forEach(function (item) {
        const slot = el("div", "slotcell", grid);
        slot.appendChild(ringCell(item, cfg));
        if (cfg.guide === item.id) guideMarker(slot, slot.clientWidth / 2 || 0, -22).dataset.center = "1";
      });
    }

    // RoomCanvas: aspectRatio(10/7, .fit), centred in what the VStack leaves it.
    const box = room.parentElement.getBoundingClientRect();
    const w = Math.min(box.width, box.height * SPACE.w / SPACE.h);
    const h = w * SPACE.h / SPACE.w;
    const s = w / SPACE.w;
    px(room, { width: w, height: h });
    room.dataset.scale = s.toFixed(4);

    if (sheet) {
      // Guide markers in the sheet are centred once the grid has its widths.
      sheet.querySelectorAll(".guide[data-center]").forEach(function (g) {
        px(g, { left: g.parentElement.clientWidth / 2 - 17 });
      });
    }

    // The spotlight veil: black at `dim`, with an even-odd hole on the lit object.
    const spot = cfg.spotlight || { id: null, dim: 0 };
    if (spot.dim > 0) {
      const veil = svgLayer(w, h, room, Z.veil);
      let d = "M0 0H" + w + "V" + h + "H0Z";
      const lit = spot.id && hotspot(place, spot.id);
      if (lit) {
        const r = scaled(lit.frame, s), pad = 8 * s;
        const hole = { x: r.x - pad, y: r.y - pad, w: r.w + 2 * pad, h: r.h + 2 * pad };
        d += roundedRectPath(hole, Math.min(26 * s + 6, hole.w / 2, hole.h / 2));
      }
      svgNode("path", { d: d, fill: "#000", "fill-opacity": spot.dim, "fill-rule": "evenodd" }, veil);
    }

    // HotspotLayer: the buttons' scan ring / open outline, then the pills.
    const hs = el("div", "layer", room);
    hs.style.zIndex = Z.hotspots;
    place.hotspots.forEach(function (h) {
      const isLit = spot.id === h.id, isOpen = cfg.open === h.id;
      if (!isLit && !isOpen) return;
      const r = scaled(h.frame, s);
      const node = el("div", isOpen ? "hs open" : "hs lit", hs);
      px(node, { left: r.x, top: r.y, width: r.w, height: r.h });
    });
    if (cfg.pills !== false) {
      const pillH = narrow ? 14.32 + 6 : 17.9 + 10;
      place.hotspots.forEach(function (h) {
        const isLit = spot.id === h.id;
        const pill = el("span", "pill" + (isLit ? " on" : "") + (spot.dim > 0 && !isLit ? " faded" : ""), hs);
        pill.textContent = h[lang];
        if (lang === "uk") pill.lang = "uk";
        px(pill, { left: h.label[0] * s, top: h.label[1] * s });
        if (cfg.guide === h.id) guideMarker(hs, h.label[0] * s, h.label[1] * s - pillH / 2 - 40);
      });
    }

    // Speech bubbles.
    const bubbleWidth = Math.min(300, Math.max(150, w * 0.44));
    const talk = el("div", "layer", room);
    talk.style.zIndex = Z.bubbles;
    function bubble(text, voice, at, width) {
      const anchor = { x: at[0] * s, y: at[1] * s };
      const half = width / 2, margin = 8;
      const lowest = half + margin, highest = Math.max(w - half - margin, lowest);
      const boxCenter = Math.min(Math.max(anchor.x, lowest), highest);
      const tailUp = anchor.y < 96;
      const b = el("div", "bubble " + voice + (tailUp ? " up" : ""), talk);
      const boxNode = el("div", "box", b);
      if (voice === "person") boxNode.appendChild(icon("speaker.wave.2.fill"));
      const words = el("span", "", boxNode);
      words.textContent = text;
      if (cfg.lang === "uk") words.lang = "uk";
      px(boxNode, { width: width, transform: "translateX(" + (boxCenter - anchor.x) + "px)" });
      el("div", "tail", b);
      px(b, { left: anchor.x, top: anchor.y + (tailUp ? -0.5 : 0.5) });
    }
    if (cfg.nurse && cfg.place === "ward") bubble(cfg.nurse, "other", NURSE_BUBBLE_AT, bubbleWidth);
    if (cfg.spoken) bubble(cfg.spoken, "person", place.speakerAt, bubbleWidth);
    else if (cfg.silence && cfg.place === "ward") bubble("…", "person", place.speakerAt, 90);

    // RingLayer (wide screens): threads, then the cells.
    if (!narrow && cfg.open && cfg.ring) {
      const open = hotspot(place, cfg.open);
      const cell = cellSize(s);
      const c = { x: (open.frame[0] + open.frame[2] / 2) * s, y: (open.frame[1] + open.frame[3] / 2) * s };
      const points = ringPositions(cfg.ring.length, c, 228 * s, cell, { x: 0, y: 0, w: w, h: h });
      const threads = svgLayer(w, h, room, Z.threads);
      let d = "";
      points.forEach(function (p) { d += "M" + c.x + " " + c.y + "L" + p.x + " " + p.y; });
      svgNode("path", { d: d, fill: "none", stroke: "#FFCC00", "stroke-opacity": 0.6, "stroke-width": 3, "stroke-linecap": "round", "stroke-dasharray": "2 9" }, threads);
      const layer = el("div", "layer", room);
      layer.style.zIndex = Z.ring;
      cfg.ring.forEach(function (item, i) {
        const p = points[i];
        const node = ringCell(item, cfg);
        px(node, { left: p.x - cell.w / 2, top: p.y - cell.h / 2, width: cell.w, height: cell.h });
        layer.appendChild(node);
        if (cfg.guide === item.id) guideMarker(layer, p.x, p.y - cell.h / 2 - 22);
      });
      room.dataset.ring = points.map((p) => p.x.toFixed(1) + "," + p.y.toFixed(1)).join(" ");
    }

    fitLabels(document);
    console.log("room scale " + room.dataset.scale + " size " + w.toFixed(1) + "×" + h.toFixed(1));
  }

  // Wait for kit.js to mark the page ready (fonts loaded, icons swapped).
  window.Room = {
    render: function (cfg) {
      function go() { build(cfg); }
      if (document.body.dataset.ready) { go(); return; }
      const watch = new MutationObserver(function () {
        if (document.body.dataset.ready) { watch.disconnect(); go(); }
      });
      watch.observe(document.body, { attributes: true, attributeFilter: ["data-ready"] });
    },
    ringPositions: ringPositions,
    cellSize: cellSize,
  };
})();
