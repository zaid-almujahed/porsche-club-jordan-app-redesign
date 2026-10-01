import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/events/data/known_locations.dart';

void main() {
  String? keyFor(String location) => knownLocationFor(location)?.key;

  test('finds a known place inside the event location', () {
    expect(keyFor('Amman'), 'amman');
    expect(keyFor('dead sea'), 'dead sea');
    expect(keyFor('Dead Sea Marriott Resort'), 'dead sea');
    expect(keyFor('Kempinski Hotel, Aqaba'), 'aqaba');
    // The longest name wins.
    expect(keyFor('Aqaba South Beach'), 'aqaba south beach');
    // Display names count too.
    expect(keyFor('Downtown As-Salt'), 'salt');
    expect(keyFor("Ma'an Gate"), 'maan');
  });

  test('only whole words, and nothing for unknown places', () {
    expect(keyFor('Basalt Hills'), isNull);
    expect(keyFor('Manja Circuit'), isNull);
    expect(keyFor(''), isNull);
  });
}
