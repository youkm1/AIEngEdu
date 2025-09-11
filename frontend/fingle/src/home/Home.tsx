import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import './home.css';
import { useAuth } from '../contexts/AuthContext';
import apiService, { Membership } from '../services/api';

interface LoginFormData {
  email: string;
  password: string;
}

const Home = () => {
  const { user, isLoggedIn, login, error, clearError, isLoading } = useAuth();
  const navigate = useNavigate();
  const [formData, setFormData] = useState<LoginFormData>({
    email: '',
    password: '',
  });
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [membership, setMembership] = useState<Membership | null>(null);
  const [membershipLoading, setMembershipLoading] = useState<boolean>(false);

  // Fetch membership data when user is logged in
  useEffect(() => {
    const fetchMembership = async () => {
      if (!user || !isLoggedIn) {
        setMembership(null);
        return;
      }

      try {
        setMembershipLoading(true);
        const memberships = await apiService.getUserMemberships(user.id);
        // Get the active membership
        const activeMembership = memberships.find(m => m.is_active) || memberships[0] || null;
        setMembership(activeMembership);
      } catch (error) {
        console.error('Failed to fetch membership:', error);
        setMembership(null);
      } finally {
        setMembershipLoading(false);
      }
    };

    fetchMembership();
  }, [user, isLoggedIn]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    
    // Clear error when user starts typing
    if (error) {
      clearError();
    }
  };

  const handleLogin = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    if (!formData.email.trim() || !formData.password.trim()) {
      return;
    }

    try {
      setIsSubmitting(true);
      await login(formData.email, formData.password);
      
      setFormData({ email: '', password: '' });
    } catch (error) {
      // Error is handled by AuthContext
      console.error('Login failed:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleStartChat = () => {
    navigate('/chat');
  };

  return (
    <div className="bg-[var(--secondary-color)] text-[var(--text-primary)]">
      <div className="flex flex-col min-h-screen">
        <header className="w-full bg-white shadow-sm">
          <div className="container mx-auto px-6 py-4 flex justify-between items-center">
            <div className="flex items-center gap-2">
              <svg 
                className="h-8 w-8 text-[var(--primary-color)]" 
                fill="none" 
                stroke="currentColor" 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth="2" 
                viewBox="0 0 24 24"
              > 
                <path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 8.2c0 7.3-8 11.8-8 11.8z"></path> 
                <circle cx="12" cy="10" r="3"></circle>
              </svg>
              <span className="text-xl font-bold">Ringle</span>
            </div>
            <nav className="flex items-center gap-6">
              <a className="text-sm font-medium text-gray-600 hover:text-[var(--primary-color)]" href="#">소개</a>
              <a className="text-sm font-medium text-gray-600 hover:text-[var(--primary-color)]" href="#">가격</a>
              <a className="text-sm font-medium text-gray-600 hover:text-[var(--primary-color)]" href="#">기업용</a>
            </nav>
            <div className="flex items-center gap-2">
              {!isLoggedIn ? (
                <>
                  <form className="flex items-center gap-2" onSubmit={handleLogin}>
                    <input 
                      className="w-40 px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-[var(--primary-color)] focus:border-[var(--primary-color)]" 
                      id="email"
                      name="email"
                      placeholder="이메일 주소" 
                      type="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      disabled={isSubmitting}
                      required
                    />
                    <input 
                      className="w-40 px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-[var(--primary-color)] focus:border-[var(--primary-color)]" 
                      id="password"
                      name="password"
                      placeholder="비밀번호" 
                      type="password"
                      value={formData.password}
                      onChange={handleInputChange}
                      disabled={isSubmitting}
                      required
                    />
                    <button 
                      className="bg-[var(--primary-color)] text-white font-bold py-1.5 px-4 text-sm rounded-md hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed" 
                      type="submit"
                      disabled={isSubmitting || isLoading}
                    >
                      {isSubmitting ? '로그인 중...' : '로그인'}
                    </button>
                  </form>
                </>
              ) : (
                <div className="flex items-center gap-4">
                  {/* User greeting */}
                  <span className="text-sm text-green-600 font-semibold">
                    안녕하세요, {user?.name}님!
                  </span>
                  
                  {/* Membership info */}
                  <div className="flex items-center gap-2 px-3 py-1 bg-gray-50 rounded-lg">
                    {membershipLoading ? (
                      <div className="text-xs text-gray-500">로딩 중...</div>
                    ) : membership ? (
                      <>
                        <div className={`w-2 h-2 rounded-full ${
                          membership.status === 'active' ? 'bg-green-500' : 'bg-gray-400'
                        }`}></div>
                        <div className="text-xs">
                          <span className="font-semibold text-gray-700">
                            {membership.membership_type === 'premium' ? '프리미엄' : '베이직'}
                          </span>
                          <span className="text-gray-500 ml-1">
                            ({membership.status === 'active' ? '활성' : '만료됨'})
                          </span>
                        </div>
                        {membership.status === 'active' && (
                          <div className="text-xs text-gray-500">
                            {new Date(membership.end_date) > new Date() 
                              ? `~${new Date(membership.end_date).toLocaleDateString()}`
                              : '만료됨'
                            }
                          </div>
                        )}
                      </>
                    ) : (
                      <div className="text-xs text-gray-500">멤버십 없음</div>
                    )}
                  </div>
                  
                  <button 
                    onClick={() => navigate('/')}
                    className="text-sm text-gray-600 hover:text-[var(--primary-color)]"
                  >
                    로그아웃
                  </button>
                </div>
              )}
            </div>
          </div>
          {/* Error Message */}
          {error && (
            <div className="bg-red-50 border-l-4 border-red-400 p-4 mx-6">
              <div className="flex">
                <div className="ml-3">
                  <p className="text-sm text-red-700">{error}</p>
                </div>
                <div className="ml-auto pl-3">
                  <button 
                    onClick={clearError}
                    className="text-red-400 hover:text-red-600"
                  >
                    <span className="sr-only">Dismiss</span>
                    ×
                  </button>
                </div>
              </div>
            </div>
          )}
        </header>
        
        <main className="flex-grow">
          <div className="relative bg-white">
            <div className="max-w-7xl mx-auto px-8 py-24">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-20 items-center">
                <div className="flex flex-col gap-8 text-left max-w-2xl">
                  <h1 className="text-5xl xl:text-6xl font-extrabold tracking-tight leading-tight text-gray-900">
                    최고의 튜터와 함께 영어를 마스터하세요
                  </h1>
                  <p className="text-xl text-gray-600 leading-relaxed">
                    아이비리그 튜터와 함께하는 1:1 화상 영어 수업. 학습 속도를 높이기 위한 맞춤형 피드백과 자료를 받아보세요.
                  </p>
                  <div className="flex gap-4">
                    <button 
                      onClick={handleStartChat}
                      disabled={!isLoggedIn}
                      className={`font-bold py-4 px-10 text-lg rounded-xl transition-all transform hover:scale-105 ${
                        isLoggedIn 
                          ? 'bg-[var(--primary-color)] text-white hover:bg-blue-700 shadow-lg' 
                          : 'bg-gray-400 text-gray-200 cursor-not-allowed'
                      }`}
                    >
                      {isLoggedIn ? '대화 시작하기' : '로그인 후 이용 가능'}
                    </button>
                    {isLoggedIn && (
                      <button className="font-semibold py-4 px-8 text-lg border-2 border-gray-300 text-gray-700 rounded-xl hover:border-gray-400 transition-colors">
                        더 알아보기
                      </button>
                    )}
                  </div>
                </div>
                <div className="flex justify-center xl:justify-end">
                  <div className="relative">
                    <img 
                      alt="Ringle 플랫폼 스크린샷" 
                      className="rounded-2xl shadow-2xl max-w-lg xl:max-w-xl w-full" 
                      src="https://lh3.googleusercontent.com/aida-public/AB6AXuAGAT4sPGzADv_CRT_Q72U4CU5jyd-ymXPNj-bwVZfmtfFXuMHedUQDEdxVvYu90LkOI3eIco9JGeB1spWuY3eY9TlWzNRCA0ExL_vnBv1dkn6RGvNsz-rHBO3cFFjoA0FBdapMZqyNQ5d0zRSeZVf9lHD2bK5cszbKUdteYzytkDHcrWD7d3OH5mKhvm0VSXWZkr5AmnwJ4W6tWS1laYcyd0oXi7HeXbxY6JvVCYihIsk6aFc0n_bFGuSWTBfqRDBFoqMR--maeGY"
                    />
                    {/* Floating element for visual interest */}
                    <div className="absolute -top-4 -left-4 w-24 h-24 bg-blue-100 rounded-full opacity-50"></div>
                    <div className="absolute -bottom-6 -right-6 w-32 h-32 bg-indigo-100 rounded-full opacity-30"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div className="bg-gray-50 py-24">
            <div className="max-w-7xl mx-auto px-8">
              <div className="text-center mb-16">
                <h2 className="text-4xl xl:text-5xl font-bold text-gray-900 mb-4">링글 플랜</h2>
                <p className="text-xl text-gray-600 max-w-2xl mx-auto">
                  자신에게 맞는 플랜을 선택하여 영어 실력을 향상시켜보세요
                </p>
              </div>
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 max-w-5xl mx-auto">
                <div className="bg-white rounded-2xl shadow-xl p-10 flex flex-col hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-2">
                  <div className="text-center mb-8">
                    <h3 className="text-3xl font-bold text-gray-900 mb-3">베이직</h3>
                    <div className="text-4xl font-extrabold text-[var(--primary-color)] mb-2">30일</div>
                    <p className="text-lg text-gray-600">기본적인 학습 기능 제공</p>
                  </div>
                  <ul className="space-y-6 text-gray-700 flex-grow mb-8">
                    <li className="flex items-center text-lg">
                      <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center mr-4">
                        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <span>AI 표현 학습 가능</span>
                    </li>
                  </ul>
                  <button 
                    className="w-full bg-gray-100 text-gray-800 font-bold py-4 px-6 text-lg rounded-xl hover:bg-gray-200 transition-all duration-200 disabled:opacity-50"
                    disabled={!isLoggedIn}
                  >
                    {isLoggedIn ? '플랜 시작하기' : '로그인 후 이용 가능'}
                  </button>
                </div>
                <div className="bg-white rounded-2xl shadow-xl p-10 flex flex-col border-4 border-[var(--primary-color)] relative hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-2">
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-[var(--primary-color)] text-white text-sm font-bold px-6 py-2 rounded-full shadow-lg">
                    가장 인기 있는
                  </div>
                  <div className="text-center mb-8 mt-4">
                    <h3 className="text-3xl font-bold text-gray-900 mb-3">프리미엄</h3>
                    <div className="text-4xl font-extrabold text-[var(--primary-color)] mb-2">60일</div>
                    <p className="text-lg text-gray-600">최상의 학습 효과를 위한 모든 기능</p>
                  </div>
                  <ul className="space-y-6 text-gray-700 flex-grow mb-8">
                    <li className="flex items-center text-lg">
                      <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center mr-4">
                        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <span>AI 표현 학습</span>
                    </li>
                    <li className="flex items-center text-lg">
                      <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center mr-4">
                        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <span>AI 롤플레잉</span>
                    </li>
                    <li className="flex items-center text-lg">
                      <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center mr-4">
                        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <span>무제한 AI 분석 가능</span>
                    </li>
                  </ul>
                  <button 
                    className="w-full bg-[var(--primary-color)] text-white font-bold py-4 px-6 text-lg rounded-xl hover:bg-blue-700 transition-all duration-200 shadow-lg disabled:opacity-50"
                    disabled={!isLoggedIn}
                  >
                    {isLoggedIn ? '플랜 시작하기' : '로그인 후 이용 가능'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </main>
        
        <footer className="bg-gray-900 text-white">
          <div className="max-w-7xl mx-auto px-8 py-16">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-12">
              <div className="col-span-2">
                <div className="flex items-center gap-2 mb-6">
                  <svg 
                    className="h-8 w-8 text-blue-400" 
                    fill="none" 
                    stroke="currentColor" 
                    strokeLinecap="round" 
                    strokeLinejoin="round" 
                    strokeWidth="2" 
                    viewBox="0 0 24 24"
                  > 
                    <path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 8.2c0 7.3-8 11.8-8 11.8z"></path> 
                    <circle cx="12" cy="10" r="3"></circle>
                  </svg>
                  <span className="text-2xl font-bold">Ringle</span>
                </div>
                <p className="text-gray-300 text-lg leading-relaxed max-w-md">
                  세계 최고 수준의 튜터와 함께하는 1:1 영어 회화 수업으로 실력을 향상시켜보세요.
                </p>
              </div>
              
              <div>
                <h3 className="font-semibold text-lg mb-6">서비스</h3>
                <ul className="space-y-4">
                  <li><a href="#" className="text-gray-300 hover:text-white transition-colors">1:1 튜터링</a></li>
                  <li><a href="#" className="text-gray-300 hover:text-white transition-colors">AI 학습</a></li>
                  <li><a href="#" className="text-gray-300 hover:text-white transition-colors">학습 분석</a></li>
                </ul>
              </div>
              
              <div>
                <h3 className="font-semibold text-lg mb-6">지원</h3>
                <ul className="space-y-4">
                  <li><a href="#" className="text-gray-300 hover:text-white transition-colors">이용약관</a></li>
                  <li><a href="#" className="text-gray-300 hover:text-white transition-colors">개인정보 처리방침</a></li>
                  <li><a href="#" className="text-gray-300 hover:text-white transition-colors">문의하기</a></li>
                </ul>
              </div>
            </div>
            
            <div className="border-t border-gray-700 mt-12 pt-8">
              <p className="text-center text-gray-400">© 2024 Ringle. All rights reserved.</p>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
};

export default Home;
