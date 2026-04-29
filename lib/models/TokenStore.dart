class TokenStore {
  static String? accessToken;

  static void setToken(String token) {
    accessToken = token;
  }

  static void clear() {
    accessToken = null;
  }
}