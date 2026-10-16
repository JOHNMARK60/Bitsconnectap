import 'package:bits_mobile_app/core/services/api_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns a fresh cached response', () async {
    final cache = ApiCacheService();
    await cache.write('user_7_events', {
      'data': {'events': []},
    });

    final result = await cache.read(
      'user_7_events',
      maxAge: const Duration(minutes: 3),
    );

    expect(result, {
      'data': {'events': []},
    });
  });

  test('clears only the selected user cache', () async {
    final cache = ApiCacheService();
    await cache.write('user_7_profile', {'id': 7});
    await cache.write('user_8_profile', {'id': 8});

    await cache.clearForUser(7);

    expect(
      await cache.read('user_7_profile', maxAge: const Duration(minutes: 1)),
      isNull,
    );
    expect(
      await cache.read('user_8_profile', maxAge: const Duration(minutes: 1)),
      {'id': 8},
    );
  });
}
