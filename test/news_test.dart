import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/news.dart';

void main() {
  test('NewsPost.fromJson parses fields', () {
    final post = NewsPost.fromJson(<String, dynamic>{
      'slug': 'whats-new',
      'title': 'What’s new',
      'body': '# Hello\nWorld',
      'type': 'new',
      'published_at': '2026-06-28T10:00:00Z',
    });
    expect(post.slug, 'whats-new');
    expect(post.title, 'What’s new');
    expect(post.body, contains('World'));
    expect(post.type, 'new');
  });

  test('parseNewsList reads items + total', () {
    final list = parseNewsList(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'slug': 'a', 'title': 'A'},
        <String, dynamic>{'slug': 'b', 'title': 'B'},
      ],
      'total': 5,
    });
    expect(list.items, hasLength(2));
    expect(list.total, 5);
    expect(list.items.first.title, 'A');
  });
}
