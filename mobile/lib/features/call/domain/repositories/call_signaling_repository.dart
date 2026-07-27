/// Contrat (couche domain) pour la signalisation Agora d'un appel :
/// envoi d'invite/accept/reject/end, et écoute des
/// événements entrants correspondants envoyés par le correspondant.
abstract class CallSignalingRepository {
  // ─── Envoi (sortant) ──────────────────────────────────────────────────────

  /// Envoie une invitation d'appel au correspondant.
  void sendCallInvite({
    required String conversationId,
    required String senderId,
    String? counterpartId,
    required String channelName,
    required bool isVideoCall,
  });

  /// Le correspondant accepte l'appel.
  void sendAccept({
    required String conversationId,
    required String senderId,
    String? counterpartId,
  });

  /// Le correspondant rejette l'appel.
  void sendReject({
    required String conversationId,
    required String senderId,
    String? counterpartId,
  });

  /// Termine l'appel.
  void sendEndCall({
    required String conversationId,
    required String senderId,
    String? counterpartId,
  });

  // ─── Écoute (entrant) ─────────────────────────────────────────────────────

  /// Invitation d'appel reçue.
  void onCallInvite(void Function(Map<String, dynamic> data) callback);

  /// Acceptation reçue.
  void onAccept(void Function(Map<String, dynamic> data) callback);

  /// Rejet reçu.
  void onReject(void Function(Map<String, dynamic> data) callback);

  /// Appel terminé.
  void onEndCall(void Function(Map<String, dynamic> data) callback);

  /// Retire tous les callbacks enregistrés.
  void dispose();
}
