import { FirebaseService } from './FirebaseService';
import { Car, CreateCarData, UpdateCarData } from '../../types/Car';
import { ApiResponse, PaginatedResponse, FilterParams } from '../../types';

export class CarService extends FirebaseService {
  private readonly COLLECTION = 'cars';

  /**
   * Create a new car
   */
  async createCar(carData: CreateCarData): Promise<ApiResponse<Car>> {
    try {
      // Validate required fields
      if (!carData.customerId?.trim()) {
        return {
          success: false,
          error: 'Customer ID is required',
        };
      }

      if (!carData.make?.trim()) {
        return {
          success: false,
          error: 'Car make is required',
        };
      }

      if (!carData.model?.trim()) {
        return {
          success: false,
          error: 'Car model is required',
        };
      }

      if (!carData.plateNumber?.trim()) {
        return {
          success: false,
          error: 'Plate number is required',
        };
      }

      if (!carData.year || carData.year < 1900 || carData.year > new Date().getFullYear() + 1) {
        return {
          success: false,
          error: 'Please enter a valid year',
        };
      }

      // Check if car with same plate number already exists
      const existingCar = await this.getDocuments<Car>(this.COLLECTION, {
        where: [{ field: 'plateNumber', operator: '==', value: carData.plateNumber.toUpperCase() }],
        limit: 1,
      });

      if (existingCar.success && existingCar.data && existingCar.data.length > 0) {
        return {
          success: false,
          error: 'Car with this plate number already exists',
        };
      }

      const result = await this.addDocument<Car>(this.COLLECTION, {
        ...carData,
        plateNumber: carData.plateNumber.toUpperCase(),
        vin: carData.vin?.toUpperCase(),
        sessionIds: [],
        isActive: true,
      });

      return result;
    } catch (error) {
      console.error('Error creating car:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create car',
      };
    }
  }

  /**
   * Update an existing car
   */
  async updateCar(updateData: UpdateCarData): Promise<ApiResponse<Car>> {
    try {
      if (!updateData.id) {
        return {
          success: false,
          error: 'Car ID is required',
        };
      }

      const { id, ...dataToUpdate } = updateData;
      
      // Normalize plate number and VIN
      if (dataToUpdate.plateNumber) {
        dataToUpdate.plateNumber = dataToUpdate.plateNumber.toUpperCase();
      }
      if (dataToUpdate.vin) {
        dataToUpdate.vin = dataToUpdate.vin.toUpperCase();
      }

      return await this.updateDocument<Car>(this.COLLECTION, id, dataToUpdate);
    } catch (error) {
      console.error('Error updating car:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update car',
      };
    }
  }

  /**
   * Get car by ID
   */
  async getCar(id: string): Promise<ApiResponse<Car>> {
    try {
      if (!id) {
        return {
          success: false,
          error: 'Car ID is required',
        };
      }

      return await this.getDocument<Car>(this.COLLECTION, id);
    } catch (error) {
      console.error('Error getting car:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get car',
      };
    }
  }

  /**
   * Get cars for a specific customer
   */
  async getCustomerCars(customerId: string): Promise<ApiResponse<Car[]>> {
    try {
      if (!customerId) {
        return {
          success: false,
          error: 'Customer ID is required',
        };
      }

      return await this.getDocuments<Car>(this.COLLECTION, {
        where: [
          { field: 'customerId', operator: '==', value: customerId },
          { field: 'isActive', operator: '==', value: true },
        ],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });
    } catch (error) {
      console.error('Error getting customer cars:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get customer cars',
      };
    }
  }

  /**
   * Get cars with filtering and pagination
   */
  async getCars(
    filters: FilterParams = {},
    page: number = 1,
    limit: number = 20
  ): Promise<ApiResponse<PaginatedResponse<Car>>> {
    try {
      const whereConditions: Array<{ field: string; operator: any; value: any }> = [];

      // Add customer filter
      if (filters.customerId) {
        whereConditions.push({ field: 'customerId', operator: '==', value: filters.customerId });
      }

      // Add active filter
      whereConditions.push({ field: 'isActive', operator: '==', value: true });

      const result = await this.getDocuments<Car>(this.COLLECTION, {
        where: whereConditions,
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit: limit + 1, // Get one extra to check if there are more pages
      });

      if (!result.success || !result.data) {
        return result as ApiResponse<PaginatedResponse<Car>>;
      }

      const hasNext = result.data.length > limit;
      const cars = hasNext ? result.data.slice(0, limit) : result.data;
      const total = cars.length; // Note: Getting total count in Firestore requires a separate query

      return {
        success: true,
        data: {
          data: cars,
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
          hasNext,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error('Error getting cars:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get cars',
      };
    }
  }

  /**
   * Search cars by plate number, make, or model
   */
  async searchCars(query: string, customerId?: string): Promise<ApiResponse<Car[]>> {
    try {
      if (!query.trim()) {
        return {
          success: true,
          data: [],
        };
      }

      const whereConditions: Array<{ field: string; operator: any; value: any }> = [
        { field: 'isActive', operator: '==', value: true },
      ];

      if (customerId) {
        whereConditions.push({ field: 'customerId', operator: '==', value: customerId });
      }

      // Search by plate number (exact match)
      const plateQuery = query.toUpperCase();
      const plateResult = await this.getDocuments<Car>(this.COLLECTION, {
        where: [
          ...whereConditions,
          { field: 'plateNumber', operator: '>=', value: plateQuery },
          { field: 'plateNumber', operator: '<=', value: plateQuery + '\uf8ff' },
        ],
        limit: 10,
      });

      // Search by make (prefix match)
      const makeResult = await this.getDocuments<Car>(this.COLLECTION, {
        where: [
          ...whereConditions,
          { field: 'make', operator: '>=', value: query },
          { field: 'make', operator: '<=', value: query + '\uf8ff' },
        ],
        limit: 10,
      });

      // Search by model (prefix match)
      const modelResult = await this.getDocuments<Car>(this.COLLECTION, {
        where: [
          ...whereConditions,
          { field: 'model', operator: '>=', value: query },
          { field: 'model', operator: '<=', value: query + '\uf8ff' },
        ],
        limit: 10,
      });

      const cars = [
        ...(plateResult.data || []),
        ...(makeResult.data || []),
        ...(modelResult.data || []),
      ];

      // Remove duplicates
      const uniqueCars = cars.filter(
        (car, index, self) => 
          index === self.findIndex(c => c.id === car.id)
      );

      return {
        success: true,
        data: uniqueCars,
      };
    } catch (error) {
      console.error('Error searching cars:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to search cars',
      };
    }
  }

  /**
   * Deactivate car (soft delete)
   */
  async deactivateCar(id: string): Promise<ApiResponse<boolean>> {
    try {
      if (!id) {
        return {
          success: false,
          error: 'Car ID is required',
        };
      }

      const result = await this.updateDocument<Car>(this.COLLECTION, id, {
        isActive: false,
      });

      return {
        success: result.success,
        data: result.success,
        error: result.error,
      };
    } catch (error) {
      console.error('Error deactivating car:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to deactivate car',
      };
    }
  }

  /**
   * Add session ID to car's session list
   */
  async addSessionToCar(carId: string, sessionId: string): Promise<ApiResponse<boolean>> {
    try {
      if (!carId || !sessionId) {
        return {
          success: false,
          error: 'Car ID and Session ID are required',
        };
      }

      const carResult = await this.getCar(carId);
      if (!carResult.success || !carResult.data) {
        return {
          success: false,
          error: 'Car not found',
        };
      }

      const sessionIds = carResult.data.sessionIds || [];
      if (!sessionIds.includes(sessionId)) {
        sessionIds.push(sessionId);
        
        const updateResult = await this.updateDocument<Car>(this.COLLECTION, carId, {
          sessionIds,
        });

        return {
          success: updateResult.success,
          data: updateResult.success,
          error: updateResult.error,
        };
      }

      return {
        success: true,
        data: true,
        message: 'Session already associated with car',
      };
    } catch (error) {
      console.error('Error adding session to car:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to add session to car',
      };
    }
  }

  /**
   * Update car mileage
   */
  async updateMileage(carId: string, mileage: number): Promise<ApiResponse<boolean>> {
    try {
      if (!carId) {
        return {
          success: false,
          error: 'Car ID is required',
        };
      }

      if (mileage < 0) {
        return {
          success: false,
          error: 'Mileage cannot be negative',
        };
      }

      const result = await this.updateDocument<Car>(this.COLLECTION, carId, {
        currentMileage: mileage,
        lastServiceDate: new Date(),
      });

      return {
        success: result.success,
        data: result.success,
        error: result.error,
      };
    } catch (error) {
      console.error('Error updating car mileage:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update car mileage',
      };
    }
  }

  /**
   * Get cars due for service
   */
  async getCarsForService(daysBefore: number = 30): Promise<ApiResponse<Car[]>> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() + daysBefore);

      return await this.getDocuments<Car>(this.COLLECTION, {
        where: [
          { field: 'isActive', operator: '==', value: true },
          { field: 'nextServiceDue', operator: '<=', value: cutoffDate },
        ],
        orderBy: { field: 'nextServiceDue', direction: 'asc' },
      });
    } catch (error) {
      console.error('Error getting cars for service:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get cars for service',
      };
    }
  }
}

export const carService = new CarService();