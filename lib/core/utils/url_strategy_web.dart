import 'package:flutter_web_plugins/url_strategy.dart';

/// Web implementation: use clean path-based URLs (no `#` fragment).
void configureUrlStrategy() {
  usePathUrlStrategy();
}
