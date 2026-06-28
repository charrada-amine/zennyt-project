import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

/// Convenience accessor for the generated localizations:
/// `context.l10n.loginTitle` instead of `AppLocalizations.of(context).loginTitle`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
