// Simple test to verify test setup
describe('Test Setup', () => {
  test('basic test works', () => {
    expect(1 + 1).toBe(2);
  });

  test('mock functions work', () => {
    const mockFn = jest.fn();
    mockFn('test');
    expect(mockFn).toHaveBeenCalledWith('test');
  });

  test('speech synthesis mock works', () => {
    window.speechSynthesis.speak({} as SpeechSynthesisUtterance);
    expect(window.speechSynthesis.speak).toHaveBeenCalled();
  });

  test('navigator media devices mock works', () => {
    expect(navigator.mediaDevices.getUserMedia).toBeDefined();
  });
});