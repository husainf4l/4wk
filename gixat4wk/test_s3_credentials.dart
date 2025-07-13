import 'dart:io';
import 'lib/services/aws_s3_service.dart';
import 'lib/config/aws_config.dart';

void main() async {
  print('Testing S3 credentials...');
  print('Access Key: ${AWSConfig.accessKeyId}');
  print('Region: ${AWSConfig.region}');
  print('Bucket: ${AWSConfig.bucketName}');

  final s3Service = AwsS3Service();

  // Create a test file
  final testFile = File('test_image.txt');
  await testFile.writeAsString(
    'This is a test upload to verify S3 credentials',
  );

  try {
    print('Uploading test file...');
    final uploadUrl = await s3Service.uploadFile(
      file: testFile,
      objectKey: 'test/credentials_test.txt',
      compress: false,
    );

    if (uploadUrl != null) {
      print('✅ Upload successful! URL: $uploadUrl');

      // Test deletion
      print('Testing deletion...');
      final deleted = await s3Service.deleteFile('test/credentials_test.txt');
      if (deleted) {
        print('✅ Deletion successful!');
      } else {
        print('❌ Deletion failed');
      }
    } else {
      print('❌ Upload failed');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Clean up test file
    if (await testFile.exists()) {
      await testFile.delete();
    }
  }
}
