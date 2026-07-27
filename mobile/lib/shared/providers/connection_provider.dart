import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/injection.dart';
import '../../core/network/network_info.dart';
import 'internet_provider.dart';

final networkInfoProvider = Provider<NetworkInfo>((ref) => sl<NetworkInfo>());

/// Conservé pour compatibilité : redirige simplement vers internetProvider
/// au lieu de repoller toutes les 30s séparément.
final connectionStatusProvider = Provider<bool>((ref) => ref.watch(internetProvider));
