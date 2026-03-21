abstract class ILocalStorage {
  Future<void> setUserToken(String token);
  Future<String?> getUserToken();
  Future<void> deleteUserToken();

  Future<void> setRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> deleteRefreshToken();

  Future<void> clear();
}
