import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { documentsAPI, pqAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useSessionKey } from '../context/SessionKeyContext';
import { encryptMessage } from '../utils/crypto';
import type { Document, DocumentListItem } from '../types';
import './Documents.css';

const Documents: React.FC = () => {
  const [documents, setDocuments] = useState<DocumentListItem[]>([]);
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [uploadTitle, setUploadTitle] = useState('');
  const [uploadContent, setUploadContent] = useState('');
  const [showUploadForm, setShowUploadForm] = useState(false);
  const { user, logout, isAuthenticated } = useAuth();
  const { sessionKey, hasSessionKey } = useSessionKey();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isAuthenticated || !user) {
      navigate('/login');
      return;
    }
    
    fetchDocuments();
  }, [isAuthenticated, user, navigate]);

  const fetchDocuments = async () => {
    try {
      setLoading(true);
      const docs = await documentsAPI.listDocuments();
      setDocuments(docs);
    } catch (err: any) {
      console.error('Failed to fetch documents:', err);
      if (err.response?.status === 401) {
        logout();
        navigate('/login');
      } else {
        setError('Failed to load documents. Please refresh the page.');
      }
    } finally {
      setLoading(false);
    }
  };

  const fetchDocument = async (documentId: string) => {
    try {
      setLoading(true);
      const doc = await documentsAPI.getDocument(documentId);
      setSelectedDocument(doc);
      setError('');
    } catch (err: any) {
      console.error('Failed to fetch document:', err);
      setError('Failed to load document.');
    } finally {
      setLoading(false);
    }
  };

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadTitle.trim() || !uploadContent.trim()) {
      setError('Title and content are required');
      return;
    }

    setLoading(true);
    setError('');

    try {
      let uploadedDoc: Document;
      
      if (hasSessionKey && sessionKey) {
        // Encrypt document content using post-quantum transport security
        console.log('[PQ] Encrypting document before upload...');
        const { nonce, ciphertext } = await encryptMessage(sessionKey, uploadContent);
        
        uploadedDoc = await documentsAPI.uploadDocumentEncrypted(
          uploadTitle,
          nonce,
          ciphertext
        );
        console.log('[PQ] Encrypted document uploaded successfully');
      } else {
        // Fallback to plaintext
        console.warn('[PQ] No session key available, uploading plaintext');
        uploadedDoc = await documentsAPI.uploadDocument(uploadTitle, uploadContent);
      }

      // Refresh document list
      await fetchDocuments();
      
      // Clear form
      setUploadTitle('');
      setUploadContent('');
      setShowUploadForm(false);
      
      // Select the new document
      await fetchDocument(uploadedDoc.id);
    } catch (err: any) {
      const errorDetail = err.response?.data?.detail;
      let errorMessage = 'Failed to upload document';
      
      if (errorDetail) {
        if (Array.isArray(errorDetail)) {
          errorMessage = errorDetail.map((e: any) => e.msg || e.message || JSON.stringify(e)).join(', ');
        } else if (typeof errorDetail === 'string') {
          errorMessage = errorDetail;
        }
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (documentId: string) => {
    if (!confirm('Are you sure you want to delete this document?')) {
      return;
    }

    try {
      await documentsAPI.deleteDocument(documentId);
      setSelectedDocument(null);
      await fetchDocuments();
    } catch (err: any) {
      setError('Failed to delete document.');
      console.error(err);
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="documents-container">
      <div className="documents-sidebar">
        <div className="sidebar-header">
          <h2>Documents</h2>
          <div className="user-info-sidebar">
            <span>{user?.username}</span>
            <button onClick={() => { logout(); navigate('/login'); }} className="logout-button">
              Logout
            </button>
          </div>
        </div>
        
        <div className="upload-section">
          <button 
            onClick={() => setShowUploadForm(!showUploadForm)}
            className="upload-button"
          >
            {showUploadForm ? 'Cancel' : '+ Upload Document'}
          </button>
        </div>

        {showUploadForm && (
          <div className="upload-form">
            <form onSubmit={handleUpload}>
              <input
                type="text"
                placeholder="Document Title"
                value={uploadTitle}
                onChange={(e) => setUploadTitle(e.target.value)}
                className="upload-input"
                required
              />
              <textarea
                placeholder="HTML Content"
                value={uploadContent}
                onChange={(e) => setUploadContent(e.target.value)}
                className="upload-textarea"
                rows={5}
                required
              />
              <button type="submit" disabled={loading} className="submit-button">
                {loading ? 'Uploading...' : 'Upload'}
              </button>
            </form>
          </div>
        )}

        <div className="documents-list">
          {loading && documents.length === 0 ? (
            <div className="empty-documents">Loading documents...</div>
          ) : documents.length === 0 ? (
            <div className="empty-documents">No documents yet. Upload one to get started!</div>
          ) : (
            documents.map((doc) => (
              <div
                key={doc.id}
                className={`document-item ${selectedDocument?.id === doc.id ? 'active' : ''}`}
                onClick={() => fetchDocument(doc.id)}
              >
                <div className="document-title">{doc.title}</div>
                <div className="document-meta">
                  <span className="document-author">by {doc.username}</span>
                  <span className="document-date">{formatTimestamp(doc.timestamp)}</span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      <div className="documents-main">
        <div className="document-header">
          <h1>{selectedDocument ? selectedDocument.title : 'Select a document'}</h1>
          {selectedDocument && selectedDocument.username === user?.username && (
            <button
              onClick={() => handleDelete(selectedDocument.id)}
              className="delete-button"
            >
              Delete
            </button>
          )}
        </div>

        {error && <div className="error-message">{error}</div>}

        {selectedDocument ? (
          <div className="document-viewer">
            <div className="document-info">
              <div className="info-item">
                <strong>Author:</strong> {selectedDocument.username}
              </div>
              <div className="info-item">
                <strong>Created:</strong> {formatTimestamp(selectedDocument.timestamp)}
              </div>
              {selectedDocument.updated_at && (
                <div className="info-item">
                  <strong>Updated:</strong> {formatTimestamp(selectedDocument.updated_at)}
                </div>
              )}
            </div>
            <div className="document-content">
              <iframe
                srcDoc={selectedDocument.content}
                title={selectedDocument.title}
                className="html-preview"
                sandbox="allow-same-origin"
              />
            </div>
          </div>
        ) : (
          <div className="no-selection">
            <p>Select a document from the sidebar to view it</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Documents;

