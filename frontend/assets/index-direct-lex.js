// Configuration for AWS services
// All configuration values are defined here as a single source of truth
const awsConfig = {
    Auth: {
        region: "us-east-1",
        userPoolId: "us-east-1_6F7gh25WJ",
        userPoolWebClientId: "3otgk0c8v1ih81ds1t21u9o6b7",
        mandatorySignIn: true,
        authenticationFlowType: "USER_PASSWORD_AUTH",
    },
    // API Gateway is still used for admin dashboard functionality (meetings management)
    API: {
        endpoints: [
            {
                name: "MeetyAPI",
                endpoint: "https://neoq21uc7d.execute-api.us-east-1.amazonaws.com/dev",
            },
        ],
    },
    // Lex V2 configuration - Generative AI Bot
    lex: {
        botId: "XZGMIGKG5L", // Replace with the MeetyGenerativeBot ID
        botAliasId: "HUCBWNPSPM", // Replace with the manually created "prod" alias ID
        localeId: "en_US",
        region: "us-east-1",
        identityPoolId: "us-east-1:db97f77c-b373-4904-9ec6-f69bc094b74d" // Same as the one used below
    }
};

// Wait for all dependencies to load before initializing
function waitForDependencies() {
    return new Promise((resolve) => {
        const checkDependencies = () => {
            if (typeof AWS !== "undefined" &&
                typeof React !== "undefined" &&
                typeof ReactDOM !== "undefined") {
                resolve();
            } else {
                console.log("Waiting for dependencies to load...", {
                    AWS: typeof AWS !== "undefined",
                    React: typeof React !== "undefined",
                    ReactDOM: typeof ReactDOM !== "undefined"
                });
                setTimeout(checkDependencies, 100);
            }
        };
        checkDependencies();
    });
}

// Initialize Cognito after dependencies are loaded
let userPool, cognitoUser, Auth, API;
async function initializeCognito() {
    await waitForDependencies();

    if (typeof AWS !== "undefined") {
        // Initialize AWS Cognito services using AWS SDK
        const cognitoIdentityServiceProvider = new AWS.CognitoIdentityServiceProvider({
            region: awsConfig.Auth.region
        });

        // Create Auth object compatible with Amplify Auth API
        Auth = {
            currentAuthenticatedUser: () => {
                return new Promise((resolve, reject) => {
                    const authResult = localStorage.getItem('cognitoAuthResult');
                    if (authResult) {
                        try {
                            const parsedResult = JSON.parse(authResult);
                            resolve(parsedResult);
                        } catch (error) {
                            reject(new Error('Invalid stored authentication data'));
                        }
                    } else {
                        reject(new Error('No current user'));
                    }
                });
            },
            currentSession: () => {
                return new Promise((resolve, reject) => {
                    const authResult = localStorage.getItem('cognitoAuthResult');
                    if (authResult) {
                        try {
                            const parsedResult = JSON.parse(authResult);
                            // Create a session-like object
                            const session = {
                                getIdToken: () => ({
                                    getJwtToken: () => parsedResult.idToken
                                }),
                                getAccessToken: () => ({
                                    getJwtToken: () => parsedResult.accessToken
                                }),
                                isValid: () => true // Simplified validation
                            };
                            resolve(session);
                        } catch (error) {
                            reject(new Error('Invalid stored session data'));
                        }
                    } else {
                        reject(new Error('No current session'));
                    }
                });
            },
            signIn: (username, password) => {
                return new Promise((resolve, reject) => {
                    const params = {
                        AuthFlow: 'USER_PASSWORD_AUTH',
                        ClientId: awsConfig.Auth.userPoolWebClientId,
                        AuthParameters: {
                            USERNAME: username,
                            PASSWORD: password
                        }
                    };

                    cognitoIdentityServiceProvider.initiateAuth(params, (err, data) => {
                        if (err) {
                            console.error("Authentication error:", err);
                            reject(err);
                        } else {
                            console.log("Authentication response:", data);

                            // Handle NEW_PASSWORD_REQUIRED challenge
                            if (data.ChallengeName === 'NEW_PASSWORD_REQUIRED') {
                                console.log("User needs to set a new password");

                                // For now, use the same password as the new password
                                // In a production app, you'd prompt the user for a new password
                                const challengeParams = {
                                    ChallengeName: 'NEW_PASSWORD_REQUIRED',
                                    ClientId: awsConfig.Auth.userPoolWebClientId,
                                    Session: data.Session,
                                    ChallengeResponses: {
                                        USERNAME: username,
                                        NEW_PASSWORD: password // Using same password for simplicity
                                    }
                                };

                                cognitoIdentityServiceProvider.respondToAuthChallenge(challengeParams, (challengeErr, challengeData) => {
                                    if (challengeErr) {
                                        console.error("Challenge response error:", challengeErr);
                                        reject(challengeErr);
                                    } else {
                                        console.log("Challenge response:", challengeData);

                                        if (challengeData.AuthenticationResult) {
                                            // Store the authentication result
                                            const authResult = {
                                                username: username,
                                                accessToken: challengeData.AuthenticationResult.AccessToken,
                                                idToken: challengeData.AuthenticationResult.IdToken,
                                                refreshToken: challengeData.AuthenticationResult.RefreshToken
                                            };

                                            console.log("Storing auth result after challenge:", authResult);

                                            // Store in localStorage for persistence
                                            localStorage.setItem('cognitoAuthResult', JSON.stringify(authResult));

                                            resolve(authResult);
                                        } else {
                                            reject(new Error("Authentication result missing after challenge"));
                                        }
                                    }
                                });
                                return;
                            }

                            // Check if AuthenticationResult exists (normal flow)
                            if (!data.AuthenticationResult) {
                                console.error("AuthenticationResult is missing from response:", data);
                                reject(new Error("Authentication result is missing from response"));
                                return;
                            }

                            // Store the authentication result (normal flow)
                            const authResult = {
                                username: username,
                                accessToken: data.AuthenticationResult.AccessToken,
                                idToken: data.AuthenticationResult.IdToken,
                                refreshToken: data.AuthenticationResult.RefreshToken
                            };

                            console.log("Storing auth result:", authResult);

                            // Store in localStorage for persistence
                            localStorage.setItem('cognitoAuthResult', JSON.stringify(authResult));

                            resolve(authResult);
                        }
                    });
                });
            },
            signOut: () => {
                return new Promise((resolve) => {
                    // Clear stored authentication data
                    localStorage.removeItem('cognitoAuthResult');
                    resolve();
                });
            }
        };

        // Create API object for admin functionality
        API = {
            get: async (apiName, path, options = {}) => {
                const endpoint = awsConfig.API.endpoints.find(e => e.name === apiName)?.endpoint;
                if (!endpoint) throw new Error(`API ${apiName} not found`);

                const response = await fetch(`${endpoint}${path}`, {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json',
                        ...options.headers
                    }
                });

                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorText}`);
                }

                const contentType = response.headers.get('content-type');
                if (contentType && contentType.includes('application/json')) {
                    return response.json();
                } else {
                    const text = await response.text();
                    console.warn('Response is not JSON:', text);
                    return { message: text };
                }
            },
            put: async (apiName, path, options = {}) => {
                const endpoint = awsConfig.API.endpoints.find(e => e.name === apiName)?.endpoint;
                if (!endpoint) throw new Error(`API ${apiName} not found`);

                const response = await fetch(`${endpoint}${path}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        ...options.headers
                    },
                    body: JSON.stringify(options.body)
                });

                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorText}`);
                }

                const contentType = response.headers.get('content-type');
                if (contentType && contentType.includes('application/json')) {
                    return response.json();
                } else {
                    const text = await response.text();
                    console.warn('Response is not JSON:', text);
                    return { message: text };
                }
            }
        };

        // Make Auth and API available globally
        window.Auth = Auth;
        window.API = API;

        console.log("Cognito configured successfully:", {
            userPoolId: awsConfig.Auth.userPoolId,
            clientId: awsConfig.Auth.userPoolWebClientId,
            region: awsConfig.Auth.region
        });

        // Initialize the React app after Cognito is ready
        renderApp();
    } else {
        console.error("AWS Cognito SDK failed to load");
    }
}

// Function to render the app after all dependencies are loaded
function renderApp() {
    ReactDOM.render(<App />, document.getElementById("root"));
}

// Start the initialization process
initializeCognito();

// Function to set up AWS credentials after user authentication
window.setupAWSCredentials = async function () {
    try {
        if (typeof Auth !== 'undefined') {
            try {
                // Try to get current session for authenticated users
                const session = await Auth.currentSession();
                const idToken = session.getIdToken().getJwtToken();

                AWS.config.credentials = new AWS.CognitoIdentityCredentials({
                    IdentityPoolId: awsConfig.lex.identityPoolId,
                    Logins: {
                        [`cognito-idp.us-east-1.amazonaws.com/${awsConfig.Auth.userPoolId}`]: idToken
                    }
                });

                // Refresh credentials
                await new Promise((resolve, reject) => {
                    AWS.config.credentials.refresh(err => {
                        if (err) {
                            console.error("Error refreshing credentials:", err);
                            reject(err);
                        } else {
                            console.log("AWS credentials refreshed successfully");
                            resolve();
                        }
                    });
                });

                return true;
            } catch (sessionError) {
                // No current session - user is not authenticated
                // This is normal for unauthenticated users, so don't throw an error
                console.log("No authenticated session found, using anonymous credentials");
                return false;
            }
        }
        return false;
    } catch (error) {
        console.error("Error setting up AWS credentials:", error);
        return false;
    }
};

// Initialize AWS SDK Lex client
let lexRuntimeClient = null;

// Function to initialize the Lex client
async function initializeLexClient() {
    if (typeof AWS !== "undefined") {
        try {
            // Set up anonymous credentials for unauthenticated users
            AWS.config.credentials = new AWS.CognitoIdentityCredentials({
                IdentityPoolId: awsConfig.lex.identityPoolId || 'us-east-1:8543e4cc-c39e-48f0-b0c2-569da7efaa5b'
            });

            // Try to set up authenticated credentials if the user is signed in
            if (typeof window.setupAWSCredentials === "function") {
                try {
                    await window.setupAWSCredentials();
                    console.log("Using authenticated credentials");
                } catch (authError) {
                    console.log("User not authenticated, using anonymous credentials");
                }
            }

            // Make sure credentials are available
            if (!AWS.config.credentials) {
                throw new Error("No AWS credentials available");
            }

            // Create the Lex client
            lexRuntimeClient = new AWS.LexRuntimeV2({
                region: awsConfig.lex.region
            });

            console.log("AWS Lex Runtime V2 client initialized");
            return true;
        } catch (error) {
            console.error("Error initializing Lex client:", error);
            return false;
        }
    }
    return false;
}

// Don't initialize the Lex client immediately - wait until it's needed

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
            // Wait for Auth to be available
            const authToUse = Auth || window.Auth;
            if (!authToUse) {
                console.log("Auth not available yet, waiting...");
                setTimeout(checkAuthState, 500);
                return;
            }

            const user = await authToUse.currentAuthenticatedUser();
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
            const authToUse = Auth || window.Auth;
            if (!authToUse) {
                throw new Error("Authentication service not available");
            }

            const user = await authToUse.signIn(username, password);
            setAuthState({
                isAuthenticated: true,
                user,
                isLoading: false,
            });

            // Initialize Lex client with authenticated credentials
            if (typeof window.setupAWSCredentials === "function") {
                await window.setupAWSCredentials();
                await initializeLexClient();
            }

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
            const authToUse = Auth || window.Auth;
            if (!authToUse) {
                throw new Error("Authentication service not available");
            }

            await authToUse.signOut();
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
            
            // Get current date and date 30 days from now for the date range
            const now = new Date();
            const startDate = now.toISOString().split('T')[0]; // YYYY-MM-DD format
            const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]; // 30 days from now
            
            const response = await API.get("MeetyAPI", `/meetings?startDate=${startDate}&endDate=${endDate}`, {
                headers: {
                    Authorization: `Bearer ${(await Auth.currentSession())
                        .getIdToken()
                        .getJwtToken()}`,
                },
            });
            
            // Handle different response formats from API
            let parsedResponse;
            if (typeof response === 'string') {
                parsedResponse = JSON.parse(response);
            } else if (response && response.message && typeof response.message === 'string') {
                // Handle case where response is wrapped in a message object
                parsedResponse = JSON.parse(response.message);
            } else {
                parsedResponse = response;
            }
            
            console.log("Meetings API Response:", response);
            console.log("Parsed meetings:", parsedResponse);
            
            setMeetings(parsedResponse);
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
                    newStatus: newStatus,
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
                                <th>Attendee Name</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {meetings.map((meeting) => (
                                <tr key={meeting.meetingId}>
                                    <td>{new Date(meeting.date).toLocaleDateString()}</td>
                                    <td>{meeting.startTime} - {meeting.endTime}</td>
                                    <td>{meeting.attendeeName}</td>
                                    <td>{meeting.email}</td>
                                    <td
                                        className={`meeting-status-${meeting.status.toLowerCase()}`}
                                    >
                                        {meeting.status}
                                    </td>
                                    <td>
                                        <button
                                            onClick={() =>
                                                updateMeetingStatus(meeting.meetingId, "approved")
                                            }
                                        >
                                            Approve
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
            
            // Handle different response formats from API
            let parsedResponse;
            if (typeof response === 'string') {
                parsedResponse = JSON.parse(response);
            } else if (response && response.message && typeof response.message === 'string') {
                // Handle case where response is wrapped in a message object
                parsedResponse = JSON.parse(response.message);
            } else {
                parsedResponse = response;
            }
            
            console.log("API Response:", response);
            console.log("Parsed meetings:", parsedResponse);
            
            setPendingMeetings(parsedResponse);
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
                    newStatus: newStatus,
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
                                <th>Attendee Name</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {pendingMeetings.map((meeting) => (
                                <tr key={meeting.meetingId}>
                                    <td>{new Date(meeting.date).toLocaleDateString()}</td>
                                    <td>{meeting.startTime} - {meeting.endTime}</td>
                                    <td>{meeting.attendeeName}</td>
                                    <td>{meeting.email}</td>
                                    <td>{meeting.status}</td>
                                    <td>
                                        <button
                                            onClick={() =>
                                                updateMeetingStatus(meeting.meetingId, "approved")
                                            }
                                        >
                                            Approve
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

// Chatbot Interface Component - Updated to use AWS SDK directly
function ChatbotInterface() {
    const [messages, setMessages] = React.useState([
        {
            text: "Hello! I'm Meety, your meeting assistant. How can I help you today?",
            sender: "bot",
        },
    ]);
    const [input, setInput] = React.useState("");
    const [isLoading, setIsLoading] = React.useState(false);
    const [sessionId, setSessionId] = React.useState("user-" + Date.now());
    const [sessionAttributes, setSessionAttributes] = React.useState({ source: "web-chat" });
    const messagesEndRef = React.useRef(null);

    React.useEffect(() => {
        scrollToBottom();
    }, [messages]);

    // Initialize Lex client when component mounts
    React.useEffect(() => {
        initializeLexClient();
    }, []);

    function scrollToBottom() {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }

    async function handleSendMessage(e) {
        e.preventDefault();

        if (!input.trim()) return;

        // Add user message to chat - ensure text is not split into characters
        const userMessage = { text: input.toString(), sender: "user" };
        setMessages((prev) => [...prev, userMessage]);
        setInput("");
        setIsLoading(true);

        try {
            // Initialize Lex client if not already initialized
            if (!lexRuntimeClient) {
                console.log("Initializing Lex client...");
                const initialized = await initializeLexClient();
                if (!initialized) {
                    throw new Error("Could not initialize Lex client");
                }
            }

            // Ensure credentials are available
            if (!AWS.config.credentials) {
                console.log("No credentials available, initializing anonymous credentials...");
                AWS.config.credentials = new AWS.CognitoIdentityCredentials({
                    IdentityPoolId: awsConfig.lex.identityPoolId
                });

                // Refresh credentials
                await new Promise((resolve, reject) => {
                    AWS.config.credentials.refresh(err => {
                        if (err) {
                            console.error("Error refreshing anonymous credentials:", err);
                            reject(err);
                        } else {
                            console.log("Anonymous credentials refreshed successfully");
                            resolve();
                        }
                    });
                });
            }

            console.log("Sending message to Lex directly:", input);

            // Call Lex V2 directly using AWS SDK
            const params = {
                botId: awsConfig.lex.botId,
                botAliasId: awsConfig.lex.botAliasId,
                localeId: awsConfig.lex.localeId,
                sessionId: sessionId,
                text: input,
                sessionState: {
                    sessionAttributes: sessionAttributes
                }
            };

            lexRuntimeClient.recognizeText(params, (err, data) => {
                if (err) {
                    console.error("Error from Lex:", err);

                    // Check if the error is due to credentials
                    if (err.code === "UnrecognizedClientException" || err.code === "AccessDeniedException") {
                        setMessages((prev) => [
                            ...prev,
                            {
                                text: "You need to sign in to use the chatbot. Please click on the Admin tab to sign in.",
                                sender: "bot",
                            },
                        ]);
                    } else {
                        setMessages((prev) => [
                            ...prev,
                            {
                                text: "Sorry, there was an error processing your request: " + err.message,
                                sender: "bot",
                            },
                        ]);
                    }
                } else {
                    console.log("Lex response:", data);

                    // Update session attributes
                    if (data.sessionState && data.sessionState.sessionAttributes) {
                        setSessionAttributes(data.sessionState.sessionAttributes);
                    }

                    // Add bot response to chat
                    if (data.messages && data.messages.length > 0) {
                        setMessages((prev) => [
                            ...prev,
                            {
                                text: data.messages[0].content || "I'm sorry, I couldn't process your request.",
                                sender: "bot",
                            },
                        ]);
                    } else {
                        setMessages((prev) => [
                            ...prev,
                            {
                                text: "I'm sorry, I couldn't process your request.",
                                sender: "bot",
                            },
                        ]);
                    }
                }
                setIsLoading(false);
            });
        } catch (error) {
            console.error("Error sending message:", error);
            setMessages((prev) => [
                ...prev,
                {
                    text: "Sorry, there was an error processing your request: " + error.message,
                    sender: "bot",
                },
            ]);
            setIsLoading(false);
        }
    }

    return (
        <div className="chatbot-interface">
            <div className="chat-messages">
                {messages.map((msg, index) => (
                    <div key={index} className={`message ${msg.sender}`}>
                        <div className="message-bubble">
                            <span 
                                style={{ 
                                    display: 'inline-block', 
                                    whiteSpace: 'normal',
                                    wordBreak: 'normal',
                                    overflowWrap: 'break-word'
                                }}
                            >
                                {msg.text}
                            </span>
                        </div>
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

// App will be rendered by the renderApp() function after dependencies are loaded

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
    flex-direction: row;
  }

  .message.user {
    justify-content: flex-end;
  }

  .message-bubble {
    padding: 0.75rem 1rem;
    border-radius: 18px;
    max-width: 70%;
    word-wrap: break-word;
    white-space: normal;
    display: block;
    line-height: 1.4;
    writing-mode: horizontal-tb;
    direction: ltr;
    text-orientation: mixed;
    overflow-wrap: break-word;
    word-break: normal;
    text-align: left;
  }

  .message-bubble span {
    display: inline-block !important;
    white-space: normal !important;
    word-wrap: break-word;
    overflow-wrap: break-word;
    word-break: normal;
    letter-spacing: normal !important;
    text-transform: none !important;
    font-family: inherit !important;
  }

  .message.bot .message-bubble {
    background-color: var(--light-bg);
    border-bottom-left-radius: 4px;
  }

  .message.user .message-bubble {
    background-color: var(--primary-color);
    color: var(--white);
    border-bottom-right-radius: 4px;
    text-align: left;
    display: flex;
    align-items: center;
  }

  .message.user .message-bubble span {
    display: inline-block !important;
    white-space: normal !important;
    word-wrap: break-word;
    overflow-wrap: break-word;
    word-break: normal;
    line-height: 1.4;
    letter-spacing: normal !important;
    text-transform: none !important;
    font-family: inherit !important;
    writing-mode: horizontal-tb !important;
    direction: ltr !important;
    text-orientation: mixed !important;
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



















