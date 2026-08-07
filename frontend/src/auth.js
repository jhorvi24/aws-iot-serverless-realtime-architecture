/**
 * Authentication Module - Cognito User Pool Auth (SRP-based)
 * Lightweight implementation without AWS SDK dependency.
 */

const Auth = (() => {
  let currentUser = null;
  let idToken = null;
  let accessToken = null;
  let refreshToken = null;

  /**
   * Sign in with email and password using Cognito USER_PASSWORD_AUTH flow.
   */
  async function signIn(email, password) {
    const payload = {
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password
      },
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: CONFIG.COGNITO_CLIENT_ID
    };

    const response = await fetch(
      `https://cognito-idp.${CONFIG.COGNITO_REGION}.amazonaws.com/`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
        },
        body: JSON.stringify(payload)
      }
    );

    const data = await response.json();

    if (data.__type && data.__type.includes('Exception')) {
      throw new Error(data.message || 'Authentication failed');
    }

    if (data.AuthenticationResult) {
      idToken = data.AuthenticationResult.IdToken;
      accessToken = data.AuthenticationResult.AccessToken;
      refreshToken = data.AuthenticationResult.RefreshToken;

      // Decode token to get user info
      currentUser = parseJwt(idToken);

      // Store tokens
      localStorage.setItem('iot_id_token', idToken);
      localStorage.setItem('iot_access_token', accessToken);
      localStorage.setItem('iot_refresh_token', refreshToken);

      return currentUser;
    }

    throw new Error('Unexpected authentication response');
  }

  /**
   * Sign out and clear tokens.
   */
  function signOut() {
    currentUser = null;
    idToken = null;
    accessToken = null;
    refreshToken = null;
    localStorage.removeItem('iot_id_token');
    localStorage.removeItem('iot_access_token');
    localStorage.removeItem('iot_refresh_token');
  }

  /**
   * Check if user is already authenticated (from stored tokens).
   */
  function checkSession() {
    const storedToken = localStorage.getItem('iot_id_token');
    if (storedToken) {
      const decoded = parseJwt(storedToken);
      const now = Math.floor(Date.now() / 1000);

      if (decoded.exp && decoded.exp > now) {
        idToken = storedToken;
        accessToken = localStorage.getItem('iot_access_token');
        refreshToken = localStorage.getItem('iot_refresh_token');
        currentUser = decoded;
        return currentUser;
      } else {
        // Token expired, try refresh
        signOut();
      }
    }
    return null;
  }

  /**
   * Refresh the access token using the refresh token.
   */
  async function refreshSession() {
    if (!refreshToken) return false;

    try {
      const payload = {
        AuthParameters: {
          REFRESH_TOKEN: refreshToken
        },
        AuthFlow: 'REFRESH_TOKEN_AUTH',
        ClientId: CONFIG.COGNITO_CLIENT_ID
      };

      const response = await fetch(
        `https://cognito-idp.${CONFIG.COGNITO_REGION}.amazonaws.com/`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
          },
          body: JSON.stringify(payload)
        }
      );

      const data = await response.json();

      if (data.AuthenticationResult) {
        idToken = data.AuthenticationResult.IdToken;
        accessToken = data.AuthenticationResult.AccessToken;
        currentUser = parseJwt(idToken);
        localStorage.setItem('iot_id_token', idToken);
        localStorage.setItem('iot_access_token', accessToken);
        return true;
      }
    } catch (error) {
      console.error('Token refresh failed:', error);
    }

    signOut();
    return false;
  }

  /**
   * Get the current ID token for API calls.
   */
  function getIdToken() {
    return idToken;
  }

  /**
   * Get the current user info.
   */
  function getUser() {
    return currentUser;
  }

  /**
   * Decode a JWT token payload.
   */
  function parseJwt(token) {
    try {
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );
      return JSON.parse(jsonPayload);
    } catch (e) {
      return {};
    }
  }

  return {
    signIn,
    signOut,
    checkSession,
    refreshSession,
    getIdToken,
    getUser
  };
})();
