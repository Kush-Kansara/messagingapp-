import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { authAPI, pqAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useSessionKey } from '../context/SessionKeyContext';
import { performKyberEncapsulation, deriveSessionKey } from '../utils/crypto';
import './Auth.css';

const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuth();
  const { setSessionKey } = useSessionKey();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Step 1: Login (sets JWT cookie)
      const user = await authAPI.login({ username, password });
      login(user);
      
      // Step 2: Perform post-quantum handshake to establish session key
      try {
        console.log('[PQ] Starting post-quantum handshake...');
        
        // Get server's Kyber public key
        const { public_key: serverPublicKeyBase64 } = await pqAPI.getKemPublicKey();
        console.log('[PQ] Received server public key');
        
        // Perform Kyber KEM encapsulation (client side of key exchange)
        const { ciphertext, sharedSecret } = await performKyberEncapsulation(serverPublicKeyBase64);
        console.log('[PQ] Kyber encapsulation complete');
        
        // Send ciphertext to server for handshake
        await pqAPI.handshake(ciphertext);
        console.log('[PQ] Handshake request sent to server');
        
        // Derive session key from shared secret (client side)
        // Server does the same derivation, so both sides have the same key
        const sessionKey = await deriveSessionKey(sharedSecret);
        setSessionKey(sessionKey);
        console.log('[PQ] Session key established and stored');
        
        console.log('[PQ] Post-quantum handshake completed successfully!');
      } catch (pqError: any) {
        console.error('[PQ] Post-quantum handshake failed:', pqError);
        // Don't block login if PQ handshake fails - app can still work with plaintext
        // In production, you might want to make this mandatory
        console.warn('[PQ] Continuing without PQ encryption (fallback to plaintext)');
      }
      
      navigate('/chat');
    } catch (err: any) {
      // Handle validation errors from FastAPI/Pydantic
      const errorDetail = err.response?.data?.detail;
      let errorMessage = 'Login failed. Please try again.';
      
      if (errorDetail) {
        if (Array.isArray(errorDetail)) {
          // Pydantic validation errors are arrays
          errorMessage = errorDetail.map((e: any) => e.msg || e.message || JSON.stringify(e)).join(', ');
        } else if (typeof errorDetail === 'string') {
          errorMessage = errorDetail;
        } else {
          errorMessage = 'Validation error. Please check your input.';
        }
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <h1>Login</h1>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="username">Username</label>
            <input
              type="text"
              id="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              autoComplete="username"
            />
          </div>
          <div className="form-group">
            <label htmlFor="password">Password</label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
            />
          </div>
          {error && <div className="error-message">{error}</div>}
          <button type="submit" disabled={loading} className="submit-button">
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>
        <p className="auth-link">
          Don't have an account? <Link to="/register">Register here</Link>
        </p>
      </div>
    </div>
  );
};

export default Login;

