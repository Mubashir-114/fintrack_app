import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/token_service.dart';

void main() {
  test(
    'a signed-out credential is not reused even if it remains in platform storage',
    () async {
      await TokenService.saveToken('synthetic-old-token');
      expect(await TokenService.getToken(), 'synthetic-old-token');
      await TokenService.removeToken();
      // Model a stale/restored platform value after local sign-out.
      await const FlutterSecureStorage().write(
        key: TokenService.accessTokenKey,
        value: 'synthetic-old-token',
      );
      expect(await TokenService.getToken(), isNull);
      await TokenService.saveToken('synthetic-new-token');
      expect(await TokenService.getToken(), 'synthetic-new-token');
    },
  );
}
