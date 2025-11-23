import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { messagesAPI, authAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import type { Message, User } from '../types';
import './Chat.css';

const Chat: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const { user, logout, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
    fetchUsers();
  }, [isAuthenticated, navigate]);

  useEffect(() => {
    if (selectedUserId) {
      fetchMessages();
      // Poll for new messages every 3 seconds
      const interval = setInterval(fetchMessages, 3000);
      return () => clearInterval(interval);
    } else {
      setMessages([]);
    }
  }, [selectedUserId, isAuthenticated, navigate]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const fetchUsers = async () => {
    try {
      const fetchedUsers = await authAPI.getUsers();
      setUsers(fetchedUsers);
    } catch (err: any) {
      console.error('Failed to fetch users:', err);
      if (err.response?.status === 401) {
        logout();
        navigate('/login');
      }
    }
  };

  const fetchMessages = async () => {
    if (!selectedUserId) return;
    try {
      const fetchedMessages = await messagesAPI.getMessages(selectedUserId, 50);
      setMessages(fetchedMessages);
    } catch (err: any) {
      console.error('Failed to fetch messages:', err);
      if (err.response?.status === 401) {
        logout();
        navigate('/login');
      }
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedUserId) return;

    setLoading(true);
    setError('');

    try {
      const sentMessage = await messagesAPI.sendMessage(newMessage.trim(), selectedUserId);
      setMessages((prev) => [...prev, sentMessage]);
      setNewMessage('');
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to send message');
      if (err.response?.status === 401) {
        logout();
        navigate('/login');
      }
    } finally {
      setLoading(false);
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (minutes < 1440) return `${Math.floor(minutes / 60)}h ago`;
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const getSelectedUserName = () => {
    if (!selectedUserId) return null;
    const selectedUser = users.find(u => u.id === selectedUserId);
    return selectedUser?.username || 'Unknown';
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="chat-container">
      <div className="chat-sidebar">
        <div className="sidebar-header">
          <h2>Users</h2>
          <div className="user-info-sidebar">
            <span>{user?.username}</span>
            <button onClick={() => { logout(); navigate('/login'); }} className="logout-button">
              Logout
            </button>
          </div>
        </div>
        <div className="users-list">
          {users.length === 0 ? (
            <div className="empty-users">No other users found</div>
          ) : (
            users.map((otherUser) => (
              <div
                key={otherUser.id}
                className={`user-item ${selectedUserId === otherUser.id ? 'active' : ''}`}
                onClick={() => setSelectedUserId(otherUser.id)}
              >
                <div className="user-avatar">{otherUser.username[0].toUpperCase()}</div>
                <div className="user-name">{otherUser.username}</div>
              </div>
            ))
          )}
        </div>
      </div>
      <div className="chat-main">
        <div className="chat-header">
          <h1>{selectedUserId ? `Chat with ${getSelectedUserName()}` : 'Select a user to start chatting'}</h1>
        </div>
        {selectedUserId ? (
          <>
            <div className="messages-container">
              {messages.length === 0 ? (
                <div className="empty-messages">No messages yet. Start the conversation!</div>
              ) : (
                messages.map((message) => {
                  const isOwnMessage = message.sender_id === user?.id;
                  return (
                    <div key={message.id} className={`message ${isOwnMessage ? 'own-message' : ''}`}>
                      <div className="message-header">
                        <span className="message-username">{message.username}</span>
                        <span className="message-timestamp">{formatTimestamp(message.timestamp)}</span>
                      </div>
                      <div className="message-content">{message.content}</div>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>
            {error && <div className="error-message">{error}</div>}
            <form onSubmit={handleSend} className="message-input-form">
              <input
                type="text"
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                placeholder="Type your message..."
                className="message-input"
                disabled={loading}
              />
              <button type="submit" disabled={loading || !newMessage.trim()} className="send-button">
                {loading ? 'Sending...' : 'Send'}
              </button>
            </form>
          </>
        ) : (
          <div className="no-selection">
            <p>Select a user from the sidebar to start a conversation</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Chat;

