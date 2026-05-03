class ApiURL{

  // Base Path
  static const String _baseURL = "https://project.developeremonhossain.shop/";


  // account managment
  static const String regitationURL = "${_baseURL}auth/register";
  static const String loginURL = "${_baseURL}auth/login";
  static const String LoginWithGoogleURL = "${_baseURL}auth/google";


  //password recovery
  static const String email_Send_otp_URL = "${_baseURL}auth/forgot-password";
  static const String otp_verify_URL = "${_baseURL}auth/forgot-password";
  static const String new_password_URL = "${_baseURL}auth/forgot-password";


  // Home
  static const String Profile_URL = "${_baseURL}auth/profile";


  //

}