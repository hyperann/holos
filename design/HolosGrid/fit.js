/* Holos Grid — stands in for SwiftUI's Text(...).lineLimit(n).minimumScaleFactor(m)
 * on the iPhone board, where cells are about 52 pt wide.
 *
 * A label marked data-fit="<size px> <minimum scale> <lines> [<max height px>]"
 * keeps its size if it fits in n lines (breaking a word wider than the line, as
 * Text does), else shrinks in 1 % steps down to the minimum scale, else stays at
 * the minimum and is truncated. It runs once the fonts are in, before the shot.
 */
(function () {
  function fits(el, size, lines, maxHeight) {
    var h = el.getBoundingClientRect().height;
    var n = Math.round(h / (size * 1.193));
    return n <= lines && el.scrollWidth <= el.clientWidth + 0.5 && (!maxHeight || h <= maxHeight + 0.5);
  }
  function fit(el) {
    var p = el.dataset.fit.split(" ").map(Number);
    var base = p[0], min = p[1], lines = p[2], maxHeight = p[3];
    el.style.display = "block";
    el.style.webkitLineClamp = "none";
    el.style.overflowWrap = "anywhere";
    el.style.lineHeight = "1.193";
    for (var s = 1; s >= min - 1e-9; s -= 0.01) {
      el.style.fontSize = base * s + "px";
      if (fits(el, base * s, lines, maxHeight)) return;
    }
    el.style.fontSize = base * min + "px";
    el.style.display = "-webkit-box";
    el.style.webkitBoxOrient = "vertical";
    el.style.webkitLineClamp = String(lines);
    el.style.overflow = "hidden";
    el.style.maxHeight = lines * base * min * 1.193 + "px";
  }
  var faces = ["700 20px Nunito", "800 20px Nunito"];
  Promise.all(faces.map(function (f) { return document.fonts.load(f, "Aa Дд"); }))
    .then(function () { return document.fonts.ready; })
    .then(function () { document.querySelectorAll("[data-fit]").forEach(fit); });
})();
