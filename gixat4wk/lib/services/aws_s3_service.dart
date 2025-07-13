import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../config/aws_config.dart';

class AwsS3Service {
  static const String _awsService = 's3';
  static const String _awsRequestType = 'aws4_request';
  static const String _algorithm = 'AWS4-HMAC-SHA256';

  Future<File?> compressImage(File file, {int quality = 85}) async {
    try {
      final String fileExtension = path.extension(file.path).toLowerCase();
      
      if (!AWSConfig.supportedImageTypes.contains(fileExtension)) {
        return file;
      }

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return file;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return file;
    }
  }

  Future<File?> compressVideo(File file) async {
    try {
      final String fileExtension = path.extension(file.path).toLowerCase();
      
      if (!AWSConfig.supportedVideoTypes.contains(fileExtension)) {
        return file;
      }

      final fileSize = await file.length();
      if (fileSize <= AWSConfig.maxVideoSize) {
        return file;
      }

      debugPrint('Video compression not implemented yet');
      return file;
    } catch (e) {
      debugPrint('Video compression failed: $e');
      return file;
    }
  }

  Future<String?> uploadFile({
    required File file,
    required String objectKey,
    String? contentType,
    bool compress = true,
  }) async {
    try {
      File fileToUpload = file;
      
      if (compress) {
        final String fileExtension = path.extension(file.path).toLowerCase();
        if (AWSConfig.supportedImageTypes.contains(fileExtension)) {
          final compressedFile = await compressImage(file);
          if (compressedFile != null) {
            fileToUpload = compressedFile;
          }
        } else if (AWSConfig.supportedVideoTypes.contains(fileExtension)) {
          final compressedFile = await compressVideo(file);
          if (compressedFile != null) {
            fileToUpload = compressedFile;
          }
        }
      }

      final String mimeType = contentType ?? lookupMimeType(fileToUpload.path) ?? 'application/octet-stream';
      final List<int> fileBytes = await fileToUpload.readAsBytes();
      
      final String url = 'https://${AWSConfig.bucketName}.s3.${AWSConfig.region}.amazonaws.com/$objectKey';
      final DateTime now = DateTime.now().toUtc();
      final String dateStamp = _formatDate(now);
      final String amzDate = _formatDateTime(now);
      
      final Map<String, String> headers = {
        'Host': '${AWSConfig.bucketName}.s3.${AWSConfig.region}.amazonaws.com',
        'Content-Type': mimeType,
        'X-Amz-Date': amzDate,
        'X-Amz-Content-Sha256': _sha256Hash(fileBytes),
      };

      if (AWSConfig.accessKeyId.isNotEmpty && AWSConfig.secretAccessKey.isNotEmpty) {
        final String authorization = _generateAuthorizationHeader(
          method: 'PUT',
          uri: '/$objectKey',
          headers: headers,
          payload: fileBytes,
          accessKey: AWSConfig.accessKeyId,
          secretKey: AWSConfig.secretAccessKey,
          region: AWSConfig.region,
          service: _awsService,
          dateStamp: dateStamp,
          amzDate: amzDate,
        );
        headers['Authorization'] = authorization;
      }

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: fileBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (compress && fileToUpload.path != file.path) {
          try {
            await fileToUpload.delete();
          } catch (e) {
            debugPrint('Failed to delete compressed file: $e');
          }
        }
        return AWSConfig.getPublicUrl(objectKey);
      } else {
        debugPrint('S3 upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String objectKey) async {
    try {
      final String url = 'https://${AWSConfig.bucketName}.s3.${AWSConfig.region}.amazonaws.com/$objectKey';
      final DateTime now = DateTime.now().toUtc();
      final String dateStamp = _formatDate(now);
      final String amzDate = _formatDateTime(now);
      
      final Map<String, String> headers = {
        'Host': '${AWSConfig.bucketName}.s3.${AWSConfig.region}.amazonaws.com',
        'X-Amz-Date': amzDate,
        'X-Amz-Content-Sha256': _sha256Hash(<int>[]),
      };

      if (AWSConfig.accessKeyId.isNotEmpty && AWSConfig.secretAccessKey.isNotEmpty) {
        final String authorization = _generateAuthorizationHeader(
          method: 'DELETE',
          uri: '/$objectKey',
          headers: headers,
          payload: <int>[],
          accessKey: AWSConfig.accessKeyId,
          secretKey: AWSConfig.secretAccessKey,
          region: AWSConfig.region,
          service: _awsService,
          dateStamp: dateStamp,
          amzDate: amzDate,
        );
        headers['Authorization'] = authorization;
      }

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  String _generateAuthorizationHeader({
    required String method,
    required String uri,
    required Map<String, String> headers,
    required List<int> payload,
    required String accessKey,
    required String secretKey,
    required String region,
    required String service,
    required String dateStamp,
    required String amzDate,
  }) {
    final String credentialScope = '$dateStamp/$region/$service/$_awsRequestType';
    final String canonicalRequest = _createCanonicalRequest(method, uri, headers, payload);
    final String stringToSign = _createStringToSign(amzDate, credentialScope, canonicalRequest);
    final String signature = _calculateSignature(secretKey, dateStamp, region, service, stringToSign);
    
    return '$_algorithm Credential=$accessKey/$credentialScope, SignedHeaders=${_getSignedHeaders(headers)}, Signature=$signature';
  }

  String _createCanonicalRequest(String method, String uri, Map<String, String> headers, List<int> payload) {
    final String canonicalUri = uri;
    const String canonicalQueryString = '';
    final String canonicalHeaders = _createCanonicalHeaders(headers);
    final String signedHeaders = _getSignedHeaders(headers);
    final String payloadHash = _sha256Hash(payload);

    return '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
  }

  String _createCanonicalHeaders(Map<String, String> headers) {
    final sortedHeaders = Map.fromEntries(
      headers.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()))
    );
    
    return '${sortedHeaders.entries.map((entry) => '${entry.key.toLowerCase()}:${entry.value.trim()}').join('\n')}\n';
  }

  String _getSignedHeaders(Map<String, String> headers) {
    final sortedKeys = headers.keys.map((key) => key.toLowerCase()).toList()..sort();
    return sortedKeys.join(';');
  }

  String _createStringToSign(String amzDate, String credentialScope, String canonicalRequest) {
    return '$_algorithm\n$amzDate\n$credentialScope\n${_sha256Hash(utf8.encode(canonicalRequest))}';
  }

  String _calculateSignature(String secretKey, String dateStamp, String region, String service, String stringToSign) {
    final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, service);
    final kSigning = _hmacSha256(kService, _awsRequestType);
    final signature = _hmacSha256(kSigning, stringToSign);
    
    return signature.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hmacSha256(List<int> key, String message) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(message)).bytes;
  }

  String _sha256Hash(List<int> data) {
    return sha256.convert(data).toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z';
  }
}
