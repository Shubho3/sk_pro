import 'package:flutter/material.dart';

/// The Indore Chai Company logo, in the two forms the app uses.
///
/// Both are cut from `assets/logo_no_bg.png` by `tool/gen_logo_assets.py`:
///
/// * [AppLogo.full] — the complete lockup (cup mark plus the wordmark). Use it
///   where the brand is the subject of the screen and there is room to read it:
///   login, loading, setup.
/// * [AppLogo.mark] — the cup on its own. Use it anywhere under ~96px, where
///   the wordmark would be an illegible smudge: app bars, nav rails, list rows.
class AppLogo extends StatelessWidget {
  const AppLogo.full({super.key, this.height = 120}) : _asset = _fullAsset;

  const AppLogo.mark({super.key, this.height = 32}) : _asset = _markAsset;

  static const _fullAsset = 'assets/logo_full.png';
  static const _markAsset = 'assets/logo_mark.png';

  final String _asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Indore Chai Company',
    );
  }
}
