// ✅ utils/image_helper.dart — নতুন file বানাও
import '../network/Api_URL.dart';

class ImageHelper {
  static String getProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return ''; // placeholder handle করবে
    }

    // ✅ Already full URL হলে (Google profile pic)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // ✅ Local server path হলে baseURL যোগ করো
    return '${ApiURL.baseURL}$imagePath';
  }
}