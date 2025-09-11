declare module 'recordrtc' {
  export interface RecordRTCOptions {
    type?: 'audio' | 'video' | 'screen' | 'canvas' | 'gif';
    mimeType?: string;
    recorderType?: any;
    numberOfAudioChannels?: number;
    desiredSampRate?: number;
    bufferSize?: number;
    bitrate?: number;
  }

  class RecordRTC {
    constructor(stream: MediaStream, options?: RecordRTCOptions);
    static StereoAudioRecorder: any;
    startRecording(): void;
    stopRecording(callback?: () => void): void;
    pauseRecording(): void;
    resumeRecording(): void;
    getBlob(): Blob;
    getDataURL(callback: (dataURL: string) => void): void;
    toURL(): string;
    save(fileName?: string): void;
    destroy(): void;
    getState(): string;
  }

  export default RecordRTC;
}