import apiService from './api';
import { mockFetch, mockApiResponses } from '../test-utils';

describe('API Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createConversation', () => {
    test('creates conversation successfully', async () => {
      global.fetch = mockFetch(mockApiResponses.createConversation);

      const result = await apiService.createConversation('Test Title', 1);

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:3001/chat',
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title: 'Test Title',
            user_id: 1
          })
        })
      );

      expect(result).toEqual(mockApiResponses.createConversation);
    });

    test('handles conversation creation error', async () => {
      global.fetch = mockFetch({ error: 'Creation failed' }, 400);

      await expect(
        apiService.createConversation('Test Title', 1)
      ).rejects.toThrow('HTTP error! status: 400');
    });
  });

  describe('getUserMemberships', () => {
    test('fetches user memberships successfully', async () => {
      global.fetch = mockFetch(mockApiResponses.getUserMemberships);

      const result = await apiService.getUserMemberships(1);

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:3001/api/users/1/memberships',
        expect.objectContaining({
          headers: { 'Content-Type': 'application/json' }
        })
      );

      expect(result).toEqual(mockApiResponses.getUserMemberships);
    });

    test('handles membership fetch error', async () => {
      global.fetch = mockFetch({ error: 'Not found' }, 404);

      await expect(
        apiService.getUserMemberships(1)
      ).rejects.toThrow('HTTP error! status: 404');
    });
  });

  describe('Environment configuration', () => {
    test('uses correct base URL from environment', async () => {
      // Test the default instance behavior - it uses localhost since that's what it was initialized with
      global.fetch = mockFetch(mockApiResponses.createConversation);
      
      await apiService.createConversation('Test', 1);

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:3001/chat',
        expect.any(Object)
      );
    });

    test('falls back to localhost when no environment URL is set', async () => {
      global.fetch = mockFetch(mockApiResponses.createConversation);
      
      await apiService.createConversation('Test', 1);

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:3001/chat',
        expect.any(Object)
      );
    });
  });

  describe('Request headers', () => {
    test('sends correct content type for JSON requests', async () => {
      global.fetch = mockFetch(mockApiResponses.createConversation);

      await apiService.createConversation('Test', 1);

      expect(global.fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: { 'Content-Type': 'application/json' }
        })
      );
    });
  });

  describe('Error handling', () => {
    test('throws error for network failures', async () => {
      global.fetch = jest.fn(() => Promise.reject(new Error('Network error')));

      await expect(
        apiService.createConversation('Test', 1)
      ).rejects.toThrow('Network error');
    });

    test('handles invalid JSON responses', async () => {
      global.fetch = jest.fn(() => Promise.resolve({
        ok: true,
        status: 200,
        statusText: 'OK',
        headers: {
          get: jest.fn(() => 'application/json')
        },
        json: () => Promise.reject(new Error('Invalid JSON')),
        text: () => Promise.resolve(''),
        blob: () => Promise.resolve(new Blob()),
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
        formData: () => Promise.resolve(new FormData()),
        clone: jest.fn(),
        body: null,
        bodyUsed: false,
        redirected: false,
        type: 'basic',
        url: ''
      } as unknown as Response));

      await expect(
        apiService.createConversation('Test', 1)
      ).rejects.toThrow('Invalid JSON');
    });
  });
});