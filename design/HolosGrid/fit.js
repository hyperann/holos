/* Holos Grid — stands in for SwiftUI's Text(...).lineLimit(n).minimumScaleFactor(m)
 * on the iPhone board, where a cell is about 52 pt wide.
 *
 * A label marked data-fit="<size px> <minimum scale> <lines> [<height px>]" is
 * laid out the way Text is: it keeps its size if it fits in n lines (breaking a
 * word that is wider than the line, as Text does) within the width and the
 * height it is offered, else shrinks in 1 % steps down to the minimum scale,
 * else stays at the minimum and is truncated to the lines that fit.
 *
 * The height is what the cell's VStack offers the label: Text is less flexible
 * than the resizable symbol above it, so it is offered an equal share — half of
 * the cell's inner height less the 6 pt spacing.
 *
 * It runs once the fonts are in, before render.cjs takes the shot.
 */
(function () {
  var LH = 1.193;
  function measure(el, size, lines, maxHeight) {
    var h = el.getBoundingClientRect().height;
    var n = Math.round(h / (size * LH));
    return n <= lines && el.scrollWidth <= el.clientWidth + 0.5 && (!maxHeight || h <= maxHeight + 0.01);
  }
  function fit(el) {
    var p = el.dataset.fit.split(" ").map(Number);
    var base = p[0], min = p[1], lines = p[2], maxHeight = p[3];
    el.style.display = "block";
    el.style.webkitLineClamp = "none";
    el.style.overflowWrap = "anywhere";
    el.style.lineHeight = String(LH);
    for (var s = 1; s >= min - 1e-9; s -= 0.01) {
      el.style.fontSize = base * s + "px";
      if (measure(el, base * s, lines, maxHeight)) return;
    }
    var size = base * min;
    var shown = maxHeight ? Math.max(1, Math.min(lines, Math.floor((maxHeight + 0.01) / (size * LH)))) : lines;
    el.style.fontSize = size + "px";
    el.style.overflow = "hidden";
    if (shown === 1) {
      el.style.whiteSpace = "nowrap";
      el.style.textOverflow = "ellipsis";
    } else {
      el.style.display = "-webkit-box";
      el.style.webkitBoxOrient = "vertical";
      el.style.webkitLineClamp = String(shown);
    }
  }
  var faces = ["700 20px Nunito", "800 20px Nunito"];
  Promise.all(faces.map(function (f) { return document.fonts.load(f, "Aa Дд"); }))
    .then(function () { return document.fonts.ready; })
    .then(function () { document.querySelectorAll("[data-fit]").forEach(fit); });
})();
