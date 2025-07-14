import 'dart:io';
import 'lib/services/aws_s3_service.dart';

void main() async {
  // print('Testing S3 upload with user husain credentials...');
  // print('Bucket: ${AWSConfig.bucketName}');
  // print('Region: ${AWSConfig.region}');
  // print('Access Key: ${AWSConfig.accessKeyId}');
  // print('Secret Key: ${AWSConfig.secretAccessKey.substring(0, 8)}...');

  final s3Service = AwsS3Service();

  // Create a simple test file
  final testFile = File('/tmp/test_image.txt');
  await testFile.writeAsString(
    'This is a test file for S3 upload verification',
  );

  // print('\nUploading test file...');
  final result = await s3Service.uploadFile(
    file: testFile,
    objectKey: 'test-uploads/test_${DateTime.now().millisecondsSinceEpoch}.txt',
    compress: false,
  );

  if (result != null) {
    // print('✅ Upload successful!');
    // print('URL: $result');
  } else {
    // print('❌ Upload failed');
  }

  // Clean up
  await testFile.delete();
}
