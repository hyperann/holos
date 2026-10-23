/* Holos Grid — stand-ins on top of ../kit/icons.js (load after it, before kit.js).
 *
 * SymbolCell draws its picture with .symbolRenderingMode(.hierarchical). For a
 * ".circle.fill" or ".triangle.fill" symbol that means the enclosing shape is
 * the secondary layer (drawn lighter) and the glyph inside is the primary
 * layer, in full ink. Each stand-in here carries both looks: style.css shows
 * the "hier" group inside a .cell and the "mono" group everywhere else (the
 * message-bar chips draw their symbols monochrome).
 *
 * heart.circle.fill also replaces the kit's stand-in, which is a bare heart
 * (the same as heart.fill): "Wife" is a heart inside a disc.
 */
(function () {
  var I = window.SF_ICONS;
  var SECONDARY = 0.45;
  var DISK = '<circle cx="128" cy="128" r="104"/>';

  function both(name, mono, primary, secondary) {
    I[name] = {
      vb: "0 0 256 256",
      d: '<g class="mono">' + mono + '</g><g class="hier"><g opacity="' + SECONDARY + '">' + secondary + "</g>" + primary + "</g>"
    };
  }
  function kitPath(name) {
    return I[name] ? I[name].d : "";
  }

  // heart.circle.fill — Wife. Monochrome: a disc with the heart knocked out
  // (the tint behind shows through); hierarchical: a light disc, a solid heart.
  var heartD = "M240,102c0,70-103.79,126.66-108.21,129a8,8,0,0,1-7.58,0C119.79,228.66,16,172,16,102A62.07,62.07,0,0,1,78,40c20.65,0,38.73,8.88,50,23.89C139.27,48.88,157.35,40,178,40A62.07,62.07,0,0,1,240,102Z";
  var heart = '<path transform="translate(66,66) scale(0.484)" d="' + heartD + '"/>';
  both("heart.circle.fill",
    DISK + '<path transform="translate(66,66) scale(0.484)" style="fill: var(--tint, #fff)" d="' + heartD + '"/>',
    heart, DISK);

  // person.crop.circle.fill — Dad: a light disc, a solid head and shoulders.
  var person = '<circle cx="128" cy="101" r="41"/>' +
    '<path d="M57,203C75,168,100,152,128,152S181,168,199,203A104,104,0,0,1,57,203Z"/>';
  both("person.crop.circle.fill", kitPath("person.crop.circle.fill"), person, DISK);

  // xmark.circle.fill — "It doesn’t help".
  var xmark = '<path d="M97,97L159,159M159,97L97,159" fill="none" stroke="currentColor" stroke-width="17" stroke-linecap="round"/>';
  both("xmark.circle.fill", kitPath("xmark.circle.fill"), xmark, DISK);

  // 3.circle.fill and 8.circle.fill — "A little", "A lot".
  var three = '<path d="M124,188a35.71,35.71,0,0,1-25.71-10.81A8,8,0,1,1,109.71,166,20,20,0,1,0,124,132a8,8,0,0,1-6.55-12.59L136.63,92H104a8,8,0,0,1,0-16h48a8,8,0,0,1,6.55,12.59l-21,30A36,36,0,0,1,124,188Z"/>';
  both("3.circle.fill", kitPath("3.circle.fill"), three, DISK);
  var eight = '<path fill-rule="evenodd" d="M164,152a35.93,35.93,0,0,0-14.19-28.61,32,32,0,1,0-43.62,0A36,36,0,1,0,164,152ZM148,152a20,20,0,1,1-20-20A20,20,0,0,1,148,152ZM128,116a16,16,0,1,0-16-16A16,16,0,0,0,128,116Z"/>';
  both("8.circle.fill", kitPath("8.circle.fill"), eight, DISK);

  // exclamationmark.triangle.fill — Help: a light triangle, a solid "!".
  var triangle = '<path d="M236.8,188.09,149.35,36.22h0a24.76,24.76,0,0,0-42.7,0L19.2,188.09a23.51,23.51,0,0,0,0,23.72A24.35,24.35,0,0,0,40.55,224h174.9a24.35,24.35,0,0,0,21.33-12.19A23.51,23.51,0,0,0,236.8,188.09Z"/>';
  var bang = '<path d="M118,102a10,10,0,0,1,20,0v42a10,10,0,0,1-20,0ZM128,194a14,14,0,1,1,14-14A14,14,0,0,1,128,194Z"/>';
  both("exclamationmark.triangle.fill", kitPath("exclamationmark.triangle.fill"), bang, triangle);
})();
