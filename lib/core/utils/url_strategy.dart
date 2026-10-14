/// Cross-platform entry point for configuring the web URL strategy.
///
/// On the web this delegates to [flutter_web_plugins] to enable clean,
/// path-based URLs (e.g. `/admin` instead of `/#/admin`). On mobile and
/// desktop it resolves to a no-op, so the same call site works everywhere and
/// keeps the door open for Android/iOS builds later.
library;

export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
