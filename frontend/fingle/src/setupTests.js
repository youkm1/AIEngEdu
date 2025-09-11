// jest-dom adds custom jest matchers for asserting on DOM nodes.
import '@testing-library/jest-dom';
import React from 'react';

// Mock window.speechSynthesis for TTS tests
Object.defineProperty(window, 'speechSynthesis', {
  writable: true,
  value: {
    speak: jest.fn(),
    cancel: jest.fn(),
    getVoices: jest.fn(() => []),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn()
  }
});

// Mock MediaDevices for audio recording tests
Object.defineProperty(navigator, 'mediaDevices', {
  writable: true,
  value: {
    getUserMedia: jest.fn(() => 
      Promise.resolve({
        getTracks: () => [],
        getVideoTracks: () => [],
        getAudioTracks: () => []
      })
    )
  }
});

// Mock URL.createObjectURL for blob handling
Object.defineProperty(URL, 'createObjectURL', {
  writable: true,
  value: jest.fn(() => 'mock-url')
});

Object.defineProperty(URL, 'revokeObjectURL', {
  writable: true,
  value: jest.fn()
});

// Mock AudioContext for VAD tests
global.AudioContext = jest.fn().mockImplementation(() => ({
  createAnalyser: jest.fn(() => ({
    fftSize: 256,
    smoothingTimeConstant: 0.8,
    connect: jest.fn(),
    getByteFrequencyData: jest.fn()
  })),
  createMediaStreamSource: jest.fn(() => ({
    connect: jest.fn(),
    disconnect: jest.fn()
  })),
  decodeAudioData: jest.fn(() => Promise.resolve({
    getChannelData: jest.fn(() => new Float32Array(100)),
    numberOfChannels: 1,
    sampleRate: 44100,
    length: 100
  })),
  createBuffer: jest.fn(() => ({
    getChannelData: jest.fn(() => new Float32Array(100))
  })),
  close: jest.fn()
}));

// Mock RecordRTC
jest.mock('recordrtc', () => {
  return jest.fn().mockImplementation(() => ({
    startRecording: jest.fn(),
    stopRecording: jest.fn((callback) => callback()),
    getBlob: jest.fn(() => new Blob(['mock audio data'], { type: 'audio/webm' })),
    destroy: jest.fn()
  }));
});

// Mock WaveSurfer
jest.mock('wavesurfer.js', () => ({
  __esModule: true,
  default: {
    create: jest.fn(() => ({
      loadBlob: jest.fn(),
      destroy: jest.fn()
    }))
  }
}));

