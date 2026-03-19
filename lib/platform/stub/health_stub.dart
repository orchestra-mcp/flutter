/// No-op health stub for web platform.
class HealthStub {
  Future<bool> isAvailable() async => false;
  Future<dynamic> getSteps() async => null;
  Future<dynamic> getHeartRate() async => null;
}
