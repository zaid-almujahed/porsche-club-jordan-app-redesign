/// A place the backend's weather endpoint knows (its SPECIAL_LOCATIONS),
/// under the name it takes ([key]).
class KnownLocation {
  const KnownLocation(this.key, this.name, this.latitude, this.longitude);

  final String key;
  final String name;
  final double latitude;
  final double longitude;
}

const List<KnownLocation> knownLocations = <KnownLocation>[
  KnownLocation('dead sea', 'Dead Sea', 31.7149, 35.5802),
  KnownLocation('wadi rum', 'Wadi Rum', 29.5321, 35.4194),
  KnownLocation('petra', 'Petra', 30.3285, 35.4444),
  KnownLocation('wadi musa', 'Wadi Musa', 30.3170, 35.4794),
  KnownLocation('aqaba south beach', 'South Beach', 29.4370, 34.9740),
  KnownLocation('amman', 'Amman', 31.9539, 35.9106),
  KnownLocation('zarqa', 'Zarqa', 32.0728, 36.0880),
  KnownLocation('irbid', 'Irbid', 32.5569, 35.8479),
  KnownLocation('aqaba', 'Aqaba', 29.5319, 35.0061),
  KnownLocation('salt', 'As-Salt', 32.0392, 35.7272),
  KnownLocation('madaba', 'Madaba', 31.7167, 35.8000),
  KnownLocation('jerash', 'Jerash', 32.2747, 35.8961),
  KnownLocation('ajloun', 'Ajloun', 32.3333, 35.7500),
  KnownLocation('mafraq', 'Mafraq', 32.3429, 36.2080),
  KnownLocation('karak', 'Al-Karak', 31.1853, 35.7048),
  KnownLocation('tafilah', 'Tafilah', 30.8375, 35.6044),
  KnownLocation('maan', "Ma'an", 30.1962, 35.7345),
  KnownLocation('ramtha', 'Ar-Ramtha', 32.5587, 36.0111),
  KnownLocation('ruwaished', 'Ar-Ruwaished', 32.5000, 38.2000),
  KnownLocation('sahab', 'Sahab', 31.8703, 36.0048),
  KnownLocation('russifa', 'Russeifa', 32.0178, 36.0464),
  KnownLocation('shobak', 'Shobak', 30.5222, 35.5706),
  KnownLocation('qatrana', 'Qatrana', 31.2500, 36.0500),
  KnownLocation('fuheis', 'Fuheis', 32.0046, 35.7833),
  KnownLocation('as-sareeh', 'As-Sareeh', 32.4914, 35.8647),
];

/// The known place an event's location names: all of it ("Amman"), or a
/// known name inside it ("Dead Sea Marriott Resort" is the Dead Sea). The
/// longest name wins, so "Aqaba South Beach" is not read as Aqaba. Null when
/// it names none of them; the weather endpoint knows no other place.
KnownLocation? knownLocationFor(String location) {
  final String text = location.trim().toLowerCase();
  if (text.isEmpty) return null;
  KnownLocation? best;
  int bestLength = 0;
  for (final KnownLocation place in knownLocations) {
    for (final String term in <String>{place.key, place.name.toLowerCase()}) {
      if (term.length > bestLength && _containsWord(text, term)) {
        best = place;
        bestLength = term.length;
      }
    }
  }
  return best;
}

// [term] as whole words, so "salt" is not found in "basalt".
bool _containsWord(String text, String term) =>
    RegExp('(?<![a-z])${RegExp.escape(term)}(?![a-z])').hasMatch(text);
