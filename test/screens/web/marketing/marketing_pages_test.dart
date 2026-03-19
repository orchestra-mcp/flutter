import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marketing pages list is non-empty', () {
    const pages = [
      'Landing',
      'Download',
      'Pricing',
      'Blog',
      'Docs',
      'Changelog',
      'About',
      'Status',
    ];
    expect(pages, hasLength(8));
    for (final page in pages) {
      expect(page, isNotEmpty);
    }
  });
}
