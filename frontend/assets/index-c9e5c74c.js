(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const l of document.querySelectorAll('link[rel="modulepreload"]'))r(l);new MutationObserver(l=>{for(const o of l)if(o.type==="childList")for(const u of o.addedNodes)u.tagName==="LINK"&&u.rel==="modulepreload"&&r(u)}).observe(document,{childList:!0,subtree:!0});function t(l){const o={};return l.integrity&&(o.integrity=l.integrity),l.referrerPolicy&&(o.referrerPolicy=l.referrerPolicy),l.crossOrigin==="use-credentials"?o.credentials="include":l.crossOrigin==="anonymous"?o.credentials="omit":o.credentials="same-origin",o}function r(l){if(l.ep)return;l.ep=!0;const o=t(l);fetch(l.href,o)}})();function tc(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var Hi={exports:{}},el={},Wi={exports:{}},T={};/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Xt=Symbol.for("react.element"),rc=Symbol.for("react.portal"),lc=Symbol.for("react.fragment"),oc=Symbol.for("react.strict_mode"),uc=Symbol.for("react.profiler"),ic=Symbol.for("react.provider"),sc=Symbol.for("react.context"),ac=Symbol.for("react.forward_ref"),cc=Symbol.for("react.suspense"),fc=Symbol.for("react.memo"),dc=Symbol.for("react.lazy"),ju=Symbol.iterator;function pc(e){return e===null||typeof e!="object"?null:(e=ju&&e[ju]||e["@@iterator"],typeof e=="function"?e:null)}var Qi={isMounted:function(){return!1},enqueueForceUpdate:function(){},enqueueReplaceState:function(){},enqueueSetState:function(){}},Ki=Object.assign,Yi={};function ot(e,n,t){this.props=e,this.context=n,this.refs=Yi,this.updater=t||Qi}ot.prototype.isReactComponent={};ot.prototype.setState=function(e,n){if(typeof e!="object"&&typeof e!="function"&&e!=null)throw Error("setState(...): takes an object of state variables to update or a function which returns an object of state variables.");this.updater.enqueueSetState(this,e,n,"setState")};ot.prototype.forceUpdate=function(e){this.updater.enqueueForceUpdate(this,e,"forceUpdate")};function Xi(){}Xi.prototype=ot.prototype;function $o(e,n,t){this.props=e,this.context=n,this.refs=Yi,this.updater=t||Qi}var Ao=$o.prototype=new Xi;Ao.constructor=$o;Ki(Ao,ot.prototype);Ao.isPureReactComponent=!0;

// AWS Amplify and Cognito Authentication
const awsConfig = {
  Auth: {
    region: 'us-east-1',
    userPoolId: 'us-east-1_GfzCYQpd3', // Will be replaced with actual pool ID from environment
    userPoolWebClientId: '3d3rjg2t10vh45cnrm3fkc2egn', // Will be replaced with actual client ID from environment
    mandatorySignIn: true,
    authenticationFlowType: 'USER_PASSWORD_AUTH'
  },
  API: {
    endpoints: [
      {
        name: "MeetyAPI",
        endpoint: "https://ih183j5ibd.execute-api.us-east-1.amazonaws.com/dev" // Will be replaced with actual API endpoint
      }
    ]
  }
};

// Auth state management
const AuthContext = React.createContext(null);

function AuthProvider({ children }) {
  const [authState, setAuthState] = React.useState({
    isAuthenticated: false,
    user: null,
    isLoading: true
  });

  React.useEffect(() => {
    // Check if user is already signed in
    checkAuthState();
  }, []);

  async function checkAuthState() {
    try {
      const user = await Auth.currentAuthenticatedUser();
      setAuthState({
        isAuthenticated: true,
        user,
        isLoading: false
      });
    } catch (error) {
      setAuthState({
        isAuthenticated: false,
        user: null,
        isLoading: false
      });
    }
  }

  async function signIn(username, password) {
    try {
      const user = await Auth.signIn(username, password);
      setAuthState({
        isAuthenticated: true,
        user,
        isLoading: false
      });
      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error.message || "Failed to sign in" 
      };
    }
  }

  async function signOut() {
    try {
      await Auth.signOut();
      setAuthState({
        isAuthenticated: false,
        user: null,
        isLoading: false
      });
      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error.message || "Failed to sign out" 
      };
    }
  }

  return (
    <AuthContext.Provider value={{ 
      ...authState, 
      signIn, 
      signOut 
    }}>
      {children}
    </AuthContext.Provider>
  );
}

// Meeting Management Components
function MeetingCalendar() {
  const [meetings, setMeetings] = React.useState([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState(null);
  const { isAuthenticated } = React.useContext(AuthContext);

  React.useEffect(() => {
    if (isAuthenticated) {
      fetchMeetings();
    }
  }, [isAuthenticated]);

  async function fetchMeetings() {
    try {
      setIsLoading(true);
      const response = await API.get('MeetyAPI', '/meetings', {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}`
        }
      });
      setMeetings(response);
      setIsLoading(false);
    } catch (err) {
      setError(err.message || "Failed to fetch meetings");
      setIsLoading(false);
    }
  }

  async function updateMeetingStatus(meetingId, newStatus) {
    try {
      await API.put('MeetyAPI', '/status', {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}`
        },
        body: {
          meetingId,
          status: newStatus
        }
      });
      // Refresh the list after update
      fetchMeetings();
    } catch (err) {
      setError(err.message || "Failed to update meeting status");
    }
  }

  if (!isAuthenticated) {
    return <div>Please sign in to view the calendar</div>;
  }

  if (isLoading) {
    return <div>Loading meetings...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="meeting-calendar">
      <h2>Meeting Calendar</h2>
      <div className="calendar-container">
        {meetings.length === 0 ? (
          <p>No meetings scheduled</p>
        ) : (
          <table className="meeting-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Time</th>
                <th>Subject</th>
                <th>Attendees</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {meetings.map(meeting => (
                <tr key={meeting.meetingId}>
                  <td>{new Date(meeting.date).toLocaleDateString()}</td>
                  <td>{meeting.time}</td>
                  <td>{meeting.subject}</td>
                  <td>{meeting.attendees.join(', ')}</td>
                  <td className={`meeting-status-${meeting.status.toLowerCase()}`}>{meeting.status}</td>
                  <td>
                    <button onClick={() => updateMeetingStatus(meeting.meetingId, 'confirmed')}>
                      Confirm
                    </button>
                    <button onClick={() => updateMeetingStatus(meeting.meetingId, 'cancelled')}>
                      Cancel
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

function PendingMeetings() {
  const [pendingMeetings, setPendingMeetings] = React.useState([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState(null);
  const { isAuthenticated } = React.useContext(AuthContext);

  React.useEffect(() => {
    if (isAuthenticated) {
      fetchPendingMeetings();
    }
  }, [isAuthenticated]);

  async function fetchPendingMeetings() {
    try {
      setIsLoading(true);
      const response = await API.get('MeetyAPI', '/pending', {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}`
        }
      });
      setPendingMeetings(response);
      setIsLoading(false);
    } catch (err) {
      setError(err.message || "Failed to fetch pending meetings");
      setIsLoading(false);
    }
  }

  async function updateMeetingStatus(meetingId, newStatus) {
    try {
      await API.put('MeetyAPI', '/status', {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}`
        },
        body: {
          meetingId,
          status: newStatus
        }
      });
      // Refresh the list after update
      fetchPendingMeetings();
    } catch (err) {
      setError(err.message || "Failed to update meeting status");
    }
  }

  if (!isAuthenticated) {
    return <div>Please sign in to view pending meetings</div>;
  }

  if (isLoading) {
    return <div>Loading pending meetings...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="pending-meetings">
      <h2>Pending Meetings</h2>
      <div className="pending-container">
        {pendingMeetings.length === 0 ? (
          <p>No pending meetings</p>
        ) : (
          <table className="meeting-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Time</th>
                <th>Subject</th>
                <th>Attendees</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {pendingMeetings.map(meeting => (
                <tr key={meeting.meetingId}>
                  <td>{new Date(meeting.date).toLocaleDateString()}</td>
                  <td>{meeting.time}</td>
                  <td>{meeting.subject}</td>
                  <td>{meeting.attendees.join(', ')}</td>
                  <td>
                    <button onClick={() => updateMeetingStatus(meeting.meetingId, 'confirmed')}>
                      Confirm
                    </button>
                    <button onClick={() => updateMeetingStatus(meeting.meetingId, 'cancelled')}>
                      Cancel
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

// Admin Login Component
function AdminLogin() {
  const [username, setUsername] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [error, setError] = React.useState('');
  const [isLoading, setIsLoading] = React.useState(false);
  const { signIn } = React.useContext(AuthContext);

  async function handleSubmit(e) {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    if (!username || !password) {
      setError('Username and password are required');
      setIsLoading(false);
      return;
    }

    try {
      const result = await signIn(username, password);
      if (!result.success) {
        setError(result.error);
      }
    } catch (err) {
      setError(err.message || 'Failed to sign in');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="admin-login">
      <h2>Admin Login</h2>
      {error && <div className="error-message">{error}</div>}
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="username">Username</label>
          <input
            type="text"
            id="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            disabled={isLoading}
          />
        </div>
        <div className="form-group">
          <label htmlFor="password">Password</label>
          <input
            type="password"
            id="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={isLoading}
          />
        </div>
        <button type="submit" disabled={isLoading}>
          {isLoading ? 'Signing in...' : 'Sign In'}
        </button>
      </form>
    </div>
  );
}

// Admin Dashboard Component
function AdminDashboard() {
  const [activeTab, setActiveTab] = React.useState('pending');
  const { isAuthenticated, signOut, user } = React.useContext(AuthContext);

  if (!isAuthenticated) {
    return <AdminLogin />;
  }

  return (
    <div className="admin-dashboard">
      <div className="dashboard-header">
        <h1>Meety Admin Dashboard</h1>
        <div className="user-info">
          <span>Welcome, {user.username}</span>
          <button onClick={signOut}>Sign Out</button>
        </div>
      </div>
      
      <div className="dashboard-tabs">
        <button 
          className={activeTab === 'pending' ? 'active' : ''} 
          onClick={() => setActiveTab('pending')}
        >
          Pending Meetings
        </button>
        <button 
          className={activeTab === 'calendar' ? 'active' : ''} 
          onClick={() => setActiveTab('calendar')}
        >
          Calendar
        </button>
      </div>
      
      <div className="dashboard-content">
        {activeTab === 'pending' && <PendingMeetings />}
        {activeTab === 'calendar' && <MeetingCalendar />}
      </div>
    </div>
  );
}

// Main App Component with Routing
function App() {
  const [view, setView] = React.useState('chat'); // 'chat' or 'admin'
  
  return (
    <AuthProvider>
      <div className="app-container">
        <nav className="app-nav">
          <div className="app-logo">
            <img src="/assets/penguin-ca53156a.png" alt="Meety Logo" />
            <h1>Meety</h1>
          </div>
          <div className="nav-links">
            <button 
              className={view === 'chat' ? 'active' : ''} 
              onClick={() => setView('chat')}
            >
              Chatbot
            </button>
            <button 
              className={view === 'admin' ? 'active' : ''} 
              onClick={() => setView('admin')}
            >
              Admin
            </button>
          </div>
        </nav>
        
        <main className="app-content">
          {view === 'chat' && <ChatbotInterface />}
          {view === 'admin' && <AdminDashboard />}
        </main>
        
        <footer className="app-footer">
          <p>&copy; 2025 Meety - AI-powered Meeting Management</p>
        </footer>
      </div>
    </AuthProvider>
  );
}

// Chatbot Interface Component
function ChatbotInterface() {
  const [messages, setMessages] = React.useState([
    { 
      text: "Hello! I'm Meety, your meeting assistant. How can I help you today?", 
      sender: 'bot' 
    }
  ]);
  const [input, setInput] = React.useState('');
  const [isLoading, setIsLoading] = React.useState(false);
  const messagesEndRef = React.useRef(null);

  React.useEffect(() => {
    scrollToBottom();
  }, [messages]);

  function scrollToBottom() {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }

  async function handleSendMessage(e) {
    e.preventDefault();
    
    if (!input.trim()) return;
    
    // Add user message to chat
    const userMessage = { text: input, sender: 'user' };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);
    
    try {
      // Send message to chatbot API
      const response = await fetch('https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev/chatbot', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message: input })
      });
      
      const data = await response.json();
      
      // Add bot response to chat
      setMessages(prev => [...prev, { 
        text: data.message || "I'm sorry, I couldn't process your request.", 
        sender: 'bot' 
      }]);
    } catch (error) {
      console.error('Error sending message:', error);
      setMessages(prev => [...prev, { 
        text: "Sorry, there was an error processing your request.", 
        sender: 'bot' 
      }]);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="chatbot-interface">
      <div className="chat-messages">
        {messages.map((msg, index) => (
          <div key={index} className={`message ${msg.sender}`}>
            <div className="message-bubble">{msg.text}</div>
          </div>
        ))}
        {isLoading && (
          <div className="message bot">
            <div className="message-bubble typing">
              <span>.</span><span>.</span><span>.</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>
      
      <form className="chat-input-form" onSubmit={handleSendMessage}>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type your message here..."
          disabled={isLoading}
        />
        <button type="submit" disabled={isLoading || !input.trim()}>
          Send
        </button>
      </form>
    </div>
  );
}

// Calendar View Component for Admin Dashboard
function CalendarView() {
  const [meetings, setMeetings] = React.useState([]);
  const [selectedDate, setSelectedDate] = React.useState(new Date());
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState(null);
  const [selectedMeeting, setSelectedMeeting] = React.useState(null);
  const { isAuthenticated } = React.useContext(AuthContext);

  React.useEffect(() => {
    if (isAuthenticated) {
      fetchMeetings();
    }
  }, [isAuthenticated, selectedDate]);

  async function fetchMeetings() {
    try {
      setIsLoading(true);
      const response = await API.get('MeetyAPI', '/meetings', {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}`
        }
      });
      setMeetings(response);
      setIsLoading(false);
    } catch (err) {
      setError(err.message || "Failed to fetch meetings");
      setIsLoading(false);
    }
  }

  function getDaysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate();
  }

  function getFirstDayOfMonth(year, month) {
    return new Date(year, month, 1).getDay();
  }

  function generateCalendarDays() {
    const year = selectedDate.getFullYear();
    const month = selectedDate.getMonth();
    const daysInMonth = getDaysInMonth(year, month);
    const firstDay = getFirstDayOfMonth(year, month);
    
    const days = [];
    
    // Add empty cells for days before the first day of the month
    for (let i = 0; i < firstDay; i++) {
      days.push({ day: null, meetings: [] });
    }
    
    // Add days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day);
      const dateString = date.toISOString().split('T')[0];
      
      const dayMeetings = meetings.filter(meeting => {
        const meetingDate = new Date(meeting.date);
        return meetingDate.getFullYear() === year && 
               meetingDate.getMonth() === month && 
               meetingDate.getDate() === day;
      });
      
      days.push({ day, meetings: dayMeetings });
    }
    
    return days;
  }

  function handlePrevMonth() {
    setSelectedDate(new Date(selectedDate.getFullYear(), selectedDate.getMonth() - 1, 1));
  }

  function handleNextMonth() {
    setSelectedDate(new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, 1));
  }

  function handleMeetingClick(meeting) {
    setSelectedMeeting(meeting);
  }

  function closeModal() {
    setSelectedMeeting(null);
  }

  async function updateMeetingStatus(meetingId, newStatus) {
    try {
      await API.put('MeetyAPI', '/status', {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}`
        },
        body: {
          meetingId,
          status: newStatus
        }
      });
      
      // Close modal and refresh meetings
      setSelectedMeeting(null);
      fetchMeetings();
    } catch (err) {
      setError(err.message || "Failed to update meeting status");
    }
  }

  if (!isAuthenticated) {
    return <div>Please sign in to view the calendar</div>;
  }

  if (isLoading) {
    return <div>Loading calendar...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  const calendarDays = generateCalendarDays();
  const monthNames = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"];
  const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return (
    <div className="calendar-view-container">
      <div className="calendar-header">
        <button onClick={handlePrevMonth}>&lt;</button>
        <h2>{monthNames[selectedDate.getMonth()]} {selectedDate.getFullYear()}</h2>
        <button onClick={handleNextMonth}>&gt;</button>
      </div>
      
      <div className="calendar-day-names">
        {dayNames.map(day => (
          <div key={day} className="day-name">{day}</div>
        ))}
      </div>
      
      <div className="calendar-view">
        {calendarDays.map((day, index) => (
          <div key={index} className={`calendar-day ${!day.day ? 'empty' : ''}`}>
            {day.day && (
              <>
                <div className="calendar-day-header">{day.day}</div>
                <div className="calendar-day-content">
                  {day.meetings.map(meeting => (
                    <div 
                      key={meeting.meetingId} 
                      className={`calendar-meeting meeting-status-${meeting.status.toLowerCase()}`}
                      onClick={() => handleMeetingClick(meeting)}
                    >
                      {meeting.time} - {meeting.subject}
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        ))}
      </div>
      
      {selectedMeeting && (
        <div className="meeting-modal">
          <div className="meeting-modal-content">
            <div className="meeting-modal-header">
              <h3>Meeting Details</h3>
              <button className="meeting-modal-close" onClick={closeModal}>&times;</button>
            </div>
            <div className="meeting-modal-body">
              <p><strong>Subject:</strong> {selectedMeeting.subject}</p>
              <p><strong>Date:</strong> {new Date(selectedMeeting.date).toLocaleDateString()}</p>
              <p><strong>Time:</strong> {selectedMeeting.time}</p>
              <p><strong>Attendees:</strong> {selectedMeeting.attendees.join(', ')}</p>
              <p><strong>Status:</strong> <span className={`meeting-status-${selectedMeeting.status.toLowerCase()}`}>{selectedMeeting.status}</span></p>
              {selectedMeeting.notes && <p><strong>Notes:</strong> {selectedMeeting.notes}</p>}
            </div>
            <div className="meeting-modal-footer">
              <button onClick={() => updateMeetingStatus(selectedMeeting.meetingId, 'confirmed')}>
                Confirm
              </button>
              <button onClick={() => updateMeetingStatus(selectedMeeting.meetingId, 'cancelled')}>
                Cancel
              </button>
              <button onClick={closeModal}>Close</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Initialize AWS Amplify
function initializeAmplify() {
  // This would normally be done with the actual Amplify library
  console.log("AWS Amplify initialized with config:", awsConfig);
}

// Render the App
document.addEventListener('DOMContentLoaded', () => {
  initializeAmplify();
  const rootElement = document.getElementById('root');
  ReactDOM.render(<App />, rootElement);
});

// CSS Styles
const styles = `
  :root {
    --primary-color: #4a6fa5;
    --secondary-color: #166088;
    --accent-color: #4cb5ab;
    --text-color: #333;
    --light-bg: #f5f7fa;
    --white: #ffffff;
    --error-color: #e74c3c;
    --success-color: #2ecc71;
    --border-radius: 8px;
    --box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: var(--text-color);
    background-color: var(--light-bg);
  }

  .app-container {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
  }

  .app-nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 2rem;
    background-color: var(--white);
    box-shadow: var(--box-shadow);
  }

  .app-logo {
    display: flex;
    align-items: center;
  }

  .app-logo img {
    height: 40px;
    margin-right: 10px;
  }

  .app-logo h1 {
    font-size: 1.5rem;
    color: var(--primary-color);
  }

  .nav-links button {
    background: none;
    border: none;
    padding: 0.5rem 1rem;
    margin-left: 1rem;
    cursor: pointer;
    font-size: 1rem;
    color: var(--text-color);
    transition: color 0.3s;
  }

  .nav-links button:hover,
  .nav-links button.active {
    color: var(--primary-color);
    font-weight: bold;
  }

  .app-content {
    flex: 1;
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
    width: 100%;
  }

  .app-footer {
    padding: 1rem;
    text-align: center;
    background-color: var(--white);
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.05);
  }

  /* Chatbot Interface */
  .chatbot-interface {
    display: flex;
    flex-direction: column;
    height: 70vh;
    background-color: var(--white);
    border-radius: var(--border-radius);
    box-shadow: var(--box-shadow);
    overflow: hidden;
  }

  .chat-messages {
    flex: 1;
    padding: 1rem;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
  }

  .message {
    margin-bottom: 1rem;
    display: flex;
  }

  .message.user {
    justify-content: flex-end;
  }

  .message-bubble {
    padding: 0.75rem 1rem;
    border-radius: 18px;
    max-width: 70%;
    word-wrap: break-word;
  }

  .message.bot .message-bubble {
    background-color: var(--light-bg);
    border-bottom-left-radius: 4px;
  }

  .message.user .message-bubble {
    background-color: var(--primary-color);
    color: var(--white);
    border-bottom-right-radius: 4px;
  }

  .typing span {
    display: inline-block;
    animation: dotTyping 1.5s infinite;
    margin-right: 3px;
  }

  .typing span:nth-child(2) {
    animation-delay: 0.5s;
  }

  .typing span:nth-child(3) {
    animation-delay: 1s;
  }

  @keyframes dotTyping {
    0% { transform: translateY(0); }
    25% { transform: translateY(-5px); }
    50% { transform: translateY(0); }
  }

  .chat-input-form {
    display: flex;
    padding: 1rem;
    background-color: var(--light-bg);
  }

  .chat-input-form input {
    flex: 1;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: var(--border-radius) 0 0 var(--border-radius);
    font-size: 1rem;
  }

  .chat-input-form button {
    padding: 0.75rem 1.5rem;
    background-color: var(--primary-color);
    color: var(--white);
    border: none;
    border-radius: 0 var(--border-radius) var(--border-radius) 0;
    cursor: pointer;
    font-size: 1rem;
    transition: background-color 0.3s;
  }

  .chat-input-form button:hover {
    background-color: var(--secondary-color);
  }

  .chat-input-form button:disabled {
    background-color: #ccc;
    cursor: not-allowed;
  }

  /* Admin Dashboard */
  .admin-dashboard {
    background-color: var(--white);
    border-radius: var(--border-radius);
    box-shadow: var(--box-shadow);
    padding: 2rem;
  }

  .dashboard-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
  }

  .user-info {
    display: flex;
    align-items: center;
  }

  .user-info span {
    margin-right: 1rem;
  }

  .user-info button {
    padding: 0.5rem 1rem;
    background-color: var(--light-bg);
    border: 1px solid #ddd;
    border-radius: var(--border-radius);
    cursor: pointer;
    transition: background-color 0.3s;
  }

  .user-info button:hover {
    background-color: #e9ecef;
  }

  .dashboard-tabs {
    display: flex;
    margin-bottom: 2rem;
    border-bottom: 1px solid #ddd;
  }

  .dashboard-tabs button {
    padding: 0.75rem 1.5rem;
    background: none;
    border: none;
    border-bottom: 3px solid transparent;
    cursor: pointer;
    font-size: 1rem;
    transition: all 0.3s;
  }

  .dashboard-tabs button.active {
    border-bottom-color: var(--primary-color);
    color: var(--primary-color);
    font-weight: bold;
  }

  /* Meeting Tables */
  .meeting-table {
    width: 100%;
    border-collapse: collapse;
  }

  .meeting-table th,
  .meeting-table td {
    padding: 0.75rem;
    text-align: left;
    border-bottom: 1px solid #ddd;
  }

  .meeting-table th {
    background-color: var(--light-bg);
    font-weight: bold;
  }

  .meeting-table tr:hover {
    background-color: #f9f9f9;
  }

  .meeting-table button {
    padding: 0.4rem 0.8rem;
    margin-right: 0.5rem;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9rem;
  }

  .meeting-table button:first-child {
    background-color: var(--success-color);
    color: white;
  }

  .meeting-table button:last-child {
    background-color: var(--error-color);
    color: white;
  }

  /* Admin Login */
  .admin-login {
    max-width: 400px;
    margin: 0 auto;
    padding: 2rem;
    background-color: var(--white);
    border-radius: var(--border-radius);
    box-shadow: var(--box-shadow);
  }

  .admin-login h2 {
    margin-bottom: 1.5rem;
    text-align: center;
    color: var(--primary-color);
  }

  .error-message {
    padding: 0.75rem;
    margin-bottom: 1rem;
    background-color: #fde8e8;
    color: var(--error-color);
    border-radius: var(--border-radius);
    text-align: center;
  }

  .form-group {
    margin-bottom: 1.5rem;
  }

  .form-group label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: bold;
  }

  .form-group input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: var(--border-radius);
    font-size: 1rem;
  }

  .admin-login button {
    width: 100%;
    padding: 0.75rem;
    background-color: var(--primary-color);
    color: var(--white);
    border: none;
    border-radius: var(--border-radius);
    cursor: pointer;
    font-size: 1rem;
    transition: background-color 0.3s;
  }

  .admin-login button:hover {
    background-color: var(--secondary-color);
  }

  .admin-login button:disabled {
    background-color: #ccc;
    cursor: not-allowed;
  }

  /* Calendar View */
  .calendar-view-container {
    background-color: var(--white);
    border-radius: var(--border-radius);
    padding: 1rem;
  }

  .calendar-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }

  .calendar-header button {
    background: none;
    border: 1px solid #ddd;
    border-radius: 50%;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
  }

  .calendar-day-names {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 8px;
    margin-bottom: 8px;
  }

  .day-name {
    text-align: center;
    font-weight: bold;
    padding: 8px;
  }

  .calendar-view {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 8px;
  }

  .calendar-day {
    border: 1px solid #ddd;
    min-height: 100px;
    padding: 8px;
    background-color: var(--white);
  }

  .calendar-day.empty {
    background-color: #f9f9f9;
  }

  .calendar-day-header {
    font-weight: bold;
    text-align: right;
    margin-bottom: 8px;
    padding-bottom: 4px;
    border-bottom: 1px solid #eee;
  }

  .calendar-meeting {
    margin-bottom: 4px;
    padding: 4px;
    border-radius: 4px;
    background-color: #e3f2fd;
    font-size: 0.8rem;
    cursor: pointer;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .meeting-status-pending {
    color: #f39c12;
    font-weight: bold;
  }

  .meeting-status-confirmed {
    color: #2ecc71;
    font-weight: bold;
  }

  .meeting-status-cancelled {
    color: #e74c3c;
    font-weight: bold;
  }

  /* Meeting Modal */
  .meeting-modal {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
  }

  .meeting-modal-content {
    background-color: white;
    padding: 2rem;
    border-radius: 8px;
    width: 500px;
    max-width: 90%;
  }

  .meeting-modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }

  .meeting-modal-close {
    background: none;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
  }

  .meeting-modal-body {
    margin-bottom: 1rem;
  }

  .meeting-modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 1rem;
  }

  .meeting-modal-footer button:first-child {
    background-color: var(--success-color);
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    cursor: pointer;
  }

  .meeting-modal-footer button:nth-child(2) {
    background-color: var(--error-color);
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    cursor: pointer;
  }

  .meeting-modal-footer button:last-child {
    background-color: #ccc;
    color: var(--text-color);
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    cursor: pointer;
  }
`;

// Add styles to document
const styleElement = document.createElement('style');
styleElement.textContent = styles;
document.head.appendChild(styleElement);