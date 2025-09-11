import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import apiService from '../services/api';

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
  const [inputMessage, setInputMessage] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isChatStarted, setIsChatStarted] = useState<boolean>(false);
  const [conversationId, setConversationId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const startChat = async () => {
    if (!user) {
      setError('로그인이 필요합니다.');
      return;
    }

    try {
      setIsLoading(true);
      setError(null);
      
      // Create a new conversation
      const conversation = await apiService.createConversation('자기소개하기', user.id);
      setConversationId(conversation.id);
      setIsChatStarted(true);
      
      // Add initial system message
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

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!inputMessage.trim() || !conversationId || !user) {
      return;
    }

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputMessage.trim(),
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsLoading(true);
    setError(null);

    try {
      // Send message to API (this would typically be a streaming response)
      await apiService.sendMessage(conversationId, userMessage.content, user.id);
      
      // For now, add a mock AI response
      // In a real implementation, you would handle the streaming response
      setTimeout(() => {
        const aiResponse: Message = {
          id: (Date.now() + 1).toString(),
          role: 'assistant',
          content: '좋은 자기소개네요! 좀 더 구체적으로 본인의 역할과 경험에 대해 말씀해주실 수 있나요?',
          timestamp: new Date()
        };
        setMessages(prev => [...prev, aiResponse]);
        setIsLoading(false);
      }, 1500);
      
    } catch (error) {
      console.error('Failed to send message:', error);
      setError('메시지를 보낼 수 없습니다. 다시 시도해주세요.');
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage(e as any);
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
                <p className="text-gray-700 text-lg">링글 AI와 영어로 대화를 나누기 위해서는 마이크 사용 권한이 필요해요.</p>
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
                <p className="text-2xl leading-relaxed">{message.content}</p>
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
        
        <form onSubmit={sendMessage} className="flex space-x-6">
          <input
            type="text"
            value={inputMessage}
            onChange={(e) => setInputMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="메시지를 입력하세요..."
            className="flex-1 border border-gray-300 rounded-2xl px-8 py-6 text-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent bg-gray-50"
            disabled={isLoading}
          />
          <button
            type="submit"
            disabled={isLoading || !inputMessage.trim()}
            className="bg-indigo-600 text-white rounded-2xl px-12 py-6 text-xl font-semibold hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors shadow-lg"
          >
            전송
          </button>
        </form>
      </div>
    </div>
  );
};

export default Chat;
