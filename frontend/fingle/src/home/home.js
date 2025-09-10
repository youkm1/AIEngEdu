import React, { useState } from 'react';
import './home.css';
import Chat from '../chat/chat';

function Home() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentView, setCurrentView] = useState('home');

  const handleLogin = (e) => {
    e.preventDefault();
    // 간단한 로그인 처리 (실제로는 API 호출)
    setIsLoggedIn(true);
  };

  const handleStartChat = () => {
    setCurrentView('chat');
  };

  if (currentView === 'chat') {
    return <Chat />;
  }
  return (
    <div className="bg-[var(--secondary-color)] text-[var(--text-primary)]">
      <div className="flex flex-col min-h-screen">
        <header className="w-full bg-white shadow-sm">
          <div className="container mx-auto px-6 py-4 flex justify-between items-center">
            <div className="flex items-center gap-2">
              <svg className="h-8 w-8 text-[var(--primary-color)]" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" viewBox="0 0 24 24"> 
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
                    <input className="w-40 px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-[var(--primary-color)] focus:border-[var(--primary-color)]" id="email" placeholder="이메일 주소" type="email"/>
                    <input className="w-40 px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-[var(--primary-color)] focus:border-[var(--primary-color)]" id="password" placeholder="비밀번호" type="password"/>
                    <button className="bg-[var(--primary-color)] text-white font-bold py-1.5 px-4 text-sm rounded-md hover:bg-blue-700 transition-colors" type="submit">로그인</button>
                  </form>
                  <a className="text-sm text-[var(--primary-color)] hover:underline whitespace-nowrap" href="#">가입하기</a>
                </>
              ) : (
                <span className="text-sm text-green-600 font-semibold">로그인 성공!</span>
              )}
            </div>
          </div>
        </header>
        <main className="flex-grow">
          <div className="relative bg-white">
            <div className="container mx-auto px-6 py-16">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
                <div className="flex flex-col gap-6 text-center lg:text-left">
                  <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight leading-tight">
                    최고의 튜터와 함께 영어를 마스터하세요
                  </h1>
                  <p className="text-lg text-[var(--text-secondary)]">
                    아이비리그 튜터와 함께하는 1:1 화상 영어 수업. 학습 속도를 높이기 위한 맞춤형 피드백과 자료를 받아보세요.
                  </p>
                  <div className="flex justify-center lg:justify-start">
                    <button 
                      onClick={handleStartChat}
                      disabled={!isLoggedIn}
                      className={`inline-block font-bold py-3 px-8 rounded-lg transition-colors ${
                        isLoggedIn 
                          ? 'bg-[var(--primary-color)] text-white hover:bg-blue-700' 
                          : 'bg-gray-400 text-gray-200 cursor-not-allowed'
                      }`}
                    >
                      {isLoggedIn ? '대화 시작하기' : '로그인 후 이용 가능'}
                    </button>
                  </div>
                </div>
                <div className="flex justify-center">
                  <img alt="Ringle 플랫폼 스크린샷" className="rounded-lg shadow-2xl" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAGAT4sPGzADv_CRT_Q72U4CU5jyd-ymXPNj-bwVZfmtfFXuMHedUQDEdxVvYu90LkOI3eIco9JGeB1spWuY3eY9TlWzNRCA0ExL_vnBv1dkn6RGvNsz-rHBO3cFFjoA0FBdapMZqyNQ5d0zRSeZVf9lHD2bK5cszbKUdteYzytkDHcrWD7d3OH5mKhvm0VSXWZkr5AmnwJ4W6tWS1laYcyd0oXi7HeXbxY6JvVCYihIsk6aFc0n_bFGuSWTBfqRDBFoqMR--maeGY"/>
                </div>
              </div>
            </div>
          </div>
          <div className="bg-[var(--secondary-color)] py-16">
            <div className="container mx-auto px-6">
              <h2 className="text-3xl font-bold text-center mb-12">링글 플랜</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto">
                <div className="bg-white rounded-lg shadow-lg p-8 flex flex-col">
                  <h3 className="text-2xl font-bold text-center mb-2">베이직</h3>
                  <p className="text-center font-semibold text-[var(--primary-color)] mb-4">30일</p>
                  <p className="text-center text-[var(--text-secondary)] mb-6">기본적인 학습 기능 제공</p>
                  <ul className="space-y-4 text-gray-700 flex-grow">
                    <li className="flex items-center">
                      <span className="material-symbols-outlined text-green-500 mr-2">check_circle</span>
                      <span>AI 표현 학습 가능</span>
                    </li>
                  </ul>
                  <button className="mt-8 w-full bg-gray-200 text-[var(--text-primary)] font-bold py-3 px-6 rounded-lg hover:bg-gray-300 transition-colors">플랜 시작하기</button>
                </div>
                <div className="bg-white rounded-lg shadow-lg p-8 flex flex-col border-2 border-[var(--primary-color)] relative">
                  <div className="absolute top-0 -translate-y-1/2 left-1/2 -translate-x-1/2 bg-[var(--primary-color)] text-white text-xs font-bold px-3 py-1 rounded-full">가장 인기 있는</div>
                  <h3 className="text-2xl font-bold text-center mb-2">프리미엄</h3>
                  <p className="text-center font-semibold text-[var(--primary-color)] mb-4">60일</p>
                  <p className="text-center text-[var(--text-secondary)] mb-6">최상의 학습 효과를 위한 모든 기능</p>
                  <ul className="space-y-4 text-gray-700 flex-grow">
                    <li className="flex items-center">
                      <span className="material-symbols-outlined text-green-500 mr-2">check_circle</span>
                      <span>AI 표현 학습</span>
                    </li>
                    <li className="flex items-center">
                      <span className="material-symbols-outlined text-green-500 mr-2">check_circle</span>
                      <span>AI 롤플레잉</span>
                    </li>
                    <li className="flex items-center">
                      <span className="material-symbols-outlined text-green-500 mr-2">check_circle</span>
                      <span>무제한 AI 분석 가능</span>
                    </li>
                  </ul>
                  <button className="mt-8 w-full bg-[var(--primary-color)] text-white font-bold py-3 px-6 rounded-lg hover:bg-blue-700 transition-colors">플랜 시작하기</button>
                </div>
              </div>
            </div>
          </div>
        </main>
        <footer className="bg-gray-100">
          <div className="container mx-auto px-6 py-8">
            <div className="flex justify-between items-center">
              <p className="text-sm text-gray-500">© 2024 Ringle. All rights reserved.</p>
              <div className="flex gap-4">
                <a className="text-gray-500 hover:text-gray-800" href="#">이용약관</a>
                <a className="text-gray-500 hover:text-gray-800" href="#">개인정보 처리방침</a>
                <a className="text-gray-500 hover:text-gray-800" href="#">문의하기</a>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
}

export default Home;