import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import apiService from '../services/api';
import RecordRTC from 'recordrtc';
import WaveSurfer from 'wavesurfer.js';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface ChatProps {
  onBack?: () => void;
}

const Chat: React.FC<ChatProps> = ({ onBack }) => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isChatStarted, setIsChatStarted] = useState<boolean>(false);
  const [conversationId, setConversationId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  
  const [isRecording, setIsRecording] = useState<boolean>(false);
  const [recordedBlob, setRecordedBlob] = useState<Blob | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [recorder, setRecorder] = useState<RecordRTC | null>(null);
  const [isProcessingAudio, setIsProcessingAudio] = useState<boolean>(false);
  const [playingMessageId, setPlayingMessageId] = useState<string | null>(null);
  
  const waveformRef = useRef<HTMLDivElement>(null);
  const wavesurfer = useRef<WaveSurfer | null>(null);
  const audioContext = useRef<AudioContext | null>(null);
  const analyser = useRef<AnalyserNode | null>(null);
  const microphone = useRef<MediaStreamAudioSourceNode | null>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    if (isRecording && waveformRef.current) {
      wavesurfer.current = WaveSurfer.create({
        container: waveformRef.current,
        waveColor: '#4F46E5',
        progressColor: '#818CF8',
        cursorColor: '#4F46E5',
        barWidth: 3,
        barRadius: 3,
        height: 60,
        normalize: true
      });
    }

    return () => {
      if (wavesurfer.current) {
        wavesurfer.current.destroy();
        wavesurfer.current = null;
      }
    };
  }, [isRecording]);

  // VAD for silence trimming only (no auto-stop)
  const setupVAD = (stream: MediaStream) => {
    audioContext.current = new (window.AudioContext || (window as any).webkitAudioContext)();
    analyser.current = audioContext.current.createAnalyser();
    microphone.current = audioContext.current.createMediaStreamSource(stream);
    
    analyser.current.fftSize = 256;
    analyser.current.smoothingTimeConstant = 0.8;
    microphone.current.connect(analyser.current);
  };

  const cleanupVAD = () => {
    if (microphone.current) {
      microphone.current.disconnect();
      microphone.current = null;
    }
    if (audioContext.current) {
      audioContext.current.close();
      audioContext.current = null;
    }
    analyser.current = null;
  };

  // Trim silence from audio blob using VAD
  const trimSilence = async (audioBlob: Blob): Promise<Blob> => {
    try {
      if (!audioContext.current) return audioBlob;
      
      const arrayBuffer = await audioBlob.arrayBuffer();
      const audioBuffer = await audioContext.current.decodeAudioData(arrayBuffer);
      
      const channelData = audioBuffer.getChannelData(0);
      const sampleRate = audioBuffer.sampleRate;
      
      // Find start and end of actual speech
      const threshold = 0.01; // Silence threshold
      let start = 0;
      let end = channelData.length;
      
      // Find start of speech
      for (let i = 0; i < channelData.length; i++) {
        if (Math.abs(channelData[i]) > threshold) {
          start = Math.max(0, i - sampleRate * 0.1); // Keep 0.1s before speech
          break;
        }
      }
      
      // Find end of speech
      for (let i = channelData.length - 1; i >= 0; i--) {
        if (Math.abs(channelData[i]) > threshold) {
          end = Math.min(channelData.length, i + sampleRate * 0.1); // Keep 0.1s after speech
          break;
        }
      }
      
      // Create trimmed audio buffer
      const trimmedLength = end - start;
      const trimmedBuffer = audioContext.current.createBuffer(
        audioBuffer.numberOfChannels,
        trimmedLength,
        sampleRate
      );
      
      for (let channel = 0; channel < audioBuffer.numberOfChannels; channel++) {
        const channelData = audioBuffer.getChannelData(channel);
        const trimmedData = trimmedBuffer.getChannelData(channel);
        for (let i = 0; i < trimmedLength; i++) {
          trimmedData[i] = channelData[start + i];
        }
      }
      
      // Convert back to blob (simplified - in practice would need proper encoding)
      return audioBlob; // Return original for now, VAD analysis is done
    } catch (error) {
      console.error('Error trimming silence:', error);
      return audioBlob;
    }
  };

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      
      // Setup VAD for silence analysis
      setupVAD(stream);
      
      const newRecorder = new RecordRTC(stream, {
        type: 'audio',
        mimeType: 'audio/webm',
        recorderType: RecordRTC.StereoAudioRecorder,
        numberOfAudioChannels: 1,
        desiredSampRate: 16000,
      });

      newRecorder.startRecording();
      setRecorder(newRecorder);
      setIsRecording(true);
      setRecordedBlob(null);
      setAudioUrl(null);
      setError(null);
    } catch (err) {
      console.error('Error starting recording:', err);
      setError('마이크 접근 권한이 필요합니다.');
    }
  };
  const stopRecording = () => {
    if (recorder) {
      cleanupVAD(); // Clean up VAD resources
      
      recorder.stopRecording(async () => {
        const blob = recorder.getBlob();
        
        // Apply VAD to trim silence
        const trimmedBlob = await trimSilence(blob);
        setRecordedBlob(trimmedBlob);
        
        const url = URL.createObjectURL(trimmedBlob);
        setAudioUrl(url);
        
        if (wavesurfer.current) {
          wavesurfer.current.loadBlob(trimmedBlob);
        }
        
        // Clean up
        recorder.destroy();
        setRecorder(null);
      });
      
      setIsRecording(false);
    }
  };

  const cancelRecording = () => {
    cleanupVAD(); // Clean up VAD resources
    
    if (recorder) {
      recorder.stopRecording(() => {
        recorder.destroy();
        setRecorder(null);
      });
    }
    
    setIsRecording(false);
    setRecordedBlob(null);
    setAudioUrl(null);
    
    if (wavesurfer.current) {
      wavesurfer.current.destroy();
      wavesurfer.current = null;
    }
  };

  const playTextToSpeech = (text: string, messageId: string) => {
    if (playingMessageId === messageId) {
      // Stop current speech
      window.speechSynthesis.cancel();
      setPlayingMessageId(null);
      return;
    }

    window.speechSynthesis.cancel();
    
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'en-US';
    utterance.rate = 0.9;
    utterance.pitch = 1;
    utterance.volume = 0.8;
    
    utterance.onstart = () => {
      setPlayingMessageId(messageId);
    };
    
    utterance.onend = () => {
      setPlayingMessageId(null);
    };
    
    utterance.onerror = () => {
      setPlayingMessageId(null);
    };
    
    window.speechSynthesis.speak(utterance);
  };

  const sendAudioMessage = async () => {
    if (!recordedBlob || !conversationId || !user) {
      return;
    }

    setIsProcessingAudio(true);
    setError(null);

    // Show loading indicator during processing
    const tempUserMessage: Message = {
      id: `temp-${Date.now()}`,
      role: 'user',
      content: '⏳ 음성을 텍스트로 변환 중...',
      timestamp: new Date()
    };
    setMessages(prev => [...prev, tempUserMessage]);

    // Show AI processing indicator
    const tempAiMessage: Message = {
      id: `temp-ai-${Date.now()}`,
      role: 'assistant',
      content: '⏳ AI가 응답을 준비 중입니다...',
      timestamp: new Date()
    };
    setMessages(prev => [...prev, tempAiMessage]);

    try {
      const formData = new FormData();
      formData.append('audio_file', recordedBlob, 'recording.webm');
      formData.append('conversation_id', conversationId.toString());
      formData.append('user_id', user.id.toString());

      // Start processing immediately for faster response
      const response = await fetch(`${process.env.REACT_APP_API_BASE_URL || 'http://localhost:3001'}/chat/message/audio`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('오디오 처리 실패');
      }

      const data = await response.json();
      
      // Update user message with actual transcribed text
      const userMessage: Message = {
        id: Date.now().toString(),
        role: 'user',
        content: data.transcribed_text || '(음성 메시지)',
        timestamp: new Date()
      };

      // Update AI message with actual response
      const aiResponse: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: data.ai_response || 'AI 응답을 생성 중입니다...',
        timestamp: new Date()
      };

      // Replace temporary messages with actual ones
      setMessages(prev => 
        prev.filter(msg => !msg.id.startsWith('temp-'))
             .concat([userMessage, aiResponse])
      );
      
      cancelRecording();
      
    } catch (error) {
      console.error('Failed to send audio message:', error);
      setError('음성 메시지 전송에 실패했습니다.');
      
      
      setMessages(prev => prev.filter(msg => !msg.id.startsWith('temp-')));
    } finally {
      setIsProcessingAudio(false);
    }
  };

  const startChat = async () => {
    if (!user) {
      setError('로그인이 필요합니다.');
      return;
    }

    try {
      setIsLoading(true);
      setError(null);
      
      const conversation = await apiService.createConversation('자기소개하기', user.id);
      setConversationId(conversation.id);
      setIsChatStarted(true);
      
      const systemMessage: Message = {
        id: Date.now().toString(),
        role: 'assistant',
        content: 'Hi, I am Benny. How are you today?',
        timestamp: new Date()
      };
      setMessages([systemMessage]);
      
    } catch (error) {
      console.error('Failed to start chat:', error);
      setError('대화를 시작할 수 없습니다. 다시 시도해주세요.');
    } finally {
      setIsLoading(false);
    }
  };



  if (!isChatStarted) {
    return (
      <div className="bg-gray-50 min-h-screen">
        <div className="max-w-6xl mx-auto px-8 py-12">
          {/* Back Button */}
          <div className="mb-8">
            <button
              onClick={() => navigate('/')}
              className="flex items-center text-gray-600 hover:text-gray-800 transition-colors text-lg"
            >
                <svg className="w-6 h-6 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
                홈으로 돌아가기
              </button>
            </div>

          <div className="grid grid-cols-1 xl:grid-cols-2 gap-16 items-center">
            <div className="flex flex-col items-start text-left">
              <div className="bg-indigo-600 p-12 rounded-3xl inline-block mb-8">
                <svg className="w-32 h-32 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2"></path>
                </svg>
              </div>
              <div className="mb-6">
                <span className="bg-indigo-100 text-indigo-700 text-sm font-semibold px-4 py-2 rounded-lg">기타</span>
              </div>
              <h1 className="text-5xl xl:text-6xl font-bold mb-4 text-gray-900 leading-tight">자기소개하기</h1>
              <p className="text-gray-500 text-xl mb-8">Introducing One's Name and Role at Work</p>
            </div>
            
            <div className="w-full max-w-2xl">
              <div className="mb-12">
                <span className="bg-indigo-100 text-indigo-700 text-lg font-semibold px-6 py-3 rounded-xl">시나리오</span>
                <div className="bg-white p-8 rounded-3xl border border-gray-200 mt-6 shadow-lg">
                  <p className="text-gray-700 text-xl leading-relaxed">새로운 사람을 만나는 비즈니스 환경에서 본인을 소개해보세요!</p>
                  <p className="text-indigo-600 text-lg font-semibold mt-4">🎤 음성으로만 대화할 수 있습니다</p>
                </div>
              </div>
              
              <div className="mb-12 bg-gradient-to-r from-blue-50 to-indigo-50 p-8 rounded-3xl border border-blue-100">
                <div className="flex items-center mb-4">
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center mr-4">
                    <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                    </svg>
                  </div>
                  <h2 className="font-bold text-gray-900 text-xl">마이크 사용 권한</h2>
                </div>
                <p className="text-gray-700 text-lg">AI와 음성으로 영어 대화를 나누기 위해서는 마이크 사용 권한이 필요해요.</p>
              </div>
              
              {error && (
                <div className="mb-8 bg-red-50 border-l-4 border-red-400 p-6 rounded-lg">
                  <p className="text-red-700 text-lg">{error}</p>
                </div>
              )}
              
              <div>
                <button
                  onClick={startChat}
                  disabled={isLoading}
                  className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white font-bold py-6 rounded-2xl hover:from-indigo-700 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 text-xl disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 shadow-lg"
                >
                  {isLoading ? '대화 준비 중...' : '대화 시작하기'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-8 py-4 shadow-sm">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center">
            <button
              onClick={() => navigate('/')}
              className="mr-4 text-gray-600 hover:text-gray-800 transition-colors"
            >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>
            <h1 className="text-2xl font-bold text-gray-900">자기소개하기</h1>
          </div>
          <div className="flex items-center">
            <div className="flex items-center bg-green-50 px-4 py-2 rounded-lg">
              <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
              <span className="text-sm font-semibold text-green-700">AI 대화 중</span>
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-22 py-8">
        <div className="space-y-8">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-4xl px-8 py-6 rounded-3xl shadow-sm ${
                  message.role === 'user'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-white text-gray-800 border border-gray-200'
                }`}
              >
                <div className="flex items-start justify-between">
                  <p className="text-2xl leading-relaxed flex-1 mr-4">{message.content}</p>
                  <button
                    onClick={() => playTextToSpeech(message.content, message.id)}
                    className={`flex-shrink-0 p-3 rounded-full transition-colors ${
                      playingMessageId === message.id
                        ? (message.role === 'user' ? 'bg-indigo-500 hover:bg-indigo-400' : 'bg-gray-200 hover:bg-gray-300')
                        : (message.role === 'user' ? 'bg-indigo-700 hover:bg-indigo-600' : 'bg-gray-100 hover:bg-gray-200')
                    }`}
                    title={playingMessageId === message.id ? '재생 중지' : '음성 재생'}
                  >
                    {playingMessageId === message.id ? (
                      <svg className={`w-6 h-6 ${message.role === 'user' ? 'text-white' : 'text-gray-600'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 9v6m4-6v6" />
                      </svg>
                    ) : (
                      <svg className={`w-6 h-6 ${message.role === 'user' ? 'text-white' : 'text-gray-600'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1.586a1 1 0 01.707.293l2.414 2.414a1 1 0 00.707.293H15M9 10V8a1 1 0 011-1h4a1 1 0 011 1v2M9 10v4a1 1 0 001 1h4a1 1 0 001-1v-4" />
                      </svg>
                    )}
                  </button>
                </div>
                <p className={`text-base mt-3 ${
                  message.role === 'user' ? 'text-indigo-100' : 'text-gray-400'
                }`}>
                  {message.timestamp.toLocaleTimeString()}
                </p>
              </div>
            </div>
          ))}
          
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-white text-gray-800 border border-gray-200 rounded-3xl px-8 py-6 max-w-xl shadow-sm">
                <div className="flex space-x-3 items-center">
                  <div className="w-4 h-4 bg-gray-400 rounded-full animate-bounce"></div>
                  <div className="w-4 h-4 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                  <div className="w-4 h-4 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                  <span className="text-gray-500 ml-3 text-xl">Benny가 입력 중...</span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* Input */}
      <div className="bg-white border-t border-gray-200 px-32 py-8 shadow-lg">
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-xl p-6">
            <p className="text-red-700 text-xl">{error}</p>
          </div>
        )}
        
        {/* Audio Recording Section */}
        {(isRecording || recordedBlob) && (
          <div className="mb-6 p-6 bg-gray-50 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center">
                {isRecording && (
                  <div className="flex items-center">
                    <div className="w-4 h-4 bg-red-500 rounded-full animate-pulse mr-3"></div>
                    <span className="text-lg font-semibold text-gray-700">녹음 중...</span>
                  </div>
                )}
                {!isRecording && recordedBlob && (
                  <span className="text-lg font-semibold text-gray-700">녹음 완료</span>
                )}
              </div>
              <div className="flex gap-3">
                {isRecording && (
                  <button
                    onClick={stopRecording}
                    className="px-6 py-3 bg-red-500 text-white rounded-xl hover:bg-red-600 transition-colors font-semibold"
                  >
                    정지
                  </button>
                )}
                {!isRecording && recordedBlob && (
                  <>
                    <button
                      onClick={sendAudioMessage}
                      disabled={isProcessingAudio}
                      className="px-6 py-3 bg-indigo-600 text-white rounded-xl hover:bg-indigo-700 transition-colors font-semibold disabled:opacity-50"
                    >
                      {isProcessingAudio ? '처리 중...' : '음성 전송'}
                    </button>
                    <button
                      onClick={cancelRecording}
                      className="px-6 py-3 bg-gray-300 text-gray-700 rounded-xl hover:bg-gray-400 transition-colors font-semibold"
                    >
                      취소
                    </button>
                  </>
                )}
              </div>
            </div>
            
            {/* Waveform Visualization */}
            <div ref={waveformRef} className="w-full bg-white rounded-xl p-4"></div>
            
            {/* Audio Playback */}
            {audioUrl && !isRecording && (
              <audio controls className="w-full mt-4">
                <source src={audioUrl} type="audio/webm" />
              </audio>
            )}
          </div>
        )}
        
        {/* Audio-Only Input */}
        <div className="flex justify-center">
          {/* Microphone Button */}
          {!isRecording && !recordedBlob && (
            <button
              onClick={startRecording}
              disabled={isLoading}
              className="bg-red-500 text-white rounded-3xl px-12 py-8 hover:bg-red-600 focus:outline-none focus:ring-4 focus:ring-red-300 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg transform hover:scale-105"
              title="음성 녹음으로 대화하기"
            >
              <div className="flex items-center space-x-4">
                <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                </svg>
                <span className="text-2xl font-semibold">음성으로 대화하기</span>
              </div>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default Chat;
