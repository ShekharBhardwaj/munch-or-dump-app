/// Route names + paths — a single source of truth importable anywhere without
/// pulling in the router (which depends on every screen, so screens can't import
/// it back without a cycle).
abstract final class Routes {
  static const String home = 'home';
  static const String scan = 'scan';
  static const String result = 'result';
  static const String login = 'login';
  static const String verify = 'verify';
  static const String forgot = 'forgot';
  static const String onboarding = 'onboarding';
  static const String account = 'account';

  static const String homePath = '/';
  static const String scanPath = '/scan';
  static const String resultPath = '/result';
  static const String loginPath = '/login';
  static const String verifyPath = '/verify';
  static const String forgotPath = '/forgot';
  static const String onboardingPath = '/onboarding';
  static const String accountPath = '/account';
}
