import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pcj_v5/core/services/remote_image_freshness.dart';

void main() {
  const String url = 'https://example.com/items/images.png';

  test(
    'a picture replaced under the same address gets a new address',
    () async {
      String etag = '"one"';
      int heads = 0;
      final RemoteImageFreshness freshness = RemoteImageFreshness(
        client: MockClient((http.Request request) async {
          heads++;
          expect(request.method, 'HEAD');
          return http.Response(
            '',
            200,
            headers: <String, String>{'etag': etag},
          );
        }),
        checkInterval: Duration.zero,
      );
      int changes = 0;
      freshness.addListener(() => changes++);

      // The first picture keeps its address.
      expect(freshness.resolve(url), url);
      await pumpEventQueue();
      expect(freshness.resolve(url), url);
      await pumpEventQueue();
      expect(changes, 0);

      // A new picture under the same name.
      etag = '"two"';
      freshness.resolve(url);
      await pumpEventQueue();
      expect(changes, 1);
      expect(freshness.resolve(url), '$url?v=two');
      expect(heads, greaterThanOrEqualTo(3));
    },
  );

  test('an address is not checked again within the interval', () async {
    int heads = 0;
    final RemoteImageFreshness freshness = RemoteImageFreshness(
      client: MockClient((http.Request request) async {
        heads++;
        return http.Response('', 200, headers: <String, String>{'etag': '"a"'});
      }),
    );
    for (int i = 0; i < 5; i++) {
      freshness.resolve(url);
      await pumpEventQueue();
    }
    expect(heads, 1);
  });
}
