/// The six possible product verdicts returned by the API, ordered best → worst.
///
/// Kept deliberately UI-free (no `Color`) — color mapping lives in the theme
/// layer (`VerdictPalette`) so this model stays pure and testable.
enum Verdict {
  munch('MUNCH', 'Munch', '🥑'),
  okay('OKAY', 'Okay', '👍'),
  treat('TREAT', 'Treat', '🍩'),
  engineered('ENGINEERED', 'Engineered', '⚙️'),
  dump('DUMP', 'Dump', '🚮'),
  bullshit('BULLSHIT', 'Bullshit', '🤡');

  const Verdict(this.apiValue, this.label, this.emoji);

  /// Uppercase token as returned by the API (e.g. `MUNCH`).
  final String apiValue;

  /// Human-friendly label (e.g. `Munch`).
  final String label;

  final String emoji;

  /// Whether this verdict represents a product to steer away from.
  bool get isBad => this == dump || this == engineered || this == bullshit;

  /// Parse an API verdict string. Tolerant of case/whitespace and the `ULTRA*`
  /// synonym the model occasionally emits; falls back to [okay] when unknown.
  static Verdict fromApi(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final verdict in Verdict.values) {
      if (verdict.apiValue == normalized) return verdict;
    }
    if (normalized.startsWith('ULTRA')) return engineered;
    return okay;
  }
}
