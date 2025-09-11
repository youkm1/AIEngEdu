const React = require('react');

module.exports = {
  __esModule: true,
  BrowserRouter: ({ children }) => React.createElement('div', { 'data-testid': 'browser-router' }, children),
  Router: ({ children }) => React.createElement('div', { 'data-testid': 'router' }, children),
  Routes: ({ children }) => React.createElement('div', { 'data-testid': 'routes' }, children),
  Route: ({ children }) => React.createElement('div', { 'data-testid': 'route' }, children),
  Link: ({ children, to, ...props }) => React.createElement('a', { href: to, 'data-testid': 'link', ...props }, children),
  NavLink: ({ children, to, ...props }) => React.createElement('a', { href: to, 'data-testid': 'navlink', ...props }, children),
  Navigate: () => React.createElement('div', { 'data-testid': 'navigate' }),
  Outlet: () => React.createElement('div', { 'data-testid': 'outlet' }),
  useNavigate: () => ((global).mockNavigate || jest.fn()),
  useLocation: () => ({ 
    pathname: '/', 
    search: '', 
    hash: '', 
    state: null, 
    key: 'default' 
  }),
  useParams: () => ({}),
  useSearchParams: () => [new URLSearchParams(), jest.fn()],
  createBrowserRouter: jest.fn(),
  RouterProvider: ({ children }) => React.createElement('div', { 'data-testid': 'router-provider' }, children)
};