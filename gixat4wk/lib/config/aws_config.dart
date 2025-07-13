class AWSConfig {
  // AWS Configuration - Load from credentials file
  static const String accessKeyId = 'AKIA46ALPORVVWYOFQOG';
  static const String secretAccessKey =
      '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';
  static const String region = 'me-central-1';
  static const String bucketName = '4wk-garage-media';

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
