import React from 'react';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders, mockUser, mockApiResponses, mockFetch, waitForNextTick } from '../test-utils';
import Chat from './Chat';

// Mock API service
jest.mock('../services/api', () => ({
  createConversation: jest.fn()
}));

const mockNavigate = jest.fn();
(global as any).mockNavigate = mockNavigate;

describe('Chat Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders initial chat start screen', () => {
    renderWithProviders(<Chat />);
    
    expect(screen.getByText('자기소개하기')).toBeInTheDocument();
    expect(screen.getByText('🎤 음성으로만 대화할 수 있습니다')).toBeInTheDocument();
    expect(screen.getByText('대화 시작하기')).toBeInTheDocument();
  });

  test('shows microphone permission notice', () => {
    renderWithProviders(<Chat />);
    
    expect(screen.getByText('마이크 사용 권한')).toBeInTheDocument();
    expect(screen.getByText(/링글 AI와 음성으로 영어 대화/)).toBeInTheDocument();
  });

  test('starts chat when start button is clicked', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Chat />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText('Hi, I am Benny. How are you today?')).toBeInTheDocument();
    });
  });

  test('shows loading state during chat start', async () => {
    const user = userEvent.setup();
    global.fetch = jest.fn(() => 
      new Promise(resolve => 
        setTimeout(() => resolve({
          ok: true,
          json: () => Promise.resolve(mockApiResponses.createConversation)
        } as Response), 100)
      )
    );
    
    renderWithProviders(<Chat />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    expect(screen.getByText('대화 준비 중...')).toBeInTheDocument();
  });

  test('displays error when chat start fails', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch({ error: 'Membership required' }, 403);
    
    renderWithProviders(<Chat />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText(/대화를 시작할 수 없습니다/)).toBeInTheDocument();
    });
  });

  test('renders chat interface after starting', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Chat />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText('Hi, I am Benny. How are you today?')).toBeInTheDocument();
      expect(screen.getByText('음성으로 대화하기')).toBeInTheDocument();
    });
  });

  test('handles audio recording start', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Chat />);
    
    // Start chat first
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText('음성으로 대화하기')).toBeInTheDocument();
    });

    // Click audio recording button
    const recordButton = screen.getByTitle('음성 녹음으로 대화하기');
    await user.click(recordButton);

    await waitFor(() => {
      expect(screen.getByText('녹음 중...')).toBeInTheDocument();
    });
  });

  test('shows TTS play buttons on messages', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Chat />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      const message = screen.getByText('Hi, I am Benny. How are you today?');
      expect(message).toBeInTheDocument();
      
      // Check for TTS button (speaker icon)
      const ttsButtons = screen.getAllByTitle('음성 재생');
      expect(ttsButtons.length).toBeGreaterThan(0);
    });
  });

  test('handles TTS playback', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Chat />);
    
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      const ttsButton = screen.getByTitle('음성 재생');
      expect(ttsButton).toBeInTheDocument();
    });

    const ttsButton = screen.getByTitle('음성 재생');
    await user.click(ttsButton);

    expect(window.speechSynthesis.speak).toHaveBeenCalled();
  });

  test('navigates back to home', async () => {
    const user = userEvent.setup();
    renderWithProviders(<Chat />);
    
    const backButton = screen.getByText('홈으로 돌아가기');
    await user.click(backButton);

    expect(mockNavigate).toHaveBeenCalledWith('/');
  });

  test('handles audio message sending', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation)
      .mockImplementationOnce(() => Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockApiResponses.createConversation)
      } as Response))
      .mockImplementationOnce(() => Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockApiResponses.audioMessage)
      } as Response));
    
    renderWithProviders(<Chat />);
    
    // Start chat
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText('음성으로 대화하기')).toBeInTheDocument();
    });

    // Start recording
    const recordButton = screen.getByTitle('음성 녹음으로 대화하기');
    await user.click(recordButton);

    await waitFor(() => {
      expect(screen.getByText('정지')).toBeInTheDocument();
    });

    // Stop recording
    const stopButton = screen.getByText('정지');
    await user.click(stopButton);

    await waitFor(() => {
      expect(screen.getByText('음성 전송')).toBeInTheDocument();
    });

    // Send audio
    const sendButton = screen.getByText('음성 전송');
    await user.click(sendButton);

    await waitFor(() => {
      expect(screen.getByText(/음성을 텍스트로 변환 중/)).toBeInTheDocument();
    });
  });

  test('handles audio recording cancellation', async () => {
    const user = userEvent.setup();
    global.fetch = mockFetch(mockApiResponses.createConversation);
    
    renderWithProviders(<Chat />);
    
    // Start chat
    const startButton = screen.getByText('대화 시작하기');
    await user.click(startButton);

    await waitFor(() => {
      expect(screen.getByText('음성으로 대화하기')).toBeInTheDocument();
    });

    // Start recording
    const recordButton = screen.getByTitle('음성 녹음으로 대화하기');
    await user.click(recordButton);

    await waitFor(() => {
      expect(screen.getByText('정지')).toBeInTheDocument();
    });

    // Stop recording to get cancel option
    const stopButton = screen.getByText('정지');
    await user.click(stopButton);

    await waitFor(() => {
      expect(screen.getByText('취소')).toBeInTheDocument();
    });

    // Cancel recording
    const cancelButton = screen.getByText('취소');
    await user.click(cancelButton);

    // Should return to initial recording state
    expect(screen.queryByText('취소')).not.toBeInTheDocument();
  });
});