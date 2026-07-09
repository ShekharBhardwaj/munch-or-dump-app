import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/cart.dart';
import 'package:munch_or_dump/core/models/receipt.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/features/cart/cart_controller.dart';
import 'package:munch_or_dump/features/cart/cart_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';

CartItem _item({
  String name = 'Item',
  String? slug,
  Verdict? verdict,
  int? score,
  bool locked = false,
}) => CartItem(
  inputName: name,
  name: name,
  productSlug: slug,
  verdict: verdict,
  score: score,
  locked: locked,
  addedAt: DateTime.utc(2026, 7, 1),
);

Future<ProviderContainer> _container({
  Map<String, Object> initial = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: <Override>[sharedPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartItem.key (web itemKey port)', () {
    test('slug wins over name', () {
      expect(
        _item(name: 'Oat Milk', slug: 'oatly-oat-milk').key,
        'slug:oatly-oat-milk',
      );
    });

    test('falls back to lowercased trimmed name', () {
      expect(_item(name: '  Oat Milk ').key, 'name:oat milk');
    });

    test('empty identity yields the rejected sentinel', () {
      expect(_item(name: '').key, 'name:');
    });
  });

  group('computeCartScore (verdict-mix math, web computeScore port)', () {
    test('averages scored unlocked items, rounded', () {
      final score = computeCartScore(<CartItem>[
        _item(name: 'a', verdict: Verdict.munch, score: 80),
        _item(name: 'b', verdict: Verdict.dump, score: 15),
        _item(name: 'c', verdict: Verdict.okay, score: 61),
      ]);
      expect(score, 52); // (80 + 15 + 61) / 3 = 52
    });

    test('excludes locked and unscored items', () {
      final score = computeCartScore(<CartItem>[
        _item(name: 'a', score: 80),
        _item(name: 'b', score: 10, locked: true),
        _item(name: 'c'), // unknown — no score
      ]);
      expect(score, 80);
    });

    test('null when nothing qualifies', () {
      expect(computeCartScore(<CartItem>[]), isNull);
      expect(computeCartScore(<CartItem>[_item(name: 'a')]), isNull);
      expect(
        computeCartScore(<CartItem>[_item(name: 'a', score: 5, locked: true)]),
        isNull,
      );
    });

    test('includes score-but-no-verdict items (matches web)', () {
      expect(computeCartScore(<CartItem>[_item(name: 'a', score: 40)]), 40);
    });
  });

  group('CartState section splits', () {
    final state = CartState(
      items: <CartItem>[
        _item(name: 'good-low', verdict: Verdict.treat, score: 50),
        _item(name: 'bad-worst', verdict: Verdict.dump, score: 5),
        _item(name: 'good-high', verdict: Verdict.munch, score: 85),
        _item(name: 'bad-mid', verdict: Verdict.engineered, score: 30),
        _item(name: 'locked', score: 10, locked: true),
        _item(name: 'mystery'),
      ],
    );

    test('analyzed excludes locked + unknown', () {
      expect(state.analyzed, hasLength(4));
    });

    test('bad is worst-first, good is best-first', () {
      expect(state.bad.map((CartItem i) => i.name), <String>[
        'bad-worst',
        'bad-mid',
      ]);
      expect(state.good.map((CartItem i) => i.name), <String>[
        'good-high',
        'good-low',
      ]);
    });

    test('locked and unknown split out', () {
      expect(state.lockedItems.single.name, 'locked');
      expect(state.unknown.single.name, 'mystery');
    });
  });

  group('score labels and trend (web Receipt.jsx thresholds)', () {
    test('scoreLabel bands', () {
      expect(scoreLabel(85), 'Clean cart');
      expect(scoreLabel(70), 'Mostly good');
      expect(scoreLabel(55), 'Mixed bag');
      expect(scoreLabel(40), 'Needs work');
      expect(scoreLabel(10), 'Red zone');
    });

    test('trajectoryTrend detects improvement / decline / stability', () {
      expect(trajectoryTrend(<int>[40, 42, 60, 70]).improving, isTrue);
      expect(trajectoryTrend(<int>[70, 60, 42, 40]).declining, isTrue);
      final stable = trajectoryTrend(<int>[50, 51, 50, 52]);
      expect(stable.improving, isFalse);
      expect(stable.declining, isFalse);
      expect(stable.label, '→ Stable');
    });
  });

  group('CartItem JSON round-trip', () {
    test('preserves every field through toJson/fromJson', () {
      final original = CartItem(
        inputName: 'STRBK CLD BRW',
        name: 'Starbucks Cold Brew',
        productSlug: 'starbucks-cold-brew',
        brandName: 'Starbucks',
        verdict: Verdict.okay,
        score: 60,
        shortExplanation: 'Fine in moderation.',
        verdictReasons: const <String>['Low sugar', 'Some additives'],
        source: 'receipt',
        addedAt: DateTime.utc(2026, 7, 9, 12, 30),
      );
      final restored = CartItem.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.inputName, original.inputName);
      expect(restored.name, original.name);
      expect(restored.productSlug, original.productSlug);
      expect(restored.brandName, original.brandName);
      expect(restored.verdict, original.verdict);
      expect(restored.score, original.score);
      expect(restored.shortExplanation, original.shortExplanation);
      expect(restored.verdictReasons, original.verdictReasons);
      expect(restored.locked, original.locked);
      expect(restored.source, original.source);
      expect(restored.addedAt, original.addedAt);
      expect(restored.key, original.key);
    });

    test('fromReceiptItem carries the locked flag and source', () {
      final receiptItem = ReceiptItem.fromJson(<String, dynamic>{
        'input_name': 'mystery',
        'locked': true,
      });
      final item = CartItem.fromReceiptItem(receiptItem, source: 'typed');
      expect(item.locked, isTrue);
      expect(item.source, 'typed');
      expect(item.verdict, isNull);
    });
  });

  group('CartController', () {
    test('adds with dedup by key and persists', () async {
      final container = await _container();
      final cart = container.read(cartControllerProvider.notifier);

      expect(
        cart.addItem(_item(name: 'Oat Milk', slug: 'oatly', score: 80)),
        isTrue,
      );
      // Same slug, different name → deduped.
      expect(
        cart.addItem(_item(name: 'Oatly Oat Milk', slug: 'oatly')),
        isFalse,
      );
      // Empty identity → rejected.
      expect(cart.addItem(_item(name: '')), isFalse);
      expect(container.read(cartControllerProvider).count, 1);

      final prefs = container.read(sharedPrefsProvider);
      final persisted =
          jsonDecode(prefs.getString(CartController.itemsKey)!) as List;
      expect(persisted, hasLength(1));
    });

    test('hydrates from persisted JSON on build', () async {
      final container = await _container(
        initial: <String, Object>{
          CartController.itemsKey: jsonEncode(<Map<String, dynamic>>[
            _item(name: 'Chips', verdict: Verdict.dump, score: 12).toJson(),
          ]),
        },
      );
      final state = container.read(cartControllerProvider);
      expect(state.count, 1);
      expect(state.items.single.verdict, Verdict.dump);
      expect(state.cartScore, 12);
    });

    test('corrupt prefs JSON never crashes build', () async {
      final container = await _container(
        initial: <String, Object>{
          CartController.itemsKey: '{not json[',
          CartController.historyKey: '42',
        },
      );
      final state = container.read(cartControllerProvider);
      expect(state.items, isEmpty);
      expect(state.savedTrips, isEmpty);
    });

    test(
      'wrong-typed prefs value (getString throws) never crashes build',
      () async {
        // A non-string under our keys makes prefs.getString throw a TypeError —
        // hydration must treat it like corrupt JSON, not crash.
        final container = await _container(
          initial: <String, Object>{
            CartController.itemsKey: 123,
            CartController.historyKey: true,
          },
        );
        final state = container.read(cartControllerProvider);
        expect(state.items, isEmpty);
        expect(state.savedTrips, isEmpty);
      },
    );

    test(
      'saveTrip snapshots score, clears items, caps history at 10',
      () async {
        final container = await _container();
        final cart = container.read(cartControllerProvider.notifier);

        for (var trip = 0; trip < 12; trip++) {
          cart.addItem(
            _item(name: 'item-$trip', verdict: Verdict.okay, score: 60 + trip),
          );
          cart.saveTrip();
        }

        final state = container.read(cartControllerProvider);
        expect(state.items, isEmpty);
        expect(state.savedTrips, hasLength(CartController.maxSavedTrips));
        // Newest first: the last saved trip carries the last score.
        expect(state.savedTrips.first.score, 71);
        expect(state.savedTrips.first.itemCount, 1);
      },
    );

    test('removeByKey, clear, and deleteTrip mutate + persist', () async {
      final container = await _container();
      final cart = container.read(cartControllerProvider.notifier);

      cart.addItem(_item(name: 'a', slug: 'a', score: 50));
      cart.addItem(_item(name: 'b', slug: 'b', score: 70));
      cart.removeByKey('slug:a');
      expect(container.read(cartControllerProvider).count, 1);

      cart.saveTrip();
      final tripId = container
          .read(cartControllerProvider)
          .savedTrips
          .single
          .id;
      cart.deleteTrip(tripId);
      expect(container.read(cartControllerProvider).savedTrips, isEmpty);

      cart.addItem(_item(name: 'c', score: 30));
      cart.clear();
      expect(container.read(cartControllerProvider).count, 0);
      final prefs = container.read(sharedPrefsProvider);
      expect(
        jsonDecode(prefs.getString(CartController.itemsKey)!) as List,
        isEmpty,
      );
    });
  });
}
