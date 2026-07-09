/// Country name → ISO 3166-1 alpha-2 code. Ported from the web app's
/// `_COUNTRY_ISO` map (`munch-or-dump-ui/src/lib/utils.js`) — keep them in
/// sync.
const Map<String, String> _countryIso = <String, String>{
  'united states': 'US',
  'usa': 'US',
  'u.s.a.': 'US',
  'u.s.': 'US',
  'us': 'US',
  'canada': 'CA',
  'mexico': 'MX',
  'brazil': 'BR',
  'argentina': 'AR',
  'chile': 'CL',
  'colombia': 'CO',
  'peru': 'PE',
  'united kingdom': 'GB',
  'uk': 'GB',
  'great britain': 'GB',
  'england': 'GB',
  'france': 'FR',
  'germany': 'DE',
  'italy': 'IT',
  'spain': 'ES',
  'portugal': 'PT',
  'netherlands': 'NL',
  'belgium': 'BE',
  'switzerland': 'CH',
  'austria': 'AT',
  'sweden': 'SE',
  'denmark': 'DK',
  'norway': 'NO',
  'finland': 'FI',
  'ireland': 'IE',
  'greece': 'GR',
  'poland': 'PL',
  'czech republic': 'CZ',
  'czechia': 'CZ',
  'hungary': 'HU',
  'romania': 'RO',
  'slovakia': 'SK',
  'turkey': 'TR',
  'australia': 'AU',
  'new zealand': 'NZ',
  'japan': 'JP',
  'china': 'CN',
  'south korea': 'KR',
  'korea': 'KR',
  'india': 'IN',
  'thailand': 'TH',
  'vietnam': 'VN',
  'indonesia': 'ID',
  'philippines': 'PH',
  'malaysia': 'MY',
  'singapore': 'SG',
  'israel': 'IL',
  'uae': 'AE',
  'united arab emirates': 'AE',
  'saudi arabia': 'SA',
  'egypt': 'EG',
  'south africa': 'ZA',
  'pakistan': 'PK',
  'bangladesh': 'BD',
};

/// Offset from an ASCII capital letter to its Unicode regional-indicator
/// symbol (🇦 is U+1F1E6, 'A' is U+0041).
const int _regionalIndicatorBase = 0x1F1E6 - 0x41;

/// Maps a free-text country-of-origin [name] ("United States", " india ") to
/// its flag emoji via ISO alpha-2 regional-indicator pairs. The lookup is
/// trimmed and lowercased; returns null when the country isn't recognised.
String? countryFlag(String? name) {
  if (name == null) return null;
  final iso = _countryIso[name.trim().toLowerCase()];
  if (iso == null) return null;
  return String.fromCharCodes(<int>[
    _regionalIndicatorBase + iso.codeUnitAt(0),
    _regionalIndicatorBase + iso.codeUnitAt(1),
  ]);
}
