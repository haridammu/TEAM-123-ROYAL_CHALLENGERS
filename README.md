# 🧠 AI-LMS: The Future of Recruitment & Learning

**AI-LMS** is a cutting-edge ecosystem designed to bridge the gap between academic learning and corporate hiring. By leveraging **GenAI (Llama-3)**, **Real-time Sockets**, and a **Flutter Multi-App Architecture**, we provide a seamless experience for Students, Companies, and Examiners.

---

## 🚀 Key Features Overview

### 🏢 **Company App (Recruitment Suite)**
*Transforming how companies hire talent.*

#### **1. Smart Job Management**
*   **Post Jobs with AI**: Create detailed job listings with rich descriptions, requirements, and salary ranges.
*   **Stepper Form UI**: Modern, intuitive multi-step form for creating vacancies.
*   **Real-time Dashboard**: Live counter for **Active Jobs** and **Total Applicants**.

#### **2. Intelligent Applicant Tracking (ATS)**
*   **AI Match Score**: Automatically analyzes every applicant's resume against the job description and assigns a **0-100% Fit Score**.
*   **Applicant Insights**: Visual indicators for "High Match" (Green), "Potential" (Yellow), and "Mismatch" (Red).
*   **Status Pipeline**: Drag-and-drop style status updates: `Pending` → `Reviewing` → `Interview` → `Hired` → `Rejected`.

#### **3. Integrated Interview System**
*   **One-Click Scheduling**: Schedule interviews directly from the applicant's profile.
*   **Real-time Notifications**: Trigger instant alerts to the Student App via Socket.IO upon scheduling.
*   **Video Integration**: (Ready for Agora/Zoom link embedding).

#### **4. AI Contest Generator (Killer Feature)**
*   **Instant Contests**: Ask the AI: *"Create a Hard Dynamic Programming contest with 3 problems"* -> **Done in 10s**.
*   **Auto-Generated Content**:
    *   Problem Titles & Descriptions
    *   Input/Output Formats & Constraints
    *   Sample Test Cases & Hidden Test Cases
*   **Global Visibility**: Contests are instantly published to the Student App's "Live" section.

#### **5. Dynamic Branding**
*   **Company Profile**: Manage Logo, Website, Bio, and Location.
*   **Instant Updates**: Changes reflect immediately across all Student App pipelines.

---

### 🎓 **Student App (Career & Learning)**
*Empowering students to learn, compete, and get hired.*

#### **1. AI-Powered Resume Builder**
*   **Smart Suggestions**: AI helps rephrase experience and skills for better ATS ranking.
*   **Premium Templates**: Auto-generates clean, professional PDF resumes.
*   **Structure**: Sections for Education, Projects, Experience, Skills, and Awards.

#### **2. Competitive Programming Arena**
*   **Live Battles**: Participate in real-time contests hosted by top companies.
*   **Real-time Leaderboard**: See your rank climb as you solve problems.
*   **AI Assistant**: In-contest chat bot to clear doubts (e.g., *"Explain this error"* or *"Hint for Problem 2"*).
*   **AI Proctoring**: Simulated proctoring system that detects tab-switching and suspicious behavior.
*   **Code Runner**: Integrated **JDoodle** compiler supporting Python, C++, Java, and Dart.

#### **3. Job Portal**
*   **Smart Feed**: Jobs recommended based on skills and resume match.
*   **One-Tap Apply**: Apply instantly using the stored profile.
*   **Application Tracking**: See exactly where you stand in the hiring pipeline.

#### **4. Learning & Gamification**
*   **Course Modules**: AI-curated learning paths.
*   **Achievements**: Badges for "Contest Winner", "Streak Master", etc.

---

### 🛠️ **Backend (The Brain)**
*   **Node.js & Express**: High-performance RESTful API.
*   **Supabase (PostgreSQL)**: Relational database for complex data modeling.
*   **Groq SDK (Llama-3-70b)**: The ultra-fast AI engine behind Contests and Resume Matching.
*   **Socket.IO**: Real-time bi-directional communication for notifications and contest updates.
*   **JDoodle API**: Remote code execution engine.

---

## � Tech Stack Details

| Component | Tech |
| :--- | :--- |
| **Mobile Apps** | **Flutter 3.x** (Dart) |
| **State Mgmt** | Riverpod |
| **Navigation** | GoRouter |
| **UI/UX** | Glassmorphism, Flutter Animate, Google Fonts (Outfit) |
| **Backend** | **Node.js**, Express.js |
| **Database** | **Supabase** (Postgres) |
| **AI Model** | **Llama-3-70b** (via Groq) |
| **Real-time** | **Socket.IO** |

---

## ⚡ Deployment & Setup

### **1. Backend Server**
```bash
cd backend
npm install
# Configure .env:
# SUPABASE_URL=...
# SUPABASE_SERVICE_KEY=...
# GROQ_API_KEY=...
# JDOODLE_CLIENT_ID=...
# JDOODLE_CLIENT_SECRET=...
npm start
```

### **2. Company App**
```bash
cd company_app
flutter pub get
flutter run
```

### **3. Student App**
```bash
cd . # Root directory
flutter pub get
flutter run
```

---

## 🌟 How to Demo "The Full Flow"

1.  **Recruiter**: Login to Company App -> **Dashboard** -> **AI Contests**.
2.  **Action**: Create a "Python Lists" contest (Medium difficulty).
3.  **Result**: Watch the AI generate problems. It appears in the list.
4.  **Student**: Login to Student App -> **Contests**.
5.  **Action**: See the "Live" contest. Open it.
6.  **Recruiter**: Go to **My Jobs**. View an Applicant.
7.  **Action**: Click "Schedule Interview".
8.  **Student**: Receive a **Notification**: *"Interview Scheduled!"*

---

*AI-LMS: Closing the loop between Education and Employment.*
