/// No-op implementation for non-web platforms (Android, iOS, desktop).
///
/// Keeps [configureUrlStrategy] callable from shared code without importing
/// any web-only libraries on native targets.
void configureUrlStrategy() {}
