import React from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { AuthContext } from './contexts/AuthContext';

// Mock user data for testing
export const mockUser = {
  id: 1,
  email: 'test@example.com',
  username: 'testuser',
  name: 'Test User',
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString()
};

// Mock membership data
export const mockMembership = {
  id: 1,
  user_id: 1,
  membership_type: 'premium',
  is_active: true,
  start_date: new Date().toISOString(),
  end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days from now
};

// Mock conversation data
export const mockConversation = {
  id: 1,
  user_id: 1,
  title: 'Test Conversation',
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString()
};

// Mock message data
export const mockMessages = [
  {
    id: '1',
    role: 'assistant' as const,
    content: 'Hi, I am Benny. How are you today?',
    timestamp: new Date()
  },
  {
    id: '2', 
    role: 'user' as const,
    content: 'Hello, I am doing well!',
    timestamp: new Date()
  }
];

// Custom render function that includes providers
interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  initialUser?: typeof mockUser | null;
  route?: string;
  authProps?: Partial<any>;
}

export function renderWithProviders(
  ui: React.ReactElement,
  {
    initialUser = mockUser,
    route = '/',
    authProps = {},
    ...renderOptions
  }: CustomRenderOptions = {}
) {
  // Mock AuthContext value with proper methods
  const mockAuthValue = {
    user: initialUser,
    isLoggedIn: !!initialUser,
    isLoading: false,
    login: jest.fn().mockImplementation(async () => Promise.resolve()),
    logout: jest.fn(),
    error: null,
    clearError: jest.fn(),
    ...authProps
  };

  function Wrapper({ children }: { children: React.ReactNode }) {
    // Set initial route
    if (route !== '/') {
      window.history.pushState({}, 'Test page', route);
    }

    return (
      <div data-testid="test-wrapper">
        <AuthContext.Provider value={mockAuthValue}>
          {children}
        </AuthContext.Provider>
      </div>
    );
  }

  return { 
    ...render(ui, { wrapper: Wrapper, ...renderOptions }),
    mockAuthValue
  };
}

// Mock API responses
export const mockApiResponses = {
  createConversation: mockConversation,
  getUserMemberships: [mockMembership],
  audioMessage: {
    success: true,
    transcribed_text: 'Hello, this is a test message.',
    ai_response: 'Thank you for your test message!',
    user_message_id: 'msg-1',
    ai_message_id: 'msg-2'
  }
};

// Mock fetch function
export const mockFetch = (response: any, status = 200) => {
  return jest.fn(() =>
    Promise.resolve({
      ok: status >= 200 && status < 300,
      status,
      statusText: status >= 200 && status < 300 ? 'OK' : 'Error',
      redirected: false,
      type: 'basic' as ResponseType,
      url: '',
      headers: {
        get: jest.fn((key: string) => {
          if (key === 'content-type') return 'application/json';
          return null;
        })
      },
      json: () => Promise.resolve(response),
      text: () => Promise.resolve(JSON.stringify(response)),
      blob: () => Promise.resolve(new Blob()),
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
      formData: () => Promise.resolve(new FormData()),
      clone: jest.fn(),
      body: {
        getReader: () => ({
          read: () => Promise.resolve({ done: true, value: new Uint8Array() }),
          releaseLock: () => {}
        })
      },
      bodyUsed: false
    } as unknown as Response)
  );
};

// Helper to wait for async operations
export const waitForNextTick = () => new Promise(resolve => setTimeout(resolve, 0));

export * from '@testing-library/react';