class ApiURL{

  // Base Path
  static const String baseURL = "https://c546-103-99-181-58.ngrok-free.app/";
  static const String WebShokedbaseURL = "wss://c546-103-99-181-58.ngrok-free.app/";

  //chat shoked
  static const String Chat_URL = "wss://c546-103-99-181-58.ngrok-free.app/ws/chat";


  // account managment
  static const String regitationURL = "${baseURL}auth/register";
  static const String loginURL = "${baseURL}auth/login";
  static const String LoginWithGoogleURL = "${baseURL}auth/google";
  static const String EmailVerifyURL = "${baseURL}auth/verify-otp";

  // Refresh Token
  static const String RefreshToken = "${baseURL}auth/refresh-token";


  //password recovery
  static const String email_Send_otp_URL = "${baseURL}auth/forgot-password";
  static const String otp_verify_URL = "${baseURL}auth/forgot-password";
  static const String new_password_URL = "${baseURL}auth/forgot-password";


  // Home
  static const String Profile_URL = "${baseURL}auth/profile";



  //Profile Update
  static const String Profile_Update_URL = "${baseURL}auth/profile/update";
  static const String Profile_Pic_Update_URL = "${baseURL}auth/profile/upload-photo";

  //Resume Update
  static const String uploadResume = "${baseURL}resume/uploadResume";
  static const String ResumeDelete = "${baseURL}resume/deleteResume/";


  //LogOut
  static const String LogOut_URL = "${baseURL}auth/logout-device";





//Update Api


}