import { FirebaseService } from './FirebaseService';
import { Customer, CreateCustomerData, UpdateCustomerData } from '../../types/Customer';
import { ApiResponse, PaginatedResponse, FilterParams } from '../../types';

export class CustomerService extends FirebaseService {
  private readonly COLLECTION = 'customers';

  /**
   * Create a new customer
   */
  async createCustomer(customerData: CreateCustomerData): Promise<ApiResponse<Customer>> {
    try {
      // Validate required fields
      if (!customerData.name?.trim()) {
        return {
          success: false,
          error: 'Customer name is required',
        };
      }

      if (!customerData.phone?.trim()) {
        return {
          success: false,
          error: 'Phone number is required',
        };
      }

      // Validate company data
      if (customerData.isCompany && !customerData.companyName?.trim()) {
        return {
          success: false,
          error: 'Company name is required when customer is a company',
        };
      }

      // Check if customer with same phone already exists
      const existingCustomer = await this.getDocuments<Customer>(this.COLLECTION, {
        where: [{ field: 'phone', operator: '==', value: customerData.phone }],
        limit: 1,
      });

      if (existingCustomer.success && existingCustomer.data && existingCustomer.data.length > 0) {
        return {
          success: false,
          error: 'Customer with this phone number already exists',
        };
      }

      const result = await this.addDocument<Customer>(this.COLLECTION, {
        ...customerData,
        carIds: [],
        sessionIds: [],
        isActive: true,
      });

      return result;
    } catch (error) {
      console.error('Error creating customer:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create customer',
      };
    }
  }

  /**
   * Update an existing customer
   */
  async updateCustomer(updateData: UpdateCustomerData): Promise<ApiResponse<Customer>> {
    try {
      if (!updateData.id) {
        return {
          success: false,
          error: 'Customer ID is required',
        };
      }

      // Validate company data if being updated
      if (updateData.isCompany !== undefined && updateData.isCompany && !updateData.companyName?.trim()) {
        return {
          success: false,
          error: 'Company name is required when customer is a company',
        };
      }

      const { id, ...dataToUpdate } = updateData;
      return await this.updateDocument<Customer>(this.COLLECTION, id, dataToUpdate);
    } catch (error) {
      console.error('Error updating customer:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update customer',
      };
    }
  }

  /**
   * Get customer by ID
   */
  async getCustomer(id: string): Promise<ApiResponse<Customer>> {
    try {
      if (!id) {
        return {
          success: false,
          error: 'Customer ID is required',
        };
      }

      return await this.getDocument<Customer>(this.COLLECTION, id);
    } catch (error) {
      console.error('Error getting customer:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get customer',
      };
    }
  }

  /**
   * Get customers with filtering and pagination
   */
  async getCustomers(
    filters: FilterParams = {},
    page: number = 1,
    limit: number = 20
  ): Promise<ApiResponse<PaginatedResponse<Customer>>> {
    try {
      const whereConditions: Array<{ field: string; operator: any; value: any }> = [];

      // Add search filter
      if (filters.search) {
        // Note: Firestore doesn't support full-text search, so we'll need to implement this client-side
        // or use Algolia/ElasticSearch for better search capabilities
      }

      // Add active filter
      whereConditions.push({ field: 'isActive', operator: '==', value: true });

      const result = await this.getDocuments<Customer>(this.COLLECTION, {
        where: whereConditions,
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit: limit + 1, // Get one extra to check if there are more pages
      });

      if (!result.success || !result.data) {
        return result as ApiResponse<PaginatedResponse<Customer>>;
      }

      const hasNext = result.data.length > limit;
      const customers = hasNext ? result.data.slice(0, limit) : result.data;
      const total = customers.length; // Note: Getting total count in Firestore requires a separate query

      return {
        success: true,
        data: {
          data: customers,
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
          hasNext,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error('Error getting customers:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get customers',
      };
    }
  }

  /**
   * Search customers by name or phone
   */
  async searchCustomers(query: string): Promise<ApiResponse<Customer[]>> {
    try {
      if (!query.trim()) {
        return {
          success: true,
          data: [],
        };
      }

      // Search by phone number (exact match)
      const phoneResult = await this.getDocuments<Customer>(this.COLLECTION, {
        where: [
          { field: 'phone', operator: '>=', value: query },
          { field: 'phone', operator: '<=', value: query + '\uf8ff' },
          { field: 'isActive', operator: '==', value: true },
        ],
        limit: 10,
      });

      // Search by name (prefix match)
      const nameResult = await this.getDocuments<Customer>(this.COLLECTION, {
        where: [
          { field: 'name', operator: '>=', value: query },
          { field: 'name', operator: '<=', value: query + '\uf8ff' },
          { field: 'isActive', operator: '==', value: true },
        ],
        limit: 10,
      });

      const customers = [
        ...(phoneResult.data || []),
        ...(nameResult.data || []),
      ];

      // Remove duplicates
      const uniqueCustomers = customers.filter(
        (customer, index, self) => 
          index === self.findIndex(c => c.id === customer.id)
      );

      return {
        success: true,
        data: uniqueCustomers,
      };
    } catch (error) {
      console.error('Error searching customers:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to search customers',
      };
    }
  }

  /**
   * Deactivate customer (soft delete)
   */
  async deactivateCustomer(id: string): Promise<ApiResponse<boolean>> {
    try {
      if (!id) {
        return {
          success: false,
          error: 'Customer ID is required',
        };
      }

      const result = await this.updateDocument<Customer>(this.COLLECTION, id, {
        isActive: false,
      });

      return {
        success: result.success,
        data: result.success,
        error: result.error,
      };
    } catch (error) {
      console.error('Error deactivating customer:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to deactivate customer',
      };
    }
  }

  /**
   * Add car ID to customer's car list
   */
  async addCarToCustomer(customerId: string, carId: string): Promise<ApiResponse<boolean>> {
    try {
      if (!customerId || !carId) {
        return {
          success: false,
          error: 'Customer ID and Car ID are required',
        };
      }

      const customerResult = await this.getCustomer(customerId);
      if (!customerResult.success || !customerResult.data) {
        return {
          success: false,
          error: 'Customer not found',
        };
      }

      const carIds = customerResult.data.carIds || [];
      if (!carIds.includes(carId)) {
        carIds.push(carId);
        
        const updateResult = await this.updateDocument<Customer>(this.COLLECTION, customerId, {
          carIds,
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
        message: 'Car already associated with customer',
      };
    } catch (error) {
      console.error('Error adding car to customer:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to add car to customer',
      };
    }
  }

  /**
   * Add session ID to customer's session list
   */
  async addSessionToCustomer(customerId: string, sessionId: string): Promise<ApiResponse<boolean>> {
    try {
      if (!customerId || !sessionId) {
        return {
          success: false,
          error: 'Customer ID and Session ID are required',
        };
      }

      const customerResult = await this.getCustomer(customerId);
      if (!customerResult.success || !customerResult.data) {
        return {
          success: false,
          error: 'Customer not found',
        };
      }

      const sessionIds = customerResult.data.sessionIds || [];
      if (!sessionIds.includes(sessionId)) {
        sessionIds.push(sessionId);
        
        const updateResult = await this.updateDocument<Customer>(this.COLLECTION, customerId, {
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
        message: 'Session already associated with customer',
      };
    } catch (error) {
      console.error('Error adding session to customer:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to add session to customer',
      };
    }
  }
}

export const customerService = new CustomerService();