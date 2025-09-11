import React from 'react';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders, mockUser, mockApiResponses, mockFetch } from '../test-utils';
import Home from './Home';

// Mock API service
jest.mock('../services/api', () => ({
  getUserMemberships: jest.fn(),
  createConversation: jest.fn()
}));

const mockNavigate = jest.fn();
(global as any).mockNavigate = mockNavigate;

describe('Home Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.fetch = mockFetch(mockApiResponses.getUserMemberships);
  });

  test('renders home page with user logged in', async () => {
    renderWithProviders(<Home />);
    
    expect(screen.getByText('자기소개하기')).toBeInTheDocument();
    expect(screen.getByText('새로운 사람을 만나는 비즈니스 환경에서 본인을 소개해보세요!')).toBeInTheDocument();
    expect(screen.getByText('🎤 음성으로만 대화할 수 있습니다')).toBeInTheDocument();
  });

  test('renders membership information when available', async () => {
    renderWithProviders(<Home />);
    
    await waitFor(() => {
      expect(screen.getByText('멤버십')).toBeInTheDocument();
    });
  });

  test('shows microphone permission notice', () => {
    renderWithProviders(<Home />);
    
    expect(screen.getByText('마이크 사용 권한')).toBeInTheDocument();
    expect(screen.getByText('링글 AI와 음성으로 영어 대화를 나누기 위해서는 마이크 사용 권한이 필요해요.')).toBeInTheDocument();
  });

  test('navigates to chat when start conversation button is clicked', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Home />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/chat');
    });
  });

  test('shows error message when conversation creation fails', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch({ error: 'Membership required' }, 403);
    
    renderWithProviders(<Home />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText(/대화를 시작할 수 없습니다/)).toBeInTheDocument();
    });
  });

  test('renders logout functionality', () => {
    renderWithProviders(<Home />);
    
    expect(screen.getByText('로그아웃')).toBeInTheDocument();
  });

  test('redirects to login when user is not logged in', () => {
    renderWithProviders(<Home />, { initialUser: null });
    
    expect(mockNavigate).toHaveBeenCalledWith('/');
  });

  test('displays loading state during conversation creation', async () => {
    const user = userEvent.setup();
    
    // Mock delayed response
    global.fetch = jest.fn(() => 
      new Promise(resolve => 
        setTimeout(() => resolve({
          ok: true,
          json: () => Promise.resolve(mockApiResponses.createConversation)
        } as Response), 100)
      )
    );
    
    renderWithProviders(<Home />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    expect(screen.getByText('대화 준비 중...')).toBeInTheDocument();
  });

  test('handles membership loading state', () => {
    renderWithProviders(<Home />);
    
    // Initially should show some loading indication or empty state
    expect(screen.getByTestId('membership-section')).toBeInTheDocument();
  });
});