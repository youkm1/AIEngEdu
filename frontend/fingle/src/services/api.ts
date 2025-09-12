// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: string[];
}

export interface User {
  id: number;
  email: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  user: User;
  token: string;
}

export interface Conversation {
  id: number;
  title: string;
  user_id: number;
  created_at: string;
  updated_at: string;
}

export interface Message {
  id: number;
  conversation_id: number;
  role: 'user' | 'assistant' | 'system';
  content: string;
  created_at: string;
}

export interface Membership {
  id: number;
  user_id: number;
  membership_type: 'basic' | 'premium';
  membership_level: string;
  available_features: string[];
  start_date: string;
  end_date: string;
  price: number;
  status: 'active' | 'expired';
  is_active: boolean;
}

export interface PaymentPrepareResponse {
  clientKey: string;
  orderId: string;
  orderName: string;
  amount: number;
  customerName: string;
  customerEmail: string;
  successUrl: string;
  failUrl: string;
}

export interface PaymentConfirmResponse {
  payment: {
    paymentKey: string;
    orderId: string;
    status: string;
    totalAmount: number;
  };
  membership: Membership;
}

export interface Coupon {
  id: number;
  name: string;
  total_uses: number;
  used_count: number;
  remaining_uses: number;
  expires_at: string;
  status: 'active' | 'expired' | 'exhausted' | 'inactive';
  usable: boolean;
  created_at: string;
  updated_at: string;
}

// Request Types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  name: string;
  password: string;
}

export interface CreateUserRequest {
  email: string;
  name: string;
}

export interface CreateConversationRequest {
  title: string;
  user_id: number;
}

export interface SendMessageRequest {
  conversation_id: number;
  message: string;
  user_id: number;
}

export interface CreateMembershipRequest {
  membership_type: 'basic' | 'premium';
  start_date?: string;
  price?: number;
}

export interface PaymentPrepareRequest {
  user_id: number;
  membership_type: 'basic' | 'premium';
}

export interface PaymentConfirmRequest {
  user_id: number;
  paymentKey: string;
  orderId: string;
  amount: number;
}

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:3000';

class ApiService {
  private baseURL: string;

  constructor() {
    this.baseURL = API_BASE_URL;
    console.log('API Base URL:', this.baseURL); // Debug log
  }

  private async request<T>(endpoint: string, options: Omit<RequestInit, 'body'> & { body?: any } = {}): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('API Request:', url, options); // Debug log
    
    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    };

    if (config.body && typeof config.body === 'object' && !(config.body instanceof FormData)) {
      config.body = JSON.stringify(config.body);
    }

    try {
      const response = await fetch(url, config);
      console.log('API Response:', response.status, response.statusText); // Debug log
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ message: 'Network error' }));
        console.error('API Error Response:', errorData); // Debug log
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
      }

      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        const data = await response.json();
        console.log('API Success Response:', data); // Debug log
        return data;
      }
      
      return await response.text() as unknown as T;
    } catch (error) {
      console.error('API Request failed:', error);
      throw error;
    }
  }

  // Auth methods
  async login(email: string, password: string): Promise<ApiResponse<AuthResponse>> {
    return this.request<ApiResponse<AuthResponse>>('/api/auth/login', {
      method: 'POST',
      body: { email, password },
    });
  }


  async getCurrentUser(): Promise<User | null> {
    const token = localStorage.getItem('authToken');
    if (!token) return null;

    try {
      return await this.request<User>('/api/auth/me', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
    } catch (error) {
      localStorage.removeItem('authToken');
      return null;
    }
  }

  // User methods
  async createUser(userData: CreateUserRequest): Promise<ApiResponse<User>> {
    return this.request<ApiResponse<User>>('/api/users', {
      method: 'POST',
      body: userData,
    });
  }

  async getUser(userId: number): Promise<User> {
    return this.request<User>(`/api/users/${userId}`);
  }

  // Chat methods
  async createConversation(title: string, userId: number): Promise<Conversation> {
    return this.request<Conversation>('/chat', {
      method: 'POST',
      body: { title, user_id: userId },
    });
  }

  async sendMessage(conversationId: number, message: string, userId: number): Promise<void> {
    return this.request<void>('/chat/message', {
      method: 'POST',
      body: {
        conversation_id: conversationId,
        message: message,
        user_id: userId,
      },
    });
  }

  // Membership methods
  async getUserMemberships(userId: number): Promise<Membership[]> {
    return this.request<Membership[]>(`/api/users/${userId}/memberships`);
  }

  async createMembership(userId: number, membershipData: CreateMembershipRequest): Promise<ApiResponse<Membership>> {
    return this.request<ApiResponse<Membership>>(`/api/users/${userId}/memberships`, {
      method: 'POST',
      body: membershipData,
    });
  }

  // Payment methods
  async preparePayment(userId: number, membershipType: 'basic' | 'premium'): Promise<ApiResponse<PaymentPrepareResponse>> {
    return this.request<ApiResponse<PaymentPrepareResponse>>('/api/payments/prepare', {
      method: 'POST',
      body: {
        user_id: userId,
        membership_type: membershipType,
      },
    });
  }

  async confirmPayment(userId: number, paymentKey: string, orderId: string, amount: number): Promise<ApiResponse<PaymentConfirmResponse>> {
    return this.request<ApiResponse<PaymentConfirmResponse>>('/api/payments/confirm', {
      method: 'POST',
      body: {
        user_id: userId,
        paymentKey,
        orderId,
        amount,
      },
    });
  }

  // Coupon methods
  async getUserCoupons(userId: number): Promise<Coupon[]> {
    return this.request<Coupon[]>(`/api/users/${userId}/coupons`);
  }

  async getAvailableCoupons(userId: number): Promise<{ success: boolean; data: Coupon[]; total_available: number; has_available: boolean }> {
    return this.request(`/api/users/${userId}/coupons/available`);
  }
}

export default new ApiService();