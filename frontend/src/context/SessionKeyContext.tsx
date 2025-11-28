/**
 * Session Key Context
 * ==================
 * 
 * React context for managing the post-quantum session key.
 * 
 * After a successful PQ handshake, the session key is stored here
 * and used to encrypt/decrypt all messages during transport.
 * 
 * The key is stored in memory only (NOT in localStorage) for security.
 */

import React, { createContext, useContext, useState, ReactNode } from 'react';

interface SessionKeyContextType {
  sessionKey: CryptoKey | null;
  setSessionKey: (key: CryptoKey | null) => void;
  hasSessionKey: boolean;
}

const SessionKeyContext = createContext<SessionKeyContextType | undefined>(undefined);

export const SessionKeyProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [sessionKey, setSessionKey] = useState<CryptoKey | null>(null);

  return (
    <SessionKeyContext.Provider
      value={{
        sessionKey,
        setSessionKey,
        hasSessionKey: sessionKey !== null
      }}
    >
      {children}
    </SessionKeyContext.Provider>
  );
};

export const useSessionKey = () => {
  const context = useContext(SessionKeyContext);
  if (context === undefined) {
    throw new Error('useSessionKey must be used within a SessionKeyProvider');
  }
  return context;
};

