import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import apiService, { User } from '../services/api';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isLoggedIn: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  error: string | null;
  clearError: () => void;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const isLoggedIn = !!user;

  // Initialize auth state on app load
  useEffect(() => {
    initializeAuth();
  }, []);

  const initializeAuth = async () => {
    try {
      const currentUser = await apiService.getCurrentUser();
      if (currentUser) {
        setUser(currentUser);
      }
    } catch (error) {
      console.error('Failed to initialize auth:', error);
      localStorage.removeItem('authToken');
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, password: string): Promise<void> => {
    try {
      setError(null);
      setIsLoading(true);

      const response = await apiService.login(email, password);
      
      if (response.success && response.data) {
        const { user: userData, token } = response.data;
        localStorage.setItem('authToken', token);
        setUser(userData);
      } else {
        throw new Error(response.message || '로그인에 실패했습니다.');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '로그인에 실패했습니다.';
      setError(errorMessage);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };


  const logout = (): void => {
    localStorage.removeItem('authToken');
    setUser(null);
    setError(null);
  };

  const clearError = (): void => {
    setError(null);
  };

  const value: AuthContextType = {
    user,
    isLoading,
    isLoggedIn,
    login,
    logout,
    error,
    clearError,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};