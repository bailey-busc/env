# Software Engineering Task Ticket Template

_Use this template to provide Claude/your LLM of choice with structured, comprehensive information for software engineering tasks. Fill out all relevant sections with specific details to get the best implementation results._

---

## 📋 **Task Overview**

### **Task Type** _(Select one)_

- [ ] 🆕 **New Feature** - Adding new functionality
- [ ] 🐛 **Bug Fix** - Fixing existing issues
- [ ] 🔧 **Refactor** - Improving existing code without changing functionality
- [ ] ⚡ **Performance** - Optimizing speed, memory, or efficiency
- [ ] 🎨 **UI/UX** - Interface improvements
- [ ] 🔗 **Integration** - Connecting with external systems
- [ ] 📚 **Documentation** - Code comments, README, or technical docs
- [ ] 🧪 **Testing** - Adding or improving tests
- [ ] 🔒 **Security** - Security improvements or fixes

### **Priority Level**

- [ ] 🔴 **Critical** - Blocking other work or production issue
- [ ] 🟡 **High** - Important for current sprint/milestone
- [ ] 🟢 **Medium** - Standard priority
- [ ] 🔵 **Low** - Nice to have, can be delayed

---

## 🎯 **Objective & Context**

### **What needs to be accomplished?**

_Provide a clear, concise description of what you want implemented_

**Example:**

> Create a user authentication system that allows users to register, login, and maintain sessions using JWT tokens. The system should integrate with our existing user database and provide role-based access control.

### **Why is this needed?**

_Explain the business value, problem being solved, or improvement being made_

**Example:**

> Currently, our application has no user authentication, which prevents us from personalizing user experiences and securing sensitive data. This feature is required before we can launch user-specific dashboards.

### **Success Criteria**

_Define what "done" looks like - be specific and measurable_

**Example:**

- [ ] Users can register with email/password
- [ ] Users can login and receive a JWT token
- [ ] Protected routes require valid authentication
- [ ] User sessions persist for 7 days
- [ ] Admin users can access admin-only features
- [ ] All endpoints have appropriate error handling

---

## 🏗️ **Technical Specifications**

### **Technology Stack**

_Specify the technologies, frameworks, and tools to use_

**Frontend:**

- Framework: _(e.g., React 18, Vue 3, vanilla JS)_
- Styling: _(e.g., Tailwind CSS, styled-components, CSS modules)_
- State Management: _(e.g., Redux, Zustand, Context API)_

**Backend:**

- Runtime/Language: _(e.g., Node.js, Python Flask, Java Spring)_
- Database: _(e.g., PostgreSQL, MongoDB, SQLite)_
- Authentication: _(e.g., JWT, OAuth, Passport.js)_

**Other:**

- Testing: _(e.g., Jest, Cypress, Pytest)_
- Build Tools: _(e.g., Vite, Webpack, Parcel)_

### **Architecture Constraints**

_Specify any architectural requirements or limitations_

**Example:**

- Must follow existing REST API patterns
- Should use existing database schema where possible
- Must be compatible with current Docker deployment setup
- Should follow company coding standards (ESLint config provided)

---

## 📐 **Detailed Requirements**

### **Functional Requirements**

_Break down exactly what the feature should do_

1. **User Registration**

   - Accept email, password, and optional profile fields
   - Validate email format and password strength
   - Check for duplicate email addresses
   - Send confirmation email (if email service is configured)

2. **User Login**

   - Accept email/password credentials
   - Return JWT token on successful authentication
   - Handle "remember me" functionality
   - Provide clear error messages for invalid credentials

3. **Session Management**
   - JWT tokens expire after 7 days
   - Refresh token mechanism for seamless renewal
   - Logout functionality that invalidates tokens

### **Data Requirements**

_Specify what data needs to be stored, processed, or displayed_

**User Model:**

```javascript
{
  id: UUID,
  email: string (unique),
  password: string (hashed),
  role: enum ['user', 'admin'],
  createdAt: timestamp,
  lastLogin: timestamp,
  isVerified: boolean
}
```

**JWT Payload:**

```javascript
{
  userId: UUID,
  email: string,
  role: string,
  exp: timestamp
}
```

### **API Endpoints**

_Define the expected API structure_

| Method | Endpoint             | Description       | Request Body                         | Response        |
| ------ | -------------------- | ----------------- | ------------------------------------ | --------------- |
| POST   | `/api/auth/register` | User registration | `{email, password, confirmPassword}` | `{user, token}` |
| POST   | `/api/auth/login`    | User login        | `{email, password}`                  | `{user, token}` |
| POST   | `/api/auth/logout`   | User logout       | `{}`                                 | `{message}`     |
| GET    | `/api/auth/me`       | Get current user  | N/A                                  | `{user}`        |

---

## 🎨 **UI/UX Requirements**

### **User Interface Specifications**

_Describe the visual and interaction requirements_

**Login Form:**

- Clean, centered design with company branding
- Email and password fields with appropriate validation
- "Remember me" checkbox
- "Forgot password?" link
- Loading state during authentication
- Clear error messages displayed inline

**Navigation:**

- Show user avatar/name when logged in
- "Login" button when logged out
- "Logout" option in user dropdown

### **User Experience Flow**

_Describe the expected user journey_

1. **New User Flow:**

   - User clicks "Sign Up" → Registration form → Email verification → Automatic login → Dashboard

2. **Returning User Flow:**

   - User clicks "Login" → Login form → Dashboard (or redirect to intended page)

3. **Protected Route Access:**
   - Unauthenticated user tries to access protected page → Redirect to login with return URL → After login, redirect back to intended page

---

## 📁 **File Structure & Integration**

### **Existing Codebase Context**

_Provide information about current project structure_

**Current File Structure:**

```
src/
├── components/
├── pages/
├── hooks/
├── utils/
├── styles/
└── App.js
```

**Existing Code to Integrate With:**

- Database connection: `src/utils/database.js`
- API client: `src/utils/api.js`
- Route protection: Should integrate with `src/components/ProtectedRoute.js`

### **New Files Expected**

_Suggest where new code should be organized_

```
src/
├── components/
│   ├── auth/
│   │   ├── LoginForm.js
│   │   ├── RegisterForm.js
│   │   └── AuthLayout.js
├── hooks/
│   └── useAuth.js
├── utils/
│   ├── auth.js
│   └── validation.js
└── context/
    └── AuthContext.js
```

---

## 🧪 **Testing Requirements**

### **Test Coverage Expectations**

_Specify what should be tested and how_

**Unit Tests:**

- [ ] Authentication utility functions
- [ ] Form validation logic
- [ ] JWT token handling
- [ ] API endpoint handlers

**Integration Tests:**

- [ ] Complete login/logout flow
- [ ] Protected route access
- [ ] User registration process

**Example Test Cases:**

- Valid login with correct credentials returns user and token
- Invalid login with wrong password returns appropriate error
- Expired JWT token redirects to login page
- Protected routes are inaccessible without authentication

---

## 🔒 **Security Considerations**

### **Security Requirements**

_Specify security measures that must be implemented_

- [ ] Passwords must be hashed using bcrypt (min 12 rounds)
- [ ] JWT tokens should be stored securely (httpOnly cookies preferred over localStorage)
- [ ] Input validation and sanitization on all form fields
- [ ] Rate limiting on login attempts
- [ ] HTTPS required for all authentication endpoints
- [ ] Secure password reset functionality

### **Common Vulnerabilities to Prevent**

- SQL injection in login queries
- XSS attacks through user input
- CSRF attacks on authentication endpoints
- Brute force attacks on login
- JWT token tampering

---

## 🔗 **Dependencies & Resources**

### **External Libraries/Packages**

_List specific packages to use or avoid_

**Required:**

- `bcryptjs` for password hashing
- `jsonwebtoken` for JWT handling
- `validator` for input validation

**Optional but Preferred:**

- `react-hook-form` for form handling
- `react-query` for API state management

**Avoid:**

- Any packages with known security vulnerabilities
- Deprecated authentication libraries

### **External Resources**

_Provide links to relevant documentation, designs, or references_

- **API Documentation:** [Link to existing API docs]
- **Design Mockups:** [Link to Figma/design files]
- **Security Standards:** [Link to company security guidelines]
- **Code Style Guide:** [Link to coding standards]

---

## 🐛 **Error Handling & Edge Cases**

### **Expected Error Scenarios**

_Define how errors should be handled_

**Authentication Errors:**

- Invalid credentials: Display "Invalid email or password"
- Account not verified: Display "Please verify your email address"
- Account locked: Display "Account temporarily locked due to multiple failed attempts"

**Network Errors:**

- API unavailable: Display "Unable to connect. Please try again."
- Timeout: Display "Request timed out. Please check your connection."

**Form Validation Errors:**

- Invalid email: Display "Please enter a valid email address"
- Weak password: Display "Password must be at least 8 characters with numbers and symbols"

### **Edge Cases to Consider**

- User tries to register with existing email
- JWT token expires during active session
- User navigates back after logout
- Multiple tabs with different authentication states
- Network connectivity issues during authentication

---

## 📋 **Acceptance Criteria Checklist**

### **Definition of Done**

_Check off when each criterion is met_

**Functionality:**

- [ ] All user stories/requirements are implemented
- [ ] All API endpoints work as specified
- [ ] UI matches design requirements
- [ ] Error handling works for all scenarios

**Code Quality:**

- [ ] Code follows established style guidelines
- [ ] All functions are properly documented
- [ ] No console.log statements left in production code
- [ ] Code is optimized for performance

**Testing:**

- [ ] All tests pass
- [ ] Test coverage meets requirements (specify %)
- [ ] Manual testing completed for all user flows

**Security:**

- [ ] Security requirements are implemented
- [ ] No sensitive data exposed in client-side code
- [ ] All inputs are properly validated and sanitized

**Integration:**

- [ ] Works with existing codebase without breaking changes
- [ ] Database migrations (if any) are included
- [ ] Environment variables documented

---

## 📝 **Additional Notes & Context**

### **Implementation Preferences**

_Any specific approaches or patterns you prefer_

**Example:**

- Prefer functional components over class components
- Use TypeScript interfaces for type safety
- Follow atomic design principles for components
- Implement progressive enhancement for better accessibility

### **Future Considerations**

_Features or changes that might be added later_

**Example:**

- Social media login integration (Google, GitHub)
- Two-factor authentication
- Single Sign-On (SSO) integration
- Advanced user roles and permissions

### **Assumptions & Clarifications**

_Document any assumptions made or clarifications needed_

**Example:**

- Assuming email service is already configured for verification emails
- Database schema changes require approval from DBA team
- Mobile responsiveness is required for all auth screens

---

## 💬 **Questions for Implementation**

_Use this section to ask Claude any clarifying questions before starting_

1. Should I implement the complete feature in one response, or break it into smaller parts?
2. Do you want me to include database migration scripts?
3. Should I prioritize any specific browser compatibility requirements?
4. Are there any existing authentication patterns in your codebase I should follow?
5. Do you need both the frontend and backend implementation, or just one?

---

**💡 Pro Tips for Best Results:**

- Be as specific as possible - vague requirements lead to assumptions
- Include examples of existing code patterns you want to follow
- Specify what you DON'T want as much as what you do want
- Mention any deadlines or constraints that might affect implementation approach
- Include links to relevant documentation or resources
- Don't hesitate to ask follow-up questions for clarification
