/* Holos Compass mockups — the parts of the board whose sizes the Swift code
 * computes, ported from the source so each screen is laid out the way the
 * code lays it out:
 *
 *   DialMetrics            Board/CompassDial.swift (petal, hub and chip sizes)
 *   petal()                Board/PetalView.swift (wide/tall layout, symbol side,
 *                          label size, arrow badge, hold ring, "Next" tag)
 *   hub()                  Board/HubView.swift (needle, trail, draft, message, Speak)
 *   chips()                Board/HubChip.swift and the chip rules in CompassDial
 *   needleSVG()            Board/NeedleDial.swift (Needle and DialTicks shapes)
 *   LEVELS                 Vocabulary/Vocabulary.swift (the levels these screens show)
 *
 * Text with .lineLimit(n).minimumScaleFactor(m) is fitted by fitText(), and
 * SF Symbols drawn with .resizable().scaledToFit() are cropped to their bounds
 * so they fill their frame the way a symbol image does. Everything runs once
 * the kit's fonts have loaded, so every measurement uses the real faces.
 */
(function () {
  "use strict";

  const LH = 1.193;                       // SF line height ÷ point size
  const DIRS = ["north", "east", "south", "west"];
  const DEG = { north: 0, east: 90, south: 180, west: 270 };          // Direction.degrees
  const ARROW = { north: "arrow.up", east: "arrow.right", south: "arrow.down", west: "arrow.left" };

  // CoreCopy and Copy.Board strings the board draws: [English, Ukrainian].
  const T = {
    goBack: ["Go back", "Назад"],
    backToStart: ["Back to start", "На початок"],
    clear: ["Clear", "Очистити"],
    clearConfirm: ["Yes, clear all", "Так, очистити все"],
    clearCancel: ["No, keep it", "Ні, залишити"],
    messageEmpty: ["Your message appears here", "Тут з’явиться ваше повідомлення"],
    speak: ["Speak", "Сказати"],
    speaking: ["Speaking…", "Звучить…"],
    paused: ["Resting. Press to start again.", "Пауза. Натисніть, щоб почати знову."],
    next: ["Next", "Сюди"],
  };
  const NATIVE = { en: "English", uk: "Українська" };                  // Language.nativeName

  // Vocabulary.swift — label, symbol, WordKind for each petal.
  const c = (en, uk, symbol, kind) => ({ label: [en, uk], symbol, kind });
  const LEVELS = {
    home: { draft: ["Four choices. Pick one.", "Чотири варіанти. Оберіть один."], crumb: ["Start", "Початок"],
      north: c("Yes", "Так", "hand.thumbsup.fill", "action"),
      east: c("No", "Ні", "hand.thumbsdown.fill", "urgent"),
      south: c("I need…", "Мені потрібно…", "hand.raised.fill", "thing"),
      west: c("I feel…", "Я почуваюся…", "heart.fill", "describing") },
    need: { draft: ["I need…", "Що мені потрібно:"], crumb: ["I need", "Мені потрібно"],
      north: c("Water", "Вода", "drop.fill", "thing"),
      east: c("Medicine", "Ліки", "pills.fill", "thing"),
      south: c("Toilet", "Туалет", "toilet.fill", "thing"),
      west: c("More…", "Ще…", "square.grid.2x2.fill", "control") },
    feel: { draft: ["I feel…", "Як я почуваюся:"], crumb: ["I feel", "Я почуваюся"],
      north: c("Pain…", "Біль…", "bandage.fill", "urgent"),
      east: c("Tired", "Втомився", "moon.zzz.fill", "describing"),
      south: c("Scared", "Страшно", "face.dashed", "describing"),
      west: c("More…", "Ще…", "square.grid.2x2.fill", "control") },
    pain: { draft: ["It hurts…", "Де болить:"], crumb: ["Pain", "Біль"],
      north: c("Head", "Голова", "brain.head.profile", "thing"),
      east: c("Chest", "Груди", "lungs.fill", "thing"),
      south: c("Stomach", "Живіт", "figure.stand", "thing"),
      west: c("Leg", "Нога", "shoeprints.fill", "thing") },
    "pain.head": { draft: ["My head hurts…", "Болить голова…"], crumb: ["Head", "Голова"],
      north: c("A little", "Трохи", "2.circle.fill", "describing"),
      east: c("Medium", "Помірно", "5.circle.fill", "describing"),
      south: c("A lot", "Дуже", "8.circle.fill", "urgent"),
      west: c("Unbearable", "Нестерпно", "10.circle.fill", "urgent") },
  };

  const C = (window.Compass = { LEVELS, T });
  const px = (v) => v + "px";
  const L = (pair, lang) => pair[lang === "uk" ? 1 : 0];
  function el(tag, cls, parent) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (parent) parent.appendChild(e);
    return e;
  }
  /** Notes for the screen review: every text that had to shrink or truncate. */
  const log = (window.__compassLog = []);

  // ---------------------------------------------------------------- text

  function lineBoxes(node) {
    const range = document.createRange();
    range.selectNodeContents(node);
    const lines = [];
    for (const r of range.getClientRects()) {
      if (!r.width && !r.height) continue;
      const mid = (r.top + r.bottom) / 2;
      let line = lines.find((l) => Math.abs(l.mid - mid) < 2);
      if (!line) lines.push({ mid, left: r.left, right: r.right });
      else { line.left = Math.min(line.left, r.left); line.right = Math.max(line.right, r.right); }
    }
    return lines;
  }

  /**
   * A SwiftUI Text with .lineLimit(lines).minimumScaleFactor(minScale), offered
   * width × height. It keeps its size if it fits; otherwise it takes the largest
   * size, down to minScale × size, at which no word has to be split and it fits
   * in `lines` lines and the height. (With a minimum scale factor set, Apple's
   * text engine shrinks a word that cannot fit rather than breaking it.) At the
   * minimum it truncates. The box then hugs its widest line, as a Text does.
   */
  C.fitText = function (node, size, o) {
    const maxLines = o.lines || 99, minScale = o.minScale || 1;
    const width = o.width, height = o.height == null ? 1e6 : o.height;
    const s = node.style;
    s.display = "block"; s.width = px(width); s.flex = "none";
    s.whiteSpace = maxLines === 1 ? "nowrap" : "normal";
    s.overflowWrap = "normal"; s.wordBreak = "normal";
    const measure = (f) => {
      s.fontSize = px(f); s.lineHeight = px(f * LH);
      const lines = lineBoxes(node);
      const widest = Math.max(0, ...lines.map((l) => l.right - l.left));
      return { lines: lines.length, widest, ok: widest <= width + 0.5 && lines.length <= maxLines && lines.length * f * LH <= height + 0.5 };
    };
    let f = size, m = measure(size);
    if (!m.ok) {
      let lo = size * minScale, hi = size;
      if (!measure(lo).ok) {
        f = lo;
      } else {
        for (let i = 0; i < 22; i++) {
          const mid = (lo + hi) / 2;
          if (measure(mid).ok) lo = mid; else hi = mid;
        }
        f = lo;
      }
      m = measure(f);
    }
    const text = node.textContent;
    if (!m.ok) {
      // Even the minimum scale does not fit: SwiftUI truncates with "…".
      s.overflow = "hidden";
      if (maxLines === 1) { s.textOverflow = "ellipsis"; }
      else { s.display = "-webkit-box"; s.webkitBoxOrient = "vertical"; s.webkitLineClamp = String(Math.max(1, Math.min(maxLines, Math.floor((height + 0.5) / (f * LH))))); s.overflowWrap = "anywhere"; }
      node.dataset.fit = "truncated";
      log.push(`TRUNCATED "${text}" at ${f.toFixed(1)}pt (base ${size.toFixed(1)}, width ${width.toFixed(1)})`);
    } else if (f < size - 0.01) {
      log.push(`shrunk "${text}" ${size.toFixed(1)} → ${f.toFixed(1)}pt (×${(f / size).toFixed(2)}), ${m.lines} line(s), width ${width.toFixed(1)}`);
    }
    node.dataset.size = f.toFixed(2);
    if (o.hug !== false && m.ok) s.width = px(Math.min(width, m.widest + 0.6));
    return f;
  };

  // ---------------------------------------------------------------- symbols

  let uid = 0;
  /** Image(systemName:).resizable().scaledToFit() in a side × side frame. */
  function symbol(name, side, hierarchical) {
    const span = window.kit.icon(name);
    span.style.width = px(side);
    span.style.height = px(side);
    span.style.verticalAlign = "top";
    if (hierarchical && /^\d+\.circle\.fill$/.test(name)) hierarchize(span);
    span.dataset.crop = "1";
    return span;
  }

  /** .symbolRenderingMode(.hierarchical): a numbered circle draws its disc as
   *  the secondary layer (half opacity) and the numeral at full strength. The
   *  kit's stand-ins are monochrome, so the numeral is cut back in here. */
  function hierarchize(span) {
    const svg = span.querySelector("svg");
    if (!svg) return;
    const path = svg.querySelector("path");
    const text = svg.querySelector("text");
    if (!path) return;
    path.setAttribute("opacity", "0.5");
    if (text) { text.setAttribute("fill", "currentColor"); return; }
    const id = "numeral" + ++uid;
    svg.insertAdjacentHTML("beforeend",
      `<mask id="${id}" maskUnits="userSpaceOnUse" x="0" y="0" width="256" height="256">` +
      `<circle cx="128" cy="128" r="104" fill="#fff"/><path d="${path.getAttribute("d")}" fill="#000"/></mask>` +
      `<circle cx="128" cy="128" r="104" mask="url(#${id})"/>`);
  }

  /** Crops each resizable symbol's viewBox to its drawing, once laid out. */
  function cropSymbols(root) {
    root.querySelectorAll("[data-crop] > svg").forEach((svg) => {
      const b = svg.getBBox();
      if (b.width > 0 && b.height > 0) svg.setAttribute("viewBox", [b.x, b.y, b.width, b.height].join(" "));
    });
  }
  C.cropSymbols = cropSymbols;

  // ---------------------------------------------------------------- drawn parts

  /** NeedleDial at `size` pt, the needle turned `deg` clockwise from up. */
  C.needleSVG = function (size, deg, dim) {
    const k = size / 2, r = size / 2, w = r * 0.16;
    const f = (v) => v.toFixed(2);
    const ticks = DIRS.map((d) => {
      const a = (DEG[d] * Math.PI) / 180, dx = Math.sin(a), dy = -Math.cos(a);
      return `<line x1="${f(k + dx * r * 0.8)}" y1="${f(k + dy * r * 0.8)}" x2="${f(k + dx * r * 0.92)}" y2="${f(k + dy * r * 0.92)}"/>`;
    }).join("");
    const needle = `${f(k)},${f(k - r * 0.78)} ${f(k + w)},${f(k)} ${f(k)},${f(k + r * 0.22)} ${f(k - w)},${f(k)}`;
    return `<svg viewBox="0 0 ${size} ${size}" width="${size}" height="${size}" style="display:block;overflow:visible" aria-hidden="true">` +
      `<circle cx="${k}" cy="${k}" r="${r}" fill="var(--c-bg)"/>` +
      `<circle cx="${k}" cy="${k}" r="${r - 1}" fill="none" stroke="var(--c-keyline)" stroke-width="2"/>` +
      `<g stroke="var(--c-quiet)" stroke-width="3" stroke-linecap="round">${ticks}</g>` +
      `<g transform="rotate(${deg} ${k} ${k})" opacity="${dim ? 0.3 : 1}">` +
      `<polygon points="${needle}" fill="var(--highlight)" stroke="#000" stroke-width="1.5" stroke-miterlimit="10"/></g>` +
      `<circle cx="${k}" cy="${k}" r="5" fill="#fff"/></svg>`;
  };

  /** Fills every <span class="needle" data-size data-dir> placeholder. */
  C.needles = function (root) {
    (root || document).querySelectorAll(".needle[data-size]").forEach((n) => {
      const size = parseFloat(n.dataset.size);
      const dir = n.dataset.dir;
      n.style.width = px(size); n.style.height = px(size);
      n.innerHTML = C.needleSVG(size, DEG[dir] != null ? DEG[dir] : parseFloat(n.dataset.deg || "0"), !(dir in DEG));
    });
  };

  /** Circle().trim(from: 0, to: p) strokes, rotated -90° so they fill clockwise
   *  from the top: [{color, width}] drawn in order, plus an optional full track. */
  C.ringSVG = function (size, p, strokes, track) {
    const k = size / 2, r = size / 2, len = 2 * Math.PI * r;
    let s = `<svg class="ring" viewBox="0 0 ${size} ${size}" width="${size}" height="${size}" aria-hidden="true"><g fill="none" transform="rotate(-90 ${k} ${k})">`;
    if (track) s += `<circle cx="${k}" cy="${k}" r="${r}" stroke="${track.color}" stroke-width="${track.width}"/>`;
    for (const t of strokes) {
      s += `<circle cx="${k}" cy="${k}" r="${r}" stroke="${t.color}" stroke-width="${t.width}" stroke-linecap="round" stroke-dasharray="${(p * len).toFixed(2)} ${len.toFixed(2)}"/>`;
    }
    return s + "</g></svg>";
  };

  // ---------------------------------------------------------------- DialMetrics

  /** CompassDial.swift, DialMetrics.init(size:showsChips:), line for line. */
  C.metrics = function (w, h, showsChips) {
    const width = Math.max(w, 0), height = Math.max(h, 0);
    const gap = Math.min(width, height) < 500 ? 8 : 14;
    const sideWidth = Math.max(Math.min(width * 0.27, 340), Math.min(76, width / 4));
    const midWidth = Math.max(width - 2 * sideWidth - 2 * gap, 0);
    const chipsBelow = showsChips && midWidth < 240;
    const rowHeight = 60;
    const crossHeight = Math.max(height - (chipsBelow ? rowHeight + gap : 0), 0);
    const petalHeight = Math.max(crossHeight * 0.24, 0);
    const middleHeight = Math.max(crossHeight - 2 * petalHeight - 2 * gap, 0);
    const chipHeight = !showsChips ? 0 : chipsBelow ? rowHeight : Math.min(Math.max(middleHeight * 0.22, 56), 72);
    return { width, height, gap, sideWidth, midWidth, chipsBelow, petalHeight, middleHeight, chipHeight };
  };

  // ---------------------------------------------------------------- parts

  function guideMarker(lang) {
    const g = el("span", "guide");
    g.appendChild(window.kit.icon("hand.point.up.left.fill"));
    el("b", null, g).textContent = L(T.next, lang);
    return g;
  }

  /** PetalView. Returns the element and a function that fits it once attached. */
  function petal(choice, dir, w, h, o) {
    const p = el("div", "petal k-" + choice.kind);
    p.style.width = px(w); p.style.height = px(h);
    p.dataset.stop = dir;
    const wide = w > h * 1.3;
    const side = Math.max(wide ? Math.min(h * 0.58, 110) : Math.min(w * 0.5, h * 0.4, 110), 24);
    const size = wide ? Math.max(Math.min(h * 0.3, 54), 20) : Math.max(Math.min(w * 0.17, 48), 20);
    const inner = el("div", "petal-in " + (wide ? "row" : "col"), p);
    inner.appendChild(symbol(choice.symbol, side, true));
    const label = el("b", "petal-label", inner);
    label.textContent = L(choice.label, o.lang);
    label.style.textAlign = wide ? "left" : "center";
    // The badge yields to the tag on a narrow petal, except while a head holds.
    if (!(o.guide && o.narrow) || o.progress > 0) {
      const badge = el("span", "badge" + (o.progress > 0 ? " holding" : ""), p);
      if (o.progress > 0) {
        badge.insertAdjacentHTML("beforeend", C.ringSVG(56, o.progress, [{ color: "#000", width: 9 }, { color: "var(--highlight)", width: 5 }]));
      }
      badge.appendChild(window.kit.icon(ARROW[dir]));
    }
    if (o.guide) p.appendChild(guideMarker(o.lang));
    const fit = () => C.fitText(label, size, {
      lines: 2, minScale: 0.4,
      width: wide ? w - 36 - side - 16 : w - 36,
      height: wide ? h - 24 : h - 24 - side - 10,
      hug: wide,
    });
    return { node: p, fit, info: { wide, side, size } };
  }

  /** HubView: needle, trail, yellow draft, the message, Speak. */
  function hub(w, h, o) {
    const lang = o.lang;
    const hb = el("div", "hub");
    hb.style.width = px(w); hb.style.height = px(h);
    hb.dataset.stop = "hub";
    const wide = w > h * 1.15;
    const inner = el("div", "hub-in " + (wide ? "row" : "col"), hb);
    const nsize = wide ? Math.min(h * 0.62, w * 0.3, 150) : Math.min(w * 0.42, h * 0.28, 110);
    const needle = el("span", "needle", inner);
    needle.dataset.size = String(nsize);
    if (o.needle) needle.dataset.dir = o.needle; else needle.dataset.deg = String(o.needleRest || 0);
    const words = el("div", "words", inner);
    const ww = w - 28 - (wide ? nsize + 16 : 0);
    const wh = h - 28 - (wide ? 0 : nsize + 10);
    words.style.width = px(ww); words.style.height = px(wh);
    const parts = [];
    if (o.crumbs) { const t = el("span", "crumbs", words); t.textContent = o.crumbs; parts.push([t, 15, 1, 0.6]); }
    if (o.draft) { const t = el("span", "draft", words); t.textContent = o.draft; parts.push([t, 22, 2, 0.5]); }
    const msg = el("span", "message" + (o.message ? "" : " empty"), words);
    msg.textContent = o.message || L(T.messageEmpty, lang);
    parts.push([msg, o.message ? 22 : 20, 4, 0.4]);
    el("span", "grow", words);
    if (o.paused) {
      const t = el("span", "crumbs", words);
      t.appendChild(window.kit.icon("pause.circle.fill"));
      t.append(" " + L(T.paused, lang));
    }
    const pill = el("span", "pill" + (o.speaking ? " speaking" : ""), words);
    pill.appendChild(window.kit.icon("speaker.wave.2.fill"));
    el("b", null, pill).textContent = L(o.speaking ? T.speaking : T.speak, lang);
    if (o.guide) { const g = guideMarker(lang); g.style.left = "auto"; g.style.right = "10px"; hb.appendChild(g); }
    const fit = () => {
      // The VStack's spacing and the Speak pill come first; the texts share the rest.
      const children = words.children.length;
      let left = wh - (children - 1) * 6 - pill.offsetHeight;
      for (const [t, size, lines, minScale] of parts) {
        C.fitText(t, size, { lines, minScale, width: ww, height: Math.max(left, size * LH * minScale) });
        left -= t.offsetHeight;
      }
    };
    return { node: hb, fit, info: { wide, nsize, ww, wh } };
  }

  /** The chips under the hub (HubChip), in scan order. */
  function chips(w, h, list, o) {
    const row = el("div", "chips");
    row.style.width = px(w); row.style.height = px(h);
    const titles = [];
    for (const ch of list) {
      const n = el("div", "chip", row);
      n.dataset.stop = ch.id;
      const ico = el("span", "ico", n);
      ico.appendChild(window.kit.icon(ch.symbol));
      const t = el("b", null, n);
      t.textContent = ch.title;
      titles.push(t);
      if (ch.guide) { const g = guideMarker(o.lang); g.style.top = "-16px"; g.style.left = "50%"; g.style.transform = "translate(-50%, 0)"; n.appendChild(g); }
    }
    const chipW = (w - 10 * (list.length - 1)) / list.length;
    const fit = () => titles.forEach((t) => C.fitText(t, 20, { lines: 1, minScale: 0.5, width: chipW - 24 - 32 - 8 }));
    return { node: row, fit, info: { chipW } };
  }

  // ---------------------------------------------------------------- the dial

  /**
   * CompassDial in `host`, sized width × height as its GeometryReader would be.
   *   level        "home", "feel", "pain", "pain.head"…; trail lists the levels after home
   *   lit          a direction, "hub", or a chip id ("language", "clear", "back"…)
   *   guide        the stop carrying the "Next" tag
   *   pointer      {dir, progress} while a head points (lights and fills that petal)
   *   message      the message so far (English or Ukrainian text), "" when empty
   */
  C.dial = function (host, cfg) {
    const lang = cfg.lang || "en";
    const showsChips = cfg.showsChips !== false;
    const m = C.metrics(cfg.width, cfg.height, showsChips);
    const trail = cfg.trail || [];
    const level = LEVELS[trail.length ? trail[trail.length - 1] : "home"];
    const isHome = trail.length === 0;
    const pointing = !!cfg.pointer;
    const litDir = pointing ? cfg.pointer.dir : DIRS.includes(cfg.lit) ? cfg.lit : null;

    const dial = el("div", "dial", host);
    dial.style.width = px(m.width); dial.style.height = px(m.height); dial.style.gap = px(m.gap);
    const fits = [];
    const parts = {};
    const makePetal = (dir) => {
      const narrow = dir === "east" || dir === "west" ? m.sideWidth < 160 : m.midWidth < 160;
      const wv = dir === "east" || dir === "west" ? m.sideWidth : m.midWidth;
      const hv = dir === "east" || dir === "west" ? m.middleHeight : m.petalHeight;
      const pt = petal(level[dir], dir, wv, hv, {
        lang, narrow, guide: cfg.guide === dir,
        progress: pointing && cfg.pointer.dir === dir ? cfg.pointer.progress : 0,
      });
      fits.push(pt.fit);
      parts[dir] = pt;
      return pt.node;
    };

    dial.appendChild(makePetal("north"));
    const mid = el("div", "dial-mid", dial);
    mid.style.gap = px(m.gap);
    mid.appendChild(makePetal("west"));
    const centre = el("div", "dial-centre", mid);
    centre.style.width = px(m.midWidth); centre.style.height = px(m.middleHeight); centre.style.gap = px(m.gap);
    mid.appendChild(makePetal("east"));
    dial.appendChild(makePetal("south"));

    // Hub: the rest of the centre once the chips (if they sit there) have theirs.
    const chipsInCentre = showsChips && !m.chipsBelow;
    const hubH = m.middleHeight - (chipsInCentre ? m.gap + m.chipHeight : 0);
    const crumbs = trail.map((id) => L(LEVELS[id].crumb, lang)).join(" › ");
    const hb = hub(m.midWidth, hubH, {
      lang, crumbs: crumbs || null, draft: isHome ? null : L(level.draft, lang),
      message: cfg.message || "", speaking: !!cfg.speaking, paused: !!cfg.paused,
      needle: litDir, needleRest: cfg.needleRest, guide: cfg.guide === "hub",
    });
    centre.appendChild(hb.node);
    fits.push(hb.fit);
    parts.hub = hb;

    if (showsChips) {
      let list;
      if (!isHome) {
        list = [{ id: "back", title: L(T.goBack, lang), symbol: "arrow.uturn.backward" }];
        if (trail.length >= 2) list.push({ id: "backToStart", title: L(T.backToStart, lang), symbol: "arrow.counterclockwise" });
      } else if (cfg.confirmingClear) {
        list = [{ id: "clearCancel", title: L(T.clearCancel, lang), symbol: "arrow.uturn.backward" },
          { id: "clearConfirm", title: L(T.clearConfirm, lang), symbol: "checkmark.circle.fill" }];
      } else {
        // Copy.Board.switchTo(language.other): the other language, named in itself.
        list = [{ id: "language", title: NATIVE[lang === "uk" ? "en" : "uk"], symbol: "globe" }];
        if (cfg.message) list.push({ id: "clear", title: L(T.clear, lang), symbol: "xmark" });
      }
      list.forEach((ch) => { ch.guide = cfg.guide === ch.id; });
      const row = chips(m.chipsBelow ? m.width : m.midWidth, m.chipHeight, list, { lang });
      (m.chipsBelow ? dial : centre).appendChild(row.node);
      fits.push(row.fit);
      parts.chips = row;
    }

    C.needles(dial);
    cropSymbols(dial);
    fits.forEach((f) => f());
    // Lift the lit stop last: its 1.04 scale must not reach the measurements.
    const litNode = cfg.lit || litDir ? dial.querySelector(`[data-stop="${litDir || cfg.lit}"]`) : null;
    if (litNode) litNode.classList.add("lit");
    return { metrics: m, parts };
  };

  // ---------------------------------------------------------------- scrolling

  /** ScrollViewProxy.scrollTo(id, anchor:) on a page that cannot be scrolled by
   *  finger: offsets `content` inside the clipping `viewport`, clamped to the
   *  scrollable range, and returns the offset. */
  C.reveal = function (viewport, content, target, anchor) {
    const vr = viewport.getBoundingClientRect(), cr = content.getBoundingClientRect(), tr = target.getBoundingClientRect();
    const top = tr.top - cr.top, bottom = tr.bottom - cr.top;
    const want = anchor === "bottom" ? bottom - vr.height : (top + bottom) / 2 - vr.height / 2;
    const offset = Math.max(0, Math.min(want, cr.height - vr.height));
    content.style.transform = `translateY(${-offset}px)`;
    return offset;
  };

  // ---------------------------------------------------------------- start-up

  /** Runs `fn` once the page is parsed (after kit.js has swapped the icons) and
   *  the kit's rounded faces are loaded, so every measurement is real. */
  C.ready = function (fn) {
    const go = () => {
      const faces = ["400 20px Nunito", "600 20px Nunito", "700 20px Nunito", "800 20px Nunito", "900 20px Nunito"];
      Promise.all(faces.map((f) => document.fonts.load(f, "Aa Дд Її"))).then(() => {
        try {
          C.needles();
          fn();
        } catch (e) {
          console.error("compass.js: " + (e && e.stack ? e.stack : e));
        }
      });
    };
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", go);
    else go();
  };
})();
