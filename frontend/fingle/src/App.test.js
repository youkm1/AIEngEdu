import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

// Mock fetch for API calls
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    headers: {
      get: jest.fn(() => 'application/json')
    },
    json: () => Promise.resolve([])
  })
);

test('renders main app routes', () => {
  render(<App />);
  // The app should render the route structure
  expect(document.querySelector('.App')).toBeInTheDocument();
});
