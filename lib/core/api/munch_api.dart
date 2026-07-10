import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:munch_or_dump/core/api/api_client.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/game.dart';
import 'package:munch_or_dump/core/models/news.dart';
import 'package:munch_or_dump/core/models/profile_update.dart';
import 'package:munch_or_dump/core/models/receipt.dart';
import 'package:munch_or_dump/core/models/scan_draft.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/models/user_profile.dart';

/// Typed client over the Munch or Dump API.
///
/// Mirrors the web app's `munchAPI` surface (`src/api/client.js`) so the two
/// clients stay recognizably the same. Phase 1 implements the full auth spine;
/// catalog/scan/analyze endpoints land in Phase 2+.
class MunchApi {
  const MunchApi(this._dio);

  final Dio _dio;

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// GET `/auth/me` — the full current user. Throws [ApiException] (401 if the
  /// session is missing or expired).
  Future<User> getMe() => _get('/auth/me', User.fromJson);

  /// POST `/auth/login` — returns the JWT. On a 403 with
  /// `requires_verification`, the email is unverified (see [ApiException.data]).
  Future<String> login(String email, String password) async {
    final res = await _post('/auth/login', <String, dynamic>{
      'email': email,
      'password': password,
    });
    return _requireToken(res);
  }

  /// POST `/auth/register` — creates an unverified account and emails a 6-digit
  /// code. No token is issued until [verifyEmail] succeeds. 409 if already taken.
  Future<void> register(String email, String password) => _post(
    '/auth/register',
    <String, dynamic>{'email': email, 'password': password},
  );

  /// POST `/auth/verify-email` — confirms the code and returns the JWT.
  Future<String> verifyEmail(String email, String code) async {
    final res = await _post('/auth/verify-email', <String, dynamic>{
      'email': email,
      'code': code,
    });
    return _requireToken(res);
  }

  /// POST `/auth/resend-verification`.
  Future<void> resendVerification(String email) =>
      _post('/auth/resend-verification', <String, dynamic>{'email': email});

  /// POST `/auth/forgot-password` — always succeeds (no account-existence leak).
  Future<void> forgotPassword(String email) =>
      _post('/auth/forgot-password', <String, dynamic>{'email': email});

  /// POST `/auth/reset-password` — sets a new password from the emailed code.
  Future<void> resetPassword(String email, String code, String newPassword) =>
      _post('/auth/reset-password', <String, dynamic>{
        'email': email,
        'code': code,
        'new_password': newPassword,
      });

  /// POST `/auth/google` — exchanges a Google id_token for the JWT. Requires the
  /// backend to have GOOGLE_CLIENT_ID configured (it fails closed otherwise).
  Future<String> googleAuth(String idToken) async {
    final res = await _post('/auth/google', <String, dynamic>{
      'id_token': idToken,
    });
    return _requireToken(res);
  }

  /// POST `/auth/apple` — exchanges an Apple identity token for the JWT.
  /// [fullName] rides along on first authorization (Apple only provides it
  /// once). Same `{token, user}` response shape as [googleAuth].
  Future<String> signInWithApple(
    String identityToken, {
    String? fullName,
  }) async {
    final body = <String, dynamic>{'identity_token': identityToken};
    if (fullName != null && fullName.isNotEmpty) body['full_name'] = fullName;
    final res = await _post('/auth/apple', body);
    return _requireToken(res);
  }

  /// POST `/auth/logout` — revokes the session server-side (bumps token_version).
  Future<void> logout() => _post('/auth/logout', const <String, dynamic>{});

  /// DELETE `/auth/me` — permanently deletes the account and everything tied
  /// to it (scans, votes, watches, saved lists). The backend confirms with
  /// `{deleted: true}`; anything else is treated as a failure so the caller
  /// never signs the user out on a deletion that didn't happen.
  Future<void> deleteAccount() async {
    final res = await _delete('/auth/me', const <String, dynamic>{});
    if (res['deleted'] != true) {
      throw const ApiException(
        'We couldn’t delete your account. Please try again.',
      );
    }
  }

  /// PATCH `/auth/profile` — updates the personalization profile.
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    final res = await _patch('/auth/profile', update.toJson());
    return UserProfile.fromJson(res['profile'] as Map<String, dynamic>);
  }

  // ── Scan pipeline ─────────────────────────────────────────────────────────────

  /// POST `/api/analyze` — the verdict. Pass a barcode and/or OCR `ingredients`
  /// + `fileUrls`. Requires auth — the API returns 401 for anonymous scan /
  /// analyze (gate before calling; see scan_screen). Returns [AnalyzeNotFound]
  /// when a barcode isn't in Open Food Facts, or [AnalyzeUnsupported] for
  /// non-food.
  Future<AnalyzeOutcome> analyze({
    String? barcode,
    List<String>? ingredients,
    String? scanId,
    String? productName,
    String? brand,
    String? category,
    List<String>? fileUrls,
    String? servingSize,
  }) async {
    final body = <String, dynamic>{};
    if (barcode != null && barcode.isNotEmpty) body['barcode'] = barcode;
    if (ingredients != null) body['ingredients'] = ingredients;
    if (scanId != null) body['scan_id'] = scanId;
    if (productName != null && productName.isNotEmpty) {
      body['product_name'] = productName;
    }
    if (brand != null && brand.isNotEmpty) body['brand'] = brand;
    if (category != null) body['category'] = category;
    if (fileUrls != null) body['file_urls'] = fileUrls;
    if (servingSize != null) body['serving_size'] = servingSize;
    final res = await _post('/api/analyze', body);
    if (res['found'] == false) {
      return AnalyzeNotFound(res['barcode'] as String?);
    }
    if (res['unsupported'] == true) {
      return AnalyzeUnsupported(
        (res['message'] ?? 'This isn’t something you eat or drink.').toString(),
      );
    }
    try {
      return AnalyzeSuccess(AnalysisResult.fromJson(res));
    } on Object catch (_) {
      // Defense in depth: a malformed/unexpected analyze body becomes a clean
      // error the scan screen already handles, never an uncaught crash.
      throw const ApiException(
        'We couldn’t read the analysis for this product. Please try again.',
      );
    }
  }

  /// POST `/api/upload-url` → a presigned S3 PUT target. Requires auth.
  Future<({String uploadUrl, String fileUrl})> createUploadUrl({
    required String filename,
    required String contentType,
  }) async {
    final res = await _post('/api/upload-url', <String, dynamic>{
      'filename': filename,
      'content_type': contentType,
    });
    return (
      uploadUrl: res['upload_url'] as String,
      fileUrl: res['file_url'] as String,
    );
  }

  /// PUT raw image bytes straight to S3 via the presigned URL. Uses a bare Dio
  /// so our Bearer interceptor never touches the S3 request; the Content-Type
  /// must match what [createUploadUrl] was called with.
  Future<void> uploadImage({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final s3 = Dio();
    try {
      await s3.put<void>(
        uploadUrl,
        data: Stream<List<int>>.value(bytes),
        options: Options(
          headers: <String, dynamic>{
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    } finally {
      s3.close();
    }
  }

  /// POST `/api/scans` — fast OCR ingest of uploaded images.
  Future<ScanDraft> createScan({
    required List<String> fileUrls,
    Map<String, dynamic>? identity,
  }) async {
    final body = <String, dynamic>{'file_urls': fileUrls};
    if (identity != null) body['identity'] = identity;
    final res = await _post('/api/scans', body);
    return ScanDraft.fromJson(res);
  }

  // ── User content (Phase 3: history / lists / watches / votes) ────────────────

  /// GET `/api/scans` — the signed-in user's scan history (auth).
  Future<List<ScanHistoryItem>> listScans({
    String sort = '-created_at',
    int limit = 50,
  }) => _getList(
    '/api/scans',
    ScanHistoryItem.fromJson,
    query: <String, dynamic>{'sort': sort, 'limit': limit},
  );

  /// GET `/api/lists` — saved products grouped by list name (auth).
  Future<SavedLists> getSavedLists() => _get('/api/lists', SavedLists.fromJson);

  /// POST `/api/lists` — save a product to a list (auth).
  Future<void> saveProduct(String productSlug, {String listName = 'saved'}) =>
      _post('/api/lists', <String, dynamic>{
        'product_slug': productSlug,
        'list_name': listName,
      });

  /// DELETE `/api/lists` — remove a product from a list (auth).
  Future<void> unsaveProduct(String productSlug, {String listName = 'saved'}) =>
      _delete('/api/lists', <String, dynamic>{
        'product_slug': productSlug,
        'list_name': listName,
      });

  /// GET `/api/watches` — watched products + brands (auth).
  Future<Watches> getWatches() => _get('/api/watches', Watches.fromJson);

  /// POST `/api/watches` — watch a product or brand (auth).
  Future<void> addWatch({String? productSlug, String? brandSlug}) {
    final body = <String, dynamic>{};
    if (productSlug != null) body['product_slug'] = productSlug;
    if (brandSlug != null) body['brand_slug'] = brandSlug;
    return _post('/api/watches', body);
  }

  /// DELETE `/api/watches` — stop watching a product or brand (auth).
  Future<void> removeWatch({String? productSlug, String? brandSlug}) {
    final body = <String, dynamic>{};
    if (productSlug != null) body['product_slug'] = productSlug;
    if (brandSlug != null) body['brand_slug'] = brandSlug;
    return _delete('/api/watches', body);
  }

  /// GET `/api/votes` — community munch/dump split for a product (anonymous OK).
  Future<VoteSummary> getVoteSummary(String productName) => _get(
    '/api/votes',
    VoteSummary.fromJson,
    query: <String, dynamic>{'product_name': productName, 'summary': 'true'},
  );

  /// POST `/api/votes` — cast/change the user's vote on a product (auth).
  Future<void> castVote(String productName, VoteChoice vote) => _post(
    '/api/votes',
    <String, dynamic>{'product_name': productName, 'vote': vote.apiValue},
  );

  /// GET `/api/products/:slug` — canonical product detail. Same verdict fields as
  /// `/api/analyze`, so it parses straight into [AnalysisResult] (anonymous OK).
  Future<AnalysisResult> getProduct(String slug) =>
      _get('/api/products/$slug', AnalysisResult.fromJson);

  // ── Browse (Phase 4: search / brands / categories / ingredients) ─────────────

  /// GET `/api/products` — search/filter. Anonymous-OK (soft `gated`).
  Future<ProductSearchResult> searchProducts({
    String? search,
    String? category,
    String? verdict,
    List<String> dietary = const <String>[],
    int limit = 30,
  }) {
    final query = <String, dynamic>{'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (verdict != null && verdict.isNotEmpty) query['verdict'] = verdict;
    for (final flag in dietary) {
      query[flag] = '1';
    }
    return _get('/api/products', parseProductSearch, query: query);
  }

  /// GET `/api/brands` — brand list (soft `gated`).
  Future<({List<BrandSummary> items, bool gated})> getBrands() => _get(
    '/api/brands',
    (json) => (
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(BrandSummary.fromJson)
              .toList() ??
          const <BrandSummary>[],
      gated: json['gated'] == true,
    ),
  );

  /// GET `/api/brands/:slug` — brand detail (returns `[]` when not found).
  Future<BrandDetail> getBrand(String slug) async {
    final data = await _getDynamic('/api/brands/$slug');
    if (data is Map<String, dynamic>) return BrandDetail.fromJson(data);
    throw const ApiException('Brand not found.');
  }

  /// GET `/api/categories` — category list (soft `gated`).
  Future<({List<CategorySummary> items, bool gated})> getCategories() => _get(
    '/api/categories',
    (json) => (
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CategorySummary.fromJson)
              .toList() ??
          const <CategorySummary>[],
      gated: json['gated'] == true,
    ),
  );

  /// GET `/api/categories/:slug` — category detail (returns `[]` when not found).
  Future<CategoryDetail> getCategory(String slug) async {
    final data = await _getDynamic('/api/categories/$slug');
    if (data is Map<String, dynamic>) return CategoryDetail.fromJson(data);
    throw const ApiException('Category not found.');
  }

  /// GET `/api/ingredients/:slug` — ingredient detail (single-item array, or
  /// `[]` when not found → null).
  Future<IngredientDetail?> getIngredient(String slug) async {
    final data = await _getDynamic('/api/ingredients/$slug');
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return IngredientDetail.fromJson(data.first as Map<String, dynamic>);
    }
    return null;
  }

  // ── Receipt (Phase 5: async job) ─────────────────────────────────────────────

  /// POST `/api/receipt` with an uploaded receipt image (auth). Returns a job id.
  Future<ReceiptStart> startReceiptFromImage(String fileUrl) async {
    final res = await _post('/api/receipt', <String, dynamic>{
      'file_url': fileUrl,
    });
    return ReceiptStart.fromJson(res);
  }

  /// POST `/api/receipt` with a typed pre-shop list (auth). Returns a job id.
  Future<ReceiptStart> startReceiptFromItems(List<String> items) async {
    final res = await _post('/api/receipt', <String, dynamic>{'items': items});
    return ReceiptStart.fromJson(res);
  }

  /// GET `/api/receipt/:jobId` — poll the job (auth).
  Future<ReceiptJob> pollReceipt(String jobId) =>
      _get('/api/receipt/$jobId', ReceiptJob.fromJson);

  // ── Game (Phase 5) ───────────────────────────────────────────────────────────

  /// GET `/api/game/lineup` — a target product + 4 ingredient-list options.
  Future<GameRound> getGameLineup({List<String> exclude = const <String>[]}) =>
      _get(
        '/api/game/lineup',
        GameRound.fromJson,
        query: exclude.isEmpty
            ? null
            : <String, dynamic>{'exclude': exclude.join(',')},
      );

  /// GET `/api/game/leaderboard` — top scores (anonymous).
  Future<List<LeaderboardEntry>> getLeaderboard() => _get(
    '/api/game/leaderboard',
    (json) =>
        (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(LeaderboardEntry.fromJson)
            .toList() ??
        const <LeaderboardEntry>[],
  );

  /// POST `/api/game/score` — record a score (anonymous; names auto-generated).
  Future<ScoreResult> submitScore({required int score, int streak = 0}) async {
    final res = await _post('/api/game/score', <String, dynamic>{
      'score': score,
      'streak': streak,
    });
    return ScoreResult.fromJson(res);
  }

  // ── News (Phase 6: anonymous) ────────────────────────────────────────────────

  /// GET `/api/news` — published posts (anonymous).
  Future<NewsList> getNews({int limit = 20, int offset = 0}) => _get(
    '/api/news',
    parseNewsList,
    query: <String, dynamic>{'limit': limit, 'offset': offset},
  );

  /// GET `/api/news/:slug` — a single post (anonymous).
  Future<NewsPost> getNewsPost(String slug) =>
      _get('/api/news/$slug', NewsPost.fromJson);

  // ── helpers ─────────────────────────────────────────────────────────────────

  /// GET returning the raw decoded body (Map or List) — for endpoints that
  /// return `[]` to mean "not found".
  Future<dynamic> _getDynamic(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      return res.data;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Extract the JWT from an auth response, turning a missing/empty token (a
  /// 2xx with no `token` — backend contract drift) into a clean [ApiException]
  /// the auth screens already handle, rather than an uncaught TypeError.
  String _requireToken(Map<String, dynamic> res) {
    final token = res['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Sign-in failed — please try again.');
    }
    return token;
  }

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return parse(res.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
      return (res.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> _delete(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(path, data: body);
      return res.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return res.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(path, data: body);
      return res.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
