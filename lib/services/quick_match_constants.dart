/// Excel-style column letters: 1→A, 26→Z, 27→AA, so each quick session is easy to scan A–Z.
String quickMatchSessionLetters(int sequence1Based) {
  var i = sequence1Based;
  var result = '';
  while (i > 0) {
    i--;
    result = '${String.fromCharCode(65 + i % 26)}$result';
    i ~/= 26;
  }
  return result;
}

/// Names for one quick-match session [n] (each new quick match gets the next index [n]).
// Display name for quick-match teams. Keep database abbreviations unique
// but show friendly names in the UI.
String quickMatchTeamAName(int n) => 'Team A';
String quickMatchTeamBName(int n) => 'Team B';
String quickMatchTeamAAbbrev(int n) => quickMatchSessionLetters(2 * n - 1);
String quickMatchTeamBAbbrev(int n) => quickMatchSessionLetters(2 * n);
