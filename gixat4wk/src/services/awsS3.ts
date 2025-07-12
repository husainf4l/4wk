import AWS from 'aws-sdk';
import Config from 'react-native-config';
import RNFS from 'react-native-fs';
import { ApiResponse } from '../types';

AWS.config.update({
  accessKeyId: Config.AWS_ACCESS_KEY_ID,
  secretAccessKey: Config.AWS_SECRET_ACCESS_KEY,
  region: Config.AWS_REGION,
});

const s3 = new AWS.S3();

export interface UploadProgress {
  loaded: number;
  total: number;
  progress: number;
}

export interface UploadResult {
  url: string;
  key: string;
  size: number;
}

export interface MediaFile {
  uri: string;
  name: string;
  type: 'image' | 'video';
  size?: number;
}

export class AWSS3Service {
  private bucketName: string;
  private maxFileSize: number = 50 * 1024 * 1024; // 50MB
  private allowedImageTypes: string[] = ['jpg', 'jpeg', 'png', 'webp'];
  private allowedVideoTypes: string[] = ['mp4', 'mov', 'avi'];

  constructor() {
    this.bucketName = Config.AWS_S3_BUCKET || '4wk-garage-media';
  }

  /**
   * Validate file before upload
   */
  private validateFile(file: MediaFile): ApiResponse<boolean> {
    try {
      // Check file URI
      if (!file.uri) {
        return {
          success: false,
          error: 'File URI is required',
        };
      }

      // Check file name
      if (!file.name) {
        return {
          success: false,
          error: 'File name is required',
        };
      }

      // Get file extension
      const extension = file.name.toLowerCase().split('.').pop();
      if (!extension) {
        return {
          success: false,
          error: 'File must have a valid extension',
        };
      }

      // Check file type
      if (file.type === 'image' && !this.allowedImageTypes.includes(extension)) {
        return {
          success: false,
          error: `Image files must be one of: ${this.allowedImageTypes.join(', ')}`,
        };
      }

      if (file.type === 'video' && !this.allowedVideoTypes.includes(extension)) {
        return {
          success: false,
          error: `Video files must be one of: ${this.allowedVideoTypes.join(', ')}`,
        };
      }

      // Check file size
      if (file.size && file.size > this.maxFileSize) {
        return {
          success: false,
          error: `File size must be less than ${this.maxFileSize / 1024 / 1024}MB`,
        };
      }

      return {
        success: true,
        data: true,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'File validation failed',
      };
    }
  }

  /**
   * Generate S3 key for file
   */
  private generateKey(
    customerId: string,
    sessionId: string,
    type: 'initial' | 'inspection' | 'test-drive',
    subType: 'images' | 'videos' | '',
    fileName: string
  ): string {
    const timestamp = Date.now();
    const sanitizedFileName = fileName.replace(/[^a-zA-Z0-9.-]/g, '_');
    
    if (subType) {
      return `customers/${customerId}/sessions/${sessionId}/${type}/${subType}/${timestamp}_${sanitizedFileName}`;
    }
    
    return `customers/${customerId}/sessions/${sessionId}/${type}/${timestamp}_${sanitizedFileName}`;
  }

  /**
   * Upload a single file to S3
   */
  async uploadFile(
    file: MediaFile,
    customerId: string,
    sessionId: string,
    type: 'initial' | 'inspection' | 'test-drive',
    onProgress?: (progress: UploadProgress) => void
  ): Promise<ApiResponse<UploadResult>> {
    try {
      // Validate file
      const validation = this.validateFile(file);
      if (!validation.success) {
        return validation as ApiResponse<UploadResult>;
      }

      // Read file content
      const fileContent = await RNFS.readFile(file.uri, 'base64');
      const buffer = Buffer.from(fileContent, 'base64');

      // Generate S3 key
      const subType = file.type === 'image' ? 'images' : 'videos';
      const key = this.generateKey(customerId, sessionId, type, subType, file.name);

      // Determine content type
      const extension = file.name.toLowerCase().split('.').pop();
      let contentType = 'application/octet-stream';
      
      if (file.type === 'image') {
        contentType = `image/${extension === 'jpg' ? 'jpeg' : extension}`;
      } else if (file.type === 'video') {
        contentType = `video/${extension}`;
      }

      const uploadParams = {
        Bucket: this.bucketName,
        Key: key,
        Body: buffer,
        ContentType: contentType,
        ACL: 'private',
        Metadata: {
          customerId,
          sessionId,
          type,
          originalName: file.name,
          uploadedAt: new Date().toISOString(),
        },
      };

      const managedUpload = s3.upload(uploadParams);

      if (onProgress) {
        managedUpload.on('httpUploadProgress', (progress) => {
          const progressData: UploadProgress = {
            loaded: progress.loaded,
            total: progress.total,
            progress: (progress.loaded / progress.total) * 100,
          };
          onProgress(progressData);
        });
      }

      const result = await managedUpload.promise();
      
      return {
        success: true,
        data: {
          url: result.Location,
          key: result.Key,
          size: buffer.length,
        },
        message: 'File uploaded successfully',
      };
    } catch (error) {
      console.error('Error uploading file to S3:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to upload file',
      };
    }
  }

  /**
   * Upload multiple files to S3
   */
  async uploadFiles(
    files: MediaFile[],
    customerId: string,
    sessionId: string,
    type: 'initial' | 'inspection' | 'test-drive',
    onProgress?: (fileIndex: number, progress: UploadProgress) => void
  ): Promise<ApiResponse<UploadResult[]>> {
    try {
      if (!files || files.length === 0) {
        return {
          success: false,
          error: 'No files provided for upload',
        };
      }

      const results: UploadResult[] = [];
      const errors: string[] = [];

      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        const uploadResult = await this.uploadFile(
          file,
          customerId,
          sessionId,
          type,
          (progress) => {
            if (onProgress) {
              onProgress(i, progress);
            }
          }
        );

        if (uploadResult.success && uploadResult.data) {
          results.push(uploadResult.data);
        } else {
          errors.push(`${file.name}: ${uploadResult.error}`);
        }
      }

      if (errors.length > 0 && results.length === 0) {
        return {
          success: false,
          error: `All uploads failed: ${errors.join(', ')}`,
        };
      }

      return {
        success: true,
        data: results,
        message: errors.length > 0 
          ? `${results.length} files uploaded successfully, ${errors.length} failed`
          : 'All files uploaded successfully',
      };
    } catch (error) {
      console.error('Error uploading files to S3:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to upload files',
      };
    }
  }

  /**
   * Get a signed URL for accessing a private file
   */

  async getSignedUrl(key: string, expiresIn: number = 3600): Promise<ApiResponse<string>> {
    try {
      if (!key) {
        return {
          success: false,
          error: 'File key is required',
        };
      }

      const params = {
        Bucket: this.bucketName,
        Key: key,
        Expires: expiresIn,
      };

      const url = s3.getSignedUrl('getObject', params);
      
      return {
        success: true,
        data: url,
        message: 'Signed URL generated successfully',
      };
    } catch (error) {
      console.error('Error generating signed URL:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to generate signed URL',
      };
    }
  }

  /**
   * Delete a file from S3
   */
  async deleteFile(key: string): Promise<ApiResponse<boolean>> {
    try {
      if (!key) {
        return {
          success: false,
          error: 'File key is required',
        };
      }

      const params = {
        Bucket: this.bucketName,
        Key: key,
      };

      await s3.deleteObject(params).promise();
      
      return {
        success: true,
        data: true,
        message: 'File deleted successfully',
      };
    } catch (error) {
      console.error('Error deleting file from S3:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete file',
      };
    }
  }

  /**
   * Delete multiple files from S3
   */
  async deleteFiles(keys: string[]): Promise<ApiResponse<boolean>> {
    try {
      if (!keys || keys.length === 0) {
        return {
          success: false,
          error: 'No file keys provided',
        };
      }

      const params = {
        Bucket: this.bucketName,
        Delete: {
          Objects: keys.map(key => ({ Key: key })),
          Quiet: false,
        },
      };

      const result = await s3.deleteObjects(params).promise();
      
      const deletedCount = result.Deleted?.length || 0;
      const errorCount = result.Errors?.length || 0;

      if (errorCount > 0) {
        return {
          success: false,
          error: `Failed to delete ${errorCount} files. ${deletedCount} files deleted successfully.`,
        };
      }

      return {
        success: true,
        data: true,
        message: `${deletedCount} files deleted successfully`,
      };
    } catch (error) {
      console.error('Error deleting files from S3:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete files',
      };
    }
  }

  /**
   * List files for a specific session
   */
  async listSessionFiles(customerId: string, sessionId: string): Promise<ApiResponse<string[]>> {
    try {
      if (!customerId || !sessionId) {
        return {
          success: false,
          error: 'Customer ID and Session ID are required',
        };
      }

      const params = {
        Bucket: this.bucketName,
        Prefix: `customers/${customerId}/sessions/${sessionId}/`,
      };

      const result = await s3.listObjectsV2(params).promise();
      const keys = result.Contents?.map(obj => obj.Key || '').filter(key => key) || [];
      
      return {
        success: true,
        data: keys,
        message: `Found ${keys.length} files`,
      };
    } catch (error) {
      console.error('Error listing files from S3:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to list files',
      };
    }
  }

  /**
   * Get file metadata
   */
  async getFileMetadata(key: string): Promise<ApiResponse<any>> {
    try {
      if (!key) {
        return {
          success: false,
          error: 'File key is required',
        };
      }

      const params = {
        Bucket: this.bucketName,
        Key: key,
      };

      const result = await s3.headObject(params).promise();
      
      return {
        success: true,
        data: {
          size: result.ContentLength,
          contentType: result.ContentType,
          lastModified: result.LastModified,
          metadata: result.Metadata,
        },
        message: 'File metadata retrieved successfully',
      };
    } catch (error) {
      console.error('Error getting file metadata:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get file metadata',
      };
    }
  }

  /**
   * Check if bucket exists and is accessible
   */
  async checkBucketAccess(): Promise<ApiResponse<boolean>> {
    try {
      await s3.headBucket({ Bucket: this.bucketName }).promise();
      
      return {
        success: true,
        data: true,
        message: 'Bucket is accessible',
      };
    } catch (error) {
      console.error('Error checking bucket access:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Bucket is not accessible',
      };
    }
  }
}

export const awsS3Service = new AWSS3Service();