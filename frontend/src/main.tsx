import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { SessionKeyProvider } from './context/SessionKeyContext'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <SessionKeyProvider>
      <App />
    </SessionKeyProvider>
  </React.StrictMode>,
)

