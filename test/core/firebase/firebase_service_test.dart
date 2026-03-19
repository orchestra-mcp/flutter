// Firebase services are tested via integration tests with a real Firebase project.
// Unit tests here verify the guard logic (Env.enableFirebase=false → no-op).
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/firebase/firebase_service.dart';

void main() {
  group('FirebaseService', () {
    test('isReady is false before init', () {
      expect(FirebaseService.isReady, isFalse);
    });

    test('init is a no-op when ENABLE_FIREBASE=false (default in test env)', () async {
      // In test env ENABLE_FIREBASE is not set → defaults to false
      // So init() must return without throwing
      await expectLater(FirebaseService.init(), completes);
      // Still not ready (Firebase.initializeApp was not called)
      expect(FirebaseService.isReady, isFalse);
    });
  });
}
