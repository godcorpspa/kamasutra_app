/// Strips leading/trailing emoji and decorative symbols from a translated
/// label ("🏆 Record" → "Record", "Tutti 🔥" → "Tutti").
///
/// Several translation strings carry emoji that were meant as icons. The
/// redesigned UI draws its own line icons, so labels are shown plain; the
/// translations themselves are left untouched.
String plainLabel(String text) => text.replaceAll(_edgeSymbols, '');

// Opening ¡ ¿ « and closing » are punctuation, not decoration: Spanish
// "¡Hecho!" must keep its first character.
final _edgeSymbols = RegExp(r'^[^\p{L}\p{N}¡¿«]+|[^\p{L}\p{N}).!?…»]+$',
    unicode: true);
