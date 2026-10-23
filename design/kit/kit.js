/* Holos design kit — page setup for every mockup.
 *
 * Include after icons.js. It:
 *  - sizes <body> from data-device ("ipad" 1194×834 · "ipad-portrait" 834×1194 · "iphone" 393×852);
 *  - draws the iPadOS/iOS status bar and home indicator (data-statusbar="dark|light|none");
 *  - swaps every <i data-sf="name"></i> for that SF Symbol's stand-in SVG;
 *  - marks <body data-ready> once fonts are loaded, which render.cjs waits for.
 */
(function () {
  const SIZES = { "ipad": [1194, 834], "ipad-portrait": [834, 1194], "iphone": [393, 852] };

  function icon(name) {
    const entry = (window.SF_ICONS || {})[name];
    const span = document.createElement("span");
    span.className = "sf";
    span.dataset.sf = name;
    if (!entry) {
      // Loud on purpose: a missing icon must be noticed in the PNG, not shipped.
      span.innerHTML = '<svg viewBox="0 0 256 256"><rect x="16" y="16" width="224" height="224" rx="40" fill="none" stroke="#ff00ff" stroke-width="24"/><text x="128" y="160" font-size="90" text-anchor="middle" fill="#ff00ff">?</text></svg>';
      console.warn("Missing SF stand-in:", name);
      return span;
    }
    span.innerHTML = '<svg viewBox="' + entry.vb + '" fill="currentColor" xmlns="http://www.w3.org/2000/svg">' + entry.d + "</svg>";
    return span;
  }

  function setup() {
    const body = document.body;
    const device = body.dataset.device || "ipad";
    const size = SIZES[device] || SIZES.ipad;
    body.style.width = size[0] + "px";
    body.style.height = size[1] + "px";

    document.querySelectorAll("i[data-sf]").forEach(function (el) {
      const span = icon(el.dataset.sf);
      if (el.className) span.className += " " + el.className;
      if (el.getAttribute("style")) span.setAttribute("style", el.getAttribute("style"));
      el.replaceWith(span);
    });

    const bar = body.dataset.statusbar || "dark";
    if (bar !== "none") {
      const status = document.createElement("div");
      status.className = "statusbar " + bar;
      status.innerHTML = device === "iphone"
        ? '<span>9:41</span><span class="right"><span class="wifi"></span><span class="battery"></span></span>'
        : '<span>9:41&nbsp;&nbsp;Fri 23 Oct</span><span class="right"><span class="wifi"></span><span>80%</span><span class="battery"></span></span>';
      status.querySelector(".wifi").replaceWith(icon("wifi"));
      body.appendChild(status);
      const home = document.createElement("div");
      home.className = "homeindicator " + bar;
      body.appendChild(home);
    }

    // Ask for every face explicitly (Latin and Cyrillic), so the screenshot
    // can never be taken in a fallback font.
    const faces = ["400 20px Nunito", "600 20px Nunito", "700 20px Nunito", "800 20px Nunito", "900 20px Nunito",
      "400 20px 'Source Serif 4'", "600 20px 'Source Serif 4'", "700 20px 'Source Serif 4'"];
    Promise.all(faces.map(function (f) { return document.fonts.load(f, "Aa Дд Її"); }))
      .then(function () { return document.fonts.ready; })
      .then(function () { body.dataset.ready = "1"; });
  }

  window.kit = { icon: icon };
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", setup);
  } else {
    setup();
  }
})();
