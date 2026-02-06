// Export all providers from a single file
// Usage: import 'package:your_app/data/providers/providers.dart';

export 'user_data_provider.dart';

// Re-export existing providers if they exist
// export 'auth_provider.dart';
// export 'position_provider.dart';

// Common provider aliases for convenience
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/position_repository_firebase.dart';

// Position repository singleton
final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  return PositionRepository.instance;
});
