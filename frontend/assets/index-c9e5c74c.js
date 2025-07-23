// Use the AWS config from the HTML file
const awsConfig = window.awsConfig || {
  Auth: {
    region: "us-east-1",
    userPoolId: "us-east-1_8zTUU9NQO",
    userPoolWebClientId: "57nib32g1o9mn5g0pmutnvb852",
    mandatorySignIn: true,
    authenticationFlowType: "USER_PASSWORD_AUTH",
  },
  API: {
    endpoints: [
      {
        name: "MeetyAPI",
        endpoint: "https://oum5xgcpjb.execute-api.us-east-1.amazonaws.com/dev",
      },
    ],
  },
};

// Initialize Amplify
if (typeof Amplify !== "undefined") {
  Amplify.configure(awsConfig);
  console.log("Amplify configured with:", awsConfig);
}

// Auth state management
const AuthContext = React.createContext(null);

function AuthProvider({ children }) {
  const [authState, setAuthState] = React.useState({
    isAuthenticated: false,
    user: null,
    isLoading: true,
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
        isLoading: false,
      });
    } catch (error) {
      setAuthState({
        isAuthenticated: false,
        user: null,
        isLoading: false,
      });
    }
  }

  async function signIn(username, password) {
    try {
      const user = await Auth.signIn(username, password);
      setAuthState({
        isAuthenticated: true,
        user,
        isLoading: false,
      });
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error.message || "Failed to sign in",
      };
    }
  }

  async function signOut() {
    try {
      await Auth.signOut();
      setAuthState({
        isAuthenticated: false,
        user: null,
        isLoading: false,
      });
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error.message || "Failed to sign out",
      };
    }
  }

  return (
    <AuthContext.Provider
      value={{
        ...authState,
        signIn,
        signOut,
      }}
    >
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
      const response = await API.get("MeetyAPI", "/meetings", {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession())
            .getIdToken()
            .getJwtToken()}`,
        },
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
      await API.put("MeetyAPI", "/status", {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession())
            .getIdToken()
            .getJwtToken()}`,
        },
        body: {
          meetingId,
          status: newStatus,
        },
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
              {meetings.map((meeting) => (
                <tr key={meeting.meetingId}>
                  <td>{new Date(meeting.date).toLocaleDateString()}</td>
                  <td>{meeting.time}</td>
                  <td>{meeting.subject}</td>
                  <td>{meeting.attendees.join(", ")}</td>
                  <td
                    className={`meeting-status-${meeting.status.toLowerCase()}`}
                  >
                    {meeting.status}
                  </td>
                  <td>
                    <button
                      onClick={() =>
                        updateMeetingStatus(meeting.meetingId, "confirmed")
                      }
                    >
                      Confirm
                    </button>
                    <button
                      onClick={() =>
                        updateMeetingStatus(meeting.meetingId, "cancelled")
                      }
                    >
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
      const response = await API.get("MeetyAPI", "/pending", {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession())
            .getIdToken()
            .getJwtToken()}`,
        },
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
      await API.put("MeetyAPI", "/status", {
        headers: {
          Authorization: `Bearer ${(await Auth.currentSession())
            .getIdToken()
            .getJwtToken()}`,
        },
        body: {
          meetingId,
          status: newStatus,
        },
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
              {pendingMeetings.map((meeting) => (
                <tr key={meeting.meetingId}>
                  <td>{new Date(meeting.date).toLocaleDateString()}</td>
                  <td>{meeting.time}</td>
                  <td>{meeting.subject}</td>
                  <td>{meeting.attendees.join(", ")}</td>
                  <td>
                    <button
                      onClick={() =>
                        updateMeetingStatus(meeting.meetingId, "confirmed")
                      }
                    >
                      Confirm
                    </button>
                    <button
                      onClick={() =>
                        updateMeetingStatus(meeting.meetingId, "cancelled")
                      }
                    >
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
  const [username, setUsername] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState("");
  const [isLoading, setIsLoading] = React.useState(false);
  const { signIn } = React.useContext(AuthContext);

  async function handleSubmit(e) {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    if (!username || !password) {
      setError("Username and password are required");
      setIsLoading(false);
      return;
    }

    try {
      const result = await signIn(username, password);
      if (!result.success) {
        setError(result.error);
      }
    } catch (err) {
      setError(err.message || "Failed to sign in");
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
          {isLoading ? "Signing in..." : "Sign In"}
        </button>
      </form>
    </div>
  );
}

// Admin Dashboard Component
function AdminDashboard() {
  const [activeTab, setActiveTab] = React.useState("pending");
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
          className={activeTab === "pending" ? "active" : ""}
          onClick={() => setActiveTab("pending")}
        >
          Pending Meetings
        </button>
        <button
          className={activeTab === "calendar" ? "active" : ""}
          onClick={() => setActiveTab("calendar")}
        >
          Calendar
        </button>
      </div>

      <div className="dashboard-content">
        {activeTab === "pending" && <PendingMeetings />}
        {activeTab === "calendar" && <MeetingCalendar />}
      </div>
    </div>
  );
}

// Main App Component with Routing
function App() {
  const [view, setView] = React.useState("chat"); // 'chat' or 'admin'

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
              className={view === "chat" ? "active" : ""}
              onClick={() => setView("chat")}
            >
              Chatbot
            </button>
            <button
              className={view === "admin" ? "active" : ""}
              onClick={() => setView("admin")}
            >
              Admin
            </button>
          </div>
        </nav>

        <main className="app-content">
          {view === "chat" && <ChatbotInterface />}
          {view === "admin" && <AdminDashboard />}
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
      sender: "bot",
    },
  ]);
  const [input, setInput] = React.useState("");
  const [isLoading, setIsLoading] = React.useState(false);
  const messagesEndRef = React.useRef(null);

  React.useEffect(() => {
    scrollToBottom();
  }, [messages]);

  function scrollToBottom() {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }

  async function handleSendMessage(e) {
    e.preventDefault();

    if (!input.trim()) return;

    // Add user message to chat
    const userMessage = { text: input, sender: "user" };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setIsLoading(true);

    try {
      // Send message to chatbot API using the configured endpoint
      const apiUrl = awsConfig.API.endpoints[0].endpoint + "/chatbot";
      console.log("Sending message to API:", apiUrl);
      
      // Simple fetch without credentials (for wildcard origin)
      const response = await fetch(
        apiUrl,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Origin": window.location.origin
          },
          body: JSON.stringify({ 
            message: input,
            userId: "user-" + Date.now(),
            sessionAttributes: { source: "web-chat" }
          }),
          mode: "cors"
          // No credentials with wildcard origin
        }
      );

      const data = await response.json();

      // Add bot response to chat
      setMessages((prev) => [
        ...prev,
        {
          text: data.message || "I'm sorry, I couldn't process your request.",
          sender: "bot",
        },
      ]);
    } catch (error) {
      console.error("Error sending message:", error);
      setMessages((prev) => [
        ...prev,
        {
          text: "Sorry, there was an error processing your request.",
          sender: "bot",
        },
      ]);
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
              <span>.</span>
              <span>.</span>
              <span>.</span>
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

// Render the App
ReactDOM.render(<App />, document.getElementById("root"));

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
`;

// Add styles to document
const styleElement = document.createElement("style");
styleElement.textContent = styles;
document.head.appendChild(styleElement);
