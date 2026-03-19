import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/utils/url_utils.dart';

void main() {
  group('resolveAvatarUrl', () {
    test('returns null for null input', () {
      expect(resolveAvatarUrl(null), isNull);
    });

    test('returns null for empty string', () {
      expect(resolveAvatarUrl(''), isNull);
    });

    test('prepends base URL to relative path', () {
      final result = resolveAvatarUrl('/uploads/avatars/team-1.png');
      expect(result, isNotNull);
      expect(result, contains('/uploads/avatars/team-1.png'));
      expect(result, isNot(startsWith('/')));
    });

    test('returns absolute URL as-is', () {
      const url = 'https://example.com/avatar.png';
      expect(resolveAvatarUrl(url), equals(url));
    });

    test('returns http URL as-is', () {
      const url = 'http://localhost:8080/avatar.png';
      expect(resolveAvatarUrl(url), equals(url));
    });
  });
}
