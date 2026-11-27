/// Exact matches only: avoid rejecting ordinary words containing a short fragment.
/// Maintain this small policy list here, independently of the puzzle catalogue.
const invitationBlockedWords = <String>{
  'せっくす',
  'れいぷ',
  'ちんぽ',
  'まんこ',
  'きちがい',
  'かたわ',
  'くろんぼ',
  'ころす',
};

/// Explicit phrases for free-form hints. Ambiguous fragments such as
/// 「かたわ」 are intentionally absent (e.g. 「かたわらの花」 is ordinary).
const invitationBlockedHintFragments = <String>{
  'せっくす',
  'れいぷ',
  'ちんぽ',
  'まんこ',
  'きちがい',
  'くろんぼ',
  'をころす',
  'をころせ',
  '殺す',
  '殺して',
  '強姦',
};
