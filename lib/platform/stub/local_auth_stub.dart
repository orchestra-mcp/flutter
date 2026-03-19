/// No-op local auth stub for web platform.
class LocalAuthStub {
  Future<bool> authenticate() async => false;
  Future<bool> isAvailable() async => false;
}
