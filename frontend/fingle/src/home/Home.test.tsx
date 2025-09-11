import { screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders, mockUser, mockApiResponses } from '../test-utils';
import Home from './Home';

// Mock API service with proper implementation
const mockGetUserMemberships = jest.fn();
const mockCreateConversation = jest.fn();

jest.mock('../services/api', () => ({
  __esModule: true,
  default: {
    getUserMemberships: (...args: any[]) => mockGetUserMemberships(...args),
    createConversation: (...args: any[]) => mockCreateConversation(...args)
  }
}));

const mockNavigate = jest.fn();
(global as any).mockNavigate = mockNavigate;

describe('Home Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockGetUserMemberships.mockReset();
    mockCreateConversation.mockReset();
    mockNavigate.mockReset();
    
    // Setup default successful API responses
    mockGetUserMemberships.mockResolvedValue([{
      id: 1,
      user_id: 1,
      membership_type: 'premium',
      is_active: true,
      status: 'active',
      start_date: new Date().toISOString(),
      end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    }]);
    
    mockCreateConversation.mockResolvedValue(mockApiResponses.createConversation);
  });

  describe('Authentication States', () => {
    test('shows login form when user is not logged in', async () => {
      renderWithProviders(<Home />, { initialUser: null });
      
      // Check for multiple disabled buttons with the same text
      const disabledButtons = screen.getAllByText('로그인 후 이용 가능');
      expect(disabledButtons.length).toBeGreaterThan(0);
      
      // Verify all are disabled
      disabledButtons.forEach(button => {
        expect(button).toBeDisabled();
      });
      
      // Look for login form elements with correct placeholder text
      expect(screen.getByPlaceholderText('이메일 주소')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('비밀번호')).toBeInTheDocument();
    });

    test('shows main content when user is logged in', async () => {
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      expect(screen.getByText('최고의 튜터와 함께 영어를 마스터하세요')).toBeInTheDocument();
      expect(screen.getByText('대화 시작하기')).toBeInTheDocument();
      expect(screen.getByText('로그아웃')).toBeInTheDocument();
    });

    test('displays user greeting when logged in', async () => {
      const testUser = { ...mockUser, name: 'John Doe' };
      renderWithProviders(<Home />, { initialUser: testUser });
      
      await waitFor(() => {
        expect(screen.getByText(/안녕하세요.*님!/)).toBeInTheDocument();
      });
    });
  });

  describe('Membership Management', () => {

    test('shows loading state while fetching membership', async () => {
      // Delay the membership API response
      let resolveMembership: (value: any) => void;
      mockGetUserMemberships.mockImplementation(() => 
        new Promise(resolve => {
          resolveMembership = resolve;
        })
      );
      
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      expect(screen.getByText('로딩 중...')).toBeInTheDocument();
      
      // Resolve the promise
      act(() => {
        resolveMembership([]);
      });
      
      await waitFor(() => {
        expect(screen.queryByText('로딩 중...')).not.toBeInTheDocument();
      });
    });

    test('handles membership fetch error gracefully', async () => {
      mockGetUserMemberships.mockRejectedValue(new Error('Network error'));
      
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      await waitFor(() => {
        expect(screen.getByText('멤버십 없음')).toBeInTheDocument();
      });
    });

  });

  describe('Chat Navigation', () => {
    test('navigates to chat when start button is clicked (logged in)', async () => {
      const user = userEvent.setup();
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      await waitFor(() => {
        expect(screen.getByText('대화 시작하기')).toBeInTheDocument();
      });
      
      const startButton = screen.getByText('대화 시작하기');
      await user.click(startButton);
      
      await waitFor(() => {
        expect(mockNavigate).toHaveBeenCalledWith('/chat');
      });
    });

    test('start button is disabled when not logged in', async () => {
      renderWithProviders(<Home />, { initialUser: null });
      
      // There are multiple buttons with this text, get the main one
      const startButtons = screen.getAllByText('로그인 후 이용 가능');
      const mainStartButton = startButtons[0]; // Usually the first one is the main CTA
      expect(mainStartButton).toBeDisabled();
    });

  });

  describe('User Interface Elements', () => {
    test('displays main heading and description', () => {
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      expect(screen.getByText('최고의 튜터와 함께 영어를 마스터하세요')).toBeInTheDocument();
      expect(screen.getByText(/아이비리그 튜터와 함께하는 1:1 화상 영어 수업/)).toBeInTheDocument();
    });

    test('shows pricing plans section', () => {
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      expect(screen.getByText('링글 플랜')).toBeInTheDocument();
      expect(screen.getByText('베이직')).toBeInTheDocument();
      expect(screen.getByText('프리미엄')).toBeInTheDocument();
      expect(screen.getByText('가장 인기 있는')).toBeInTheDocument();
    });

    test('displays logout functionality for logged in users', () => {
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      expect(screen.getByText('로그아웃')).toBeInTheDocument();
    });

    test('shows additional info button for logged in users', () => {
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      expect(screen.getByText('더 알아보기')).toBeInTheDocument();
    });
  });

  describe('Login Functionality', () => {
    test('login form handles user input', async () => {
      const user = userEvent.setup();
      renderWithProviders(<Home />, { initialUser: null });
      
      const emailInput = screen.getByPlaceholderText('이메일 주소');
      const passwordInput = screen.getByPlaceholderText('비밀번호');
      
      await user.type(emailInput, 'test@example.com');
      await user.type(passwordInput, 'password123');
      
      expect(emailInput).toHaveValue('test@example.com');
      expect(passwordInput).toHaveValue('password123');
    });

  });

  describe('Error Handling', () => {
    test('displays authentication errors', () => {
      const errorMessage = '로그인에 실패했습니다.';
      
      renderWithProviders(<Home />, { 
        initialUser: null,
        authProps: { error: errorMessage }
      });
      
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
    });

    test('error can be dismissed', async () => {
      const user = userEvent.setup();
      const mockClearError = jest.fn();
      
      renderWithProviders(<Home />, { 
        initialUser: null,
        authProps: { 
          error: '로그인에 실패했습니다.',
          clearError: mockClearError
        }
      });
      
      const dismissButton = screen.getByRole('button', { name: /dismiss/i });
      await user.click(dismissButton);
      
      expect(mockClearError).toHaveBeenCalled();
    });
  });

  describe('Accessibility', () => {

    test('buttons have appropriate labels and states', () => {
      renderWithProviders(<Home />, { initialUser: mockUser });
      
      const startButton = screen.getByRole('button', { name: '대화 시작하기' });
      const logoutButton = screen.getByRole('button', { name: '로그아웃' });
      const learnMoreButton = screen.getByRole('button', { name: '더 알아보기' });
      
      expect(startButton).toBeEnabled();
      expect(logoutButton).toBeEnabled();
      expect(learnMoreButton).toBeEnabled();
    });
  });
});