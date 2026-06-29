/// Route names + paths — a single source of truth importable anywhere without
/// pulling in the router (which depends on every screen, so screens can't import
/// it back without a cycle).
abstract final class Routes {
  static const String home = 'home';
  static const String scan = 'scan';
  static const String result = 'result';
  static const String product = 'product';
  static const String history = 'history';
  static const String watchlist = 'watchlist';
  static const String search = 'search';
  static const String brands = 'brands';
  static const String brand = 'brand';
  static const String categories = 'categories';
  static const String category = 'category';
  static const String ingredient = 'ingredient';
  static const String receipt = 'receipt';
  static const String game = 'game';
  static const String compare = 'compare';
  static const String news = 'news';
  static const String newsPost = 'newsPost';
  static const String login = 'login';
  static const String verify = 'verify';
  static const String forgot = 'forgot';
  static const String onboarding = 'onboarding';
  static const String account = 'account';

  static const String homePath = '/';
  static const String scanPath = '/scan';
  static const String resultPath = '/result';
  static const String productPath = '/product/:slug';
  static const String historyPath = '/history';
  static const String watchlistPath = '/watchlist';
  static const String searchPath = '/search';
  static const String brandsPath = '/brands';
  static const String brandPath = '/brand/:slug';
  static const String categoriesPath = '/categories';
  static const String categoryPath = '/category/:slug';
  static const String ingredientPath = '/ingredient/:slug';
  static const String receiptPath = '/receipt';
  static const String gamePath = '/game';
  static const String comparePath = '/compare';
  static const String newsPath = '/news';
  static const String newsPostPath = '/news/:slug';
  static const String loginPath = '/login';
  static const String verifyPath = '/verify';
  static const String forgotPath = '/forgot';
  static const String onboardingPath = '/onboarding';
  static const String accountPath = '/account';
}
