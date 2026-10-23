/* Holos Words mockups: a few SF Symbol stand-ins replaced with closer shapes.
 *
 * The kit maps these line symbols to Phosphor "fill" glyphs, which are boxed or
 * solid shapes (a white X knocked out of a square for "xmark", a solid triangle
 * for "chevron.right"). The code draws the plain symbols at a bold weight
 * (`.weight(.bold)`), so Phosphor's bold set is the faithful stand-in.
 * Phosphor Icons, MIT (see ../kit/Phosphor-LICENSE.txt). Load after icons.js,
 * before kit.js.
 */
(function () {
  const icons = window.SF_ICONS || (window.SF_ICONS = {});
  const vb = "0 0 256 256";
  icons["xmark"] = { vb: vb, d: '<path d="M208.49,191.51a12,12,0,0,1-17,17L128,145,64.49,208.49a12,12,0,0,1-17-17L111,128,47.51,64.49a12,12,0,0,1,17-17L128,111l63.51-63.52a12,12,0,0,1,17,17L145,128Z"/>' };
  icons["chevron.right"] = { vb: vb, d: '<path d="M184.49,136.49l-80,80a12,12,0,0,1-17-17L159,128,87.51,56.49a12,12,0,1,1,17-17l80,80A12,12,0,0,1,184.49,136.49Z"/>' };
  icons["plus"] = { vb: vb, d: '<path d="M228,128a12,12,0,0,1-12,12H140v76a12,12,0,0,1-24,0V140H40a12,12,0,0,1,0-24h76V40a12,12,0,0,1,24,0v76h76A12,12,0,0,1,228,128Z"/>' };
  icons["arrow.right"] = { vb: vb, d: '<path d="M224.49,136.49l-72,72a12,12,0,0,1-17-17L187,140H40a12,12,0,0,1,0-24H187L135.51,64.48a12,12,0,0,1,17-17l72,72A12,12,0,0,1,224.49,136.49Z"/>' };
  icons["arrow.down"] = { vb: vb, d: '<path d="M208.49,152.49l-72,72a12,12,0,0,1-17,0l-72-72a12,12,0,0,1,17-17L116,187V40a12,12,0,0,1,24,0V187l51.51-51.52a12,12,0,0,1,17,17Z"/>' };
  // SF's location.fill is the navigation arrow, pointing up and right (the
  // kit draws a map pin). Phosphor's navigation-arrow-fill, mirrored.
  icons["location.fill"] = { vb: vb, d: '<g transform="translate(256 0) scale(-1 1)"><path d="M248,121.58a15.76,15.76,0,0,1-11.29,15l-.2.06-78,21.84-21.84,78-.06.2a15.77,15.77,0,0,1-15,11.29h-.3a15.77,15.77,0,0,1-15.07-10.67L41,61.41a1,1,0,0,1-.05-.16A16,16,0,0,1,61.25,40.9l.16.05,175.92,65.26A15.78,15.78,0,0,1,248,121.58Z"/></g>' };
})();
