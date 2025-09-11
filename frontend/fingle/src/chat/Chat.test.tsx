import { screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders, mockUser, mockApiResponses } from '../test-utils';
import Chat from './Chat';

// Mock API service
const mockCreateConversation = jest.fn();
jest.mock('../services/api', () => ({
  __esModule: true,
  default: {
    createConversation: (...args: any[]) => mockCreateConversation(...args)
  }
}));

const mockNavigate = jest.fn();
(global as any).mockNavigate = mockNavigate;

// Mock media APIs
const mockMediaStream = {
  getTracks: jest.fn(() => [{ stop: jest.fn() }]),
  getAudioTracks: jest.fn(() => [{ stop: jest.fn() }])
};

// Mock getUserMedia
const mockGetUserMedia = jest.fn();
Object.defineProperty(navigator, 'mediaDevices', {
  value: { getUserMedia: mockGetUserMedia },
  writable: true
});

describe('Chat Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCreateConversation.mockReset();
    mockNavigate.mockReset();
    mockGetUserMedia.mockReset();
    
    // Setup default successful responses
    mockCreateConversation.mockResolvedValue(mockApiResponses.createConversation);
    mockGetUserMedia.mockResolvedValue(mockMediaStream);
  });

  describe('Initial State', () => {
    test('renders initial chat start screen', () => {
      renderWithProviders(<Chat />, { initialUser: mockUser });
      
      expect(screen.getByText('자기소개하기')).toBeInTheDocument();
      expect(screen.getByText('🎤 음성으로만 대화할 수 있습니다')).toBeInTheDocument();
      expect(screen.getByText('대화 시작하기')).toBeInTheDocument();
      expect(screen.getByText('시나리오')).toBeInTheDocument();
    });

    test('displays microphone permission notice', () => {
      renderWithProviders(<Chat />, { initialUser: mockUser });
      
      expect(screen.getByText('마이크 사용 권한')).toBeInTheDocument();
      expect(screen.getByText('링글 AI와 음성으로 영어 대화를 나누기 위해서는 마이크 사용 권한이 필요해요.')).toBeInTheDocument();
    });

    test('shows scenario information', () => {
      renderWithProviders(<Chat />, { initialUser: mockUser });
      
      expect(screen.getByText('새로운 사람을 만나는 비즈니스 환경에서 본인을 소개해보세요!')).toBeInTheDocument();
    });
  });

  describe('Authentication', () => {

    test('allows chat start when user is logged in', () => {
      renderWithProviders(<Chat />, { initialUser: mockUser });
      
      const startButton = screen.getByText('대화 시작하기');
      expect(startButton).toBeEnabled();
    });
  });

  describe('Conversation Management', () => {


    test('handles conversation creation error', async () => {
      const user = userEvent.setup();
      
      mockCreateConversation.mockRejectedValue(new Error('Failed to create conversation'));
      
      renderWithProviders(<Chat />, { initialUser: mockUser });
      
      const startButton = screen.getByText('대화 시작하기');
      await user.click(startButton);
      
      await waitFor(() => {
        expect(screen.getByText('대화를 시작할 수 없습니다. 다시 시도해주세요.')).toBeInTheDocument();
      });
    });

  });

  describe('Accessibility', () => {
    test('has proper heading structure', () => {
      renderWithProviders(<Chat />, { initialUser: mockUser });
      
      const mainHeading = screen.getByRole('heading', { level: 1 });
      expect(mainHeading).toBeInTheDocument();
      expect(mainHeading).toHaveTextContent('자기소개하기');
    });
  });
});