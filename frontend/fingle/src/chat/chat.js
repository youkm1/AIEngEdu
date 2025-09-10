import React from 'react';

function Chat() {
  return (
    <div className="bg-gray-50">
      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <div className="flex flex-col items-center md:items-start text-center md:text-left">
            <div className="bg-indigo-600 p-8 rounded-2xl inline-block">
              <svg className="w-24 h-24 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2"></path>
              </svg>
            </div>
            <div className="mt-6">
              <span className="bg-gray-200 text-gray-600 text-xs font-semibold px-3 py-1 rounded-md">기타</span>
            </div>
            <h1 className="text-4xl lg:text-5xl font-bold mt-4 text-gray-800">자기소개하기</h1>
            <p className="text-gray-500 mt-2 text-lg">Introducing One's Name and Role at Work</p>
          </div>
          <div className="w-full max-w-lg mx-auto">
            <div className="mt-10">
              <span className="bg-indigo-100 text-indigo-700 text-sm font-semibold px-3 py-1 rounded-md">시나리오</span>
              <div className="bg-white p-6 rounded-2xl border border-gray-200 mt-4">
                <p className="text-gray-700 text-lg">새로운 사람을 만나는 비즈니스 환경에서 본인을 소개볼까요?</p>
              </div>
            </div>
            <div className="mt-8 bg-gray-100 p-6 rounded-2xl">
              <div className="flex items-center">
                <span className="material-icons text-gray-500">mic</span>
                <h2 className="ml-2 font-semibold text-gray-800 text-lg">마이크 사용 권한</h2>
              </div>
              <p className="text-sm text-gray-600 mt-3">* 링글 AI와 영어로 대화를 나누기 위해서는 마이크 사용 권한이 필요해요.</p>
            </div>
            <div className="mt-8">
              <button className="w-full bg-indigo-600 text-white font-semibold py-4 rounded-xl hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 text-lg">
                대화 시작하기
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Chat;