import 'package:flutter_dotenv/flutter_dotenv.dart';

class AWSConfig {
  // AWS Configuration - Load from environment variables
  static String get accessKeyId => dotenv.env['AWS_ACCESS_KEY_ID'] ?? '';
  static String get secretAccessKey => dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '';
  static String get region => dotenv.env['AWS_REGION'] ?? 'me-central-1';
  static String get bucketName => dotenv.env['AWS_BUCKET_NAME'] ?? '4wk-garage-media';

  // S3 Configuration
  static const String imagesFolder = 'images';
  static const String videosFolder = 'videos';
  static const String documentsFolder = 'documents';
  static const String profilePhotosFolder = 'profile-photos';
  static const String carImagesFolder = 'car-images';
  static const String inspectionPhotosFolder = 'inspection-photos';
  static const String jobOrderAttachmentsFolder = 'job-order-attachments';

  // File size limits (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50MB

  // Supported file types
  static const List<String> supportedImageTypes = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  static const List<String> supportedVideoTypes = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
  ];

  static const List<String> supportedDocumentTypes = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.xlsx',
    '.xls',
  ];

  // Get public URL for S3 object
  static String getPublicUrl(String key) {
    return 'https://$bucketName.s3.$region.amazonaws.com/$key';
  }

  // Extract key from S3 URL
  static String extractKeyFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.join('/');
  }
}
