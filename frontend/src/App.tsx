import React, { useEffect, useState } from 'react';
import ReportPage from './components/ReportPage';
import { AuthContext } from './context/AuthContext';

const AUTH_SERVICE_URL = process.env.REACT_APP_AUTH_SERVICE_URL || 'http://localhost:8081';
const KEYCLOAK_URL = process.env.REACT_APP_KEYCLOAK_URL || 'http://localhost:8080';
const KEYCLOAK_REALM = process.env.REACT_APP_KEYCLOAK_REALM || 'reports-realm';
const KEYCLOAK_CLIENT_ID = process.env.REACT_APP_KEYCLOAK_CLIENT_ID || 'reports-frontend';

const App: React.FC = () => {
  const [authenticated, setAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkSession();
  }, []);

  const checkSession = async () => {
    try {
      const response = await fetch(`${AUTH_SERVICE_URL}/api/auth/session`, {
        credentials: 'include'
      });
      
      if (response.ok) {
        setAuthenticated(true);
      } else {
        setAuthenticated(false);
      }
    } catch (error) {
      setAuthenticated(false);
    } finally {
      setLoading(false);
    }
  };

  const login = async () => {
    const { generateCodeVerifier, generateCodeChallenge, storeCodeVerifier } = await import('./utils/pkce');
    
    const codeVerifier = await generateCodeVerifier();
    const codeChallenge = await generateCodeChallenge(codeVerifier);
    storeCodeVerifier(codeVerifier);

    const redirectUri = encodeURIComponent(`${window.location.origin}/callback`);
    const authUrl = `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/auth?` +
      `client_id=${KEYCLOAK_CLIENT_ID}&` +
      `redirect_uri=${redirectUri}&` +
      `response_type=code&` +
      `scope=openid profile email&` +
      `code_challenge=${codeChallenge}&` +
      `code_challenge_method=S256`;

    window.location.href = authUrl;
  };

  const logout = async () => {
    try {
      await fetch(`${AUTH_SERVICE_URL}/api/auth/logout`, {
        method: 'POST',
        credentials: 'include'
      });
      setAuthenticated(false);
      window.location.href = '/';
    } catch (error) {
      console.error('Logout failed', error);
    }
  };

  const getAccessToken = async (): Promise<string | null> => {
    try {
      const response = await fetch(`${AUTH_SERVICE_URL}/api/auth/token`, {
        credentials: 'include'
      });
      
      if (response.ok) {
        const data = await response.json();
        return data.access_token;
      }
      return null;
    } catch (error) {
      console.error('Failed to get access token', error);
      return null;
    }
  };

  useEffect(() => {
    const handleCallback = async () => {
      const urlParams = new URLSearchParams(window.location.search);
      const code = urlParams.get('code');
      
      if (code) {
        const { getCodeVerifier, clearCodeVerifier } = await import('./utils/pkce');
        const codeVerifier = getCodeVerifier();
        
        if (codeVerifier) {
          try {
            const redirectUri = `${window.location.origin}/callback`;
            const response = await fetch(`${AUTH_SERVICE_URL}/api/auth/callback`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json'
              },
              credentials: 'include',
              body: JSON.stringify({
                code,
                code_verifier: codeVerifier,
                redirect_uri: redirectUri
              })
            });

            if (response.ok) {
              clearCodeVerifier();
              setAuthenticated(true);
              window.history.replaceState({}, document.title, '/');
            } else {
              console.error('Authentication failed');
            }
          } catch (error) {
            console.error('Authentication error', error);
          }
        }
      }
    };

    if (window.location.pathname === '/callback') {
      handleCallback();
    }
  }, []);

  if (loading) {
    return <div className="flex items-center justify-center min-h-screen">Loading...</div>;
  }

  return (
    <AuthContext.Provider value={{ authenticated, login, logout, getAccessToken }}>
      <div className="App">
        <ReportPage />
      </div>
    </AuthContext.Provider>
  );
};

export default App;