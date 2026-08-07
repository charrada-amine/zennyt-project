import 'package:dio/dio.dart';

import '../../shared/app_mode.dart';

/// Intercepteur **dev uniquement** (Phase A — avant la fusion du contexte Identity).
///
/// Le backend `dev` n'a pas de vraie authentification : il lit le header
/// `X-Dev-User: <uuid>` pour savoir « qui agit » (voir `DevSecurityConfig` côté
/// backend). On simule donc le candidat ou le recruteur en fonction du drapeau
/// global [appIsRecruiter] — basculer le mode dans l'UI change l'identité envoyée
/// à chaque requête, sans login.
///
/// Les UUID sont ceux semés par `DevDataSeeder.java` : les offres / l'évaluation /
/// le fit-score de démo leur sont rattachés.
///
/// En Phase B (Identity fusionné), on retire cet intercepteur et on s'appuie
/// uniquement sur [AuthInterceptor] (Bearer JWT).
class DevIdentityInterceptor extends Interceptor {
  /// Recruteur de démo (propriétaire des 3 offres ACTIVE + de l'évaluation).
  static const recruiterId = '11111111-1111-1111-1111-111111111111';

  /// Candidat de démo (parcourt les offres, swipe, postule, passe le test).
  static const candidateId = '22222222-2222-2222-2222-222222222222';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Si un appel a déjà fixé l'identité explicitement (flux multi-acteurs en
    // dev, ex. offre d'opportunité recruteur→candidat), on ne l'écrase pas.
    options.headers.putIfAbsent(
      'X-Dev-User',
      () => appIsRecruiter.value ? recruiterId : candidateId,
    );
    handler.next(options);
  }
}
