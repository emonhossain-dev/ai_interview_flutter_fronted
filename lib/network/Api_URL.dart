class ApiURL{

  // Base Path
  static const String _baseURL = "https://9bf0-103-99-181-58.ngrok-free.app/";


  // account managment
  static const String regitationURL = "${_baseURL}auth/register";
  static const String loginURL = "${_baseURL}auth/login";
  static const String LoginWithGoogleURL = "${_baseURL}auth/google";
  static const String EmailVerifyURL = "${_baseURL}auth/verify-otp";

  // Refresh Token
  static const String RefreshToken = "${_baseURL}auth/refresh-token";


  //password recovery
  static const String email_Send_otp_URL = "${_baseURL}auth/forgot-password";
  static const String otp_verify_URL = "${_baseURL}auth/forgot-password";
  static const String new_password_URL = "${_baseURL}auth/forgot-password";


  // Home
  static const String Profile_URL = "${_baseURL}auth/profile";


  //

}