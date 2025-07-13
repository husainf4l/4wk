import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'lib/config/aws_config.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  print('Testing environment variables...');
  print('Access Key ID: ${AWSConfig.accessKeyId}');
  print('Secret Key: ${AWSConfig.secretAccessKey.isNotEmpty ? 'LOADED' : 'EMPTY'}');
  print('Region: ${AWSConfig.region}');
  print('Bucket: ${AWSConfig.bucketName}');
  
  if (AWSConfig.accessKeyId.isNotEmpty && AWSConfig.secretAccessKey.isNotEmpty) {
    print('✅ Environment variables loaded successfully!');
  } else {
    print('❌ Environment variables not loaded properly!');
  }
}
