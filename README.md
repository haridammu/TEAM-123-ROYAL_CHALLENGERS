# Learning Management System (LMS)

A comprehensive Learning Management System built with Django (Backend) and Flutter (Frontend) that includes all the features of a modern enterprise-level LMS.
=======
# AI POWERED Learning Management System (LMS)

A comprehensive Learning Management System built with Django (Backend) , SupaBase Database and Flutter (Frontend  that includes all the features of a modern enterprise-level LMS.
>>>>>>> 59185188576a4d1f6ef7a183291e2bbc2e860993

## Features

### Authentication & User Management
- User registration and login
- Google Sign-In integration
- Role-based access control (Admin, Instructor, Student, Teaching Assistant)
- Profile management with streak tracking
- Security settings with 2FA support

### Core LMS Features
- Course creation and management
- Module and lesson organization
- Video embedding support
- Enrollment system
- Progress tracking
- Certificates generation

### Advanced Features
- Quiz and assessment system with multiple question types
- Assignment tracking with progress indicators
- Live streaming for examinations
- Project submission with video recording
- YouTube video integration

### Communication & Social Features
- Real-time chat (individual and group)
- Discussion forums
- Social feed with posts and comments
- Following system
- Achievement and badge system
- Leaderboard rankings

### Gamification
- Point-based reward system
- Streak tracking
- Achievement badges
- Leaderboards
- Progress visualization

### Payment & Subscription
- Subscription plans (Basic, Premium)
- Course purchases
- Payment processing integration
- Revenue tracking

### Analytics & Reporting
- User engagement analytics
- Course performance reports
- Financial reporting
- Data export capabilities

### Security & Privacy
- Two-factor authentication
- Privacy controls
- Data encryption
- Account deletion
- Device management

## Technology Stack

### Backend (Django)
- Django 4.2
- Django REST Framework
- SQLite (default database)
- Django CORS Headers
- PyOTP (for 2FA)
- QR Code generation

### Frontend (Flutter)
- Flutter 3.7+
- Dart 3.7+
- HTTP Client for API communication
- WebSocket for real-time features
- Charts for data visualization

## Installation

### Backend Setup

1. Clone the repository:
   ```
   git clone <repository-url>
   cd Lms
   ```

2. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Run migrations:
   ```
   python manage.py migrate
   ```

5. Create a superuser:
   ```
   python manage.py createsuperuser
   ```

6. Start the development server:
   ```
   python manage.py runserver
   ```

### Frontend Setup

1. Navigate to the Flutter app directory:
   ```
   cd lms_app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. **Supabase Configuration** (IMPORTANT):
   - Follow the instructions in `SUPABASE_SETUP_INSTRUCTIONS.md`
   - Update your Supabase URL and anon key in `lib/services/supabase_auth_service.dart`
   - Run the database setup script in your Supabase project

4. Run the app:
   ```
   flutter run
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration (Django backend)
- `POST /api/auth/login/` - User login (Django backend)
- `POST /api/auth/google-login/` - Google Sign-In (Django backend)
- `POST /api/auth/logout/` - User logout (Django backend)
- `GET /api/auth/profile/` - Get user profile (Django backend)
- `PUT /api/auth/profile/update/` - Update user profile (Django backend)

**Note**: The application now also supports Supabase authentication. See `lib/services/supabase_auth_service.dart` for the Supabase implementation.

### Courses
- `GET /api/courses/` - List all courses
- `GET /api/courses/{id}/` - Get course details
- `POST /api/courses/` - Create a course (Admin only)
- `PUT /api/courses/{id}/` - Update a course (Admin only)
- `DELETE /api/courses/{id}/` - Delete a course (Admin only)

### Modules and Lessons
- `GET /api/courses/modules/` - List modules
- `GET /api/courses/lessons/` - List lessons
- `POST /api/courses/modules/` - Create a module (Instructor only)
- `POST /api/courses/lessons/` - Create a lesson (Instructor only)

### Enrollments
- `GET /api/courses/enrollments/` - List user enrollments
- `POST /api/courses/enroll/` - Enroll in a course
- `DELETE /api/courses/unenroll/{id}/` - Unenroll from a course

### Quizzes
- `GET /api/quizzes/` - List quizzes
- `GET /api/quizzes/{id}/` - Get quiz details
- `POST /api/quizzes/` - Create a quiz (Instructor only)
- `GET /api/quizzes/questions/` - List questions
- `GET /api/quizzes/choices/` - List choices
- `POST /api/quizzes/attempts/` - Start quiz attempt
- `POST /api/quizzes/answers/` - Submit answer
- `PATCH /api/quizzes/attempts/{id}/` - Complete quiz attempt

### Chat
- `GET /api/chat/rooms/` - List chat rooms
- `GET /api/chat/messages/` - List messages
- `POST /api/chat/messages/` - Send a message
- `GET /api/chat/private-chats/` - List private chats
- `GET /api/chat/private-messages/` - List private messages
- `POST /api/chat/private-messages/` - Send a private message

### Social
- `GET /api/social/posts/` - List posts
- `POST /api/social/posts/` - Create a post
- `POST /api/social/posts/{id}/like/` - Like a post
- `POST /api/social/posts/{id}/unlike/` - Unlike a post
- `GET /api/social/comments/` - List comments
- `POST /api/social/comments/` - Create a comment
- `GET /api/social/achievements/` - List achievements
- `GET /api/social/leaderboard/` - Get leaderboard

### Payments
- `GET /api/payments/plans/` - List subscription plans
- `GET /api/payments/subscriptions/` - List user subscriptions
- `POST /api/payments/subscriptions/` - Subscribe to a plan
- `GET /api/payments/history/` - Get payment history
- `POST /api/payments/process/` - Process a payment

### Analytics
- `GET /api/analytics/user-activity/` - Get user activity
- `GET /api/analytics/course-progress/` - Get course progress
- `GET /api/analytics/quiz-analytics/` - Get quiz analytics
- `GET /api/analytics/engagement-metrics/` - Get engagement metrics
- `GET /api/analytics/system-performance/` - Get system performance

## Project Structure

### Backend (Django)
```
Lms/
├── Lms/                 # Project settings
├── authentication/      # User authentication and profiles
├── courses/            # Course, module, lesson management
├── quizzes/            # Quiz and assessment system
├── chat/               # Chat and messaging system
├── social/             # Social features and community
├── payments/           # Payment and subscription system
├── analytics/          # Analytics and reporting
├── manage.py           # Django management script
└── requirements.txt    # Python dependencies
```

### Frontend (Flutter)
```
lms_app/
├── lib/
│   ├── models/         # Data models
│   ├── screens/        # UI screens
│   ├── services/       # API services
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Entry point
├── pubspec.yaml        # Flutter dependencies
└── README.md           # Flutter app documentation
```

## Testing

### Backend Testing
Run Django tests:
```
python manage.py test
```

### Frontend Testing
Run Flutter tests:
```
flutter test
```

## Deployment

### Backend Deployment
1. Set environment variables:
   ```
   SECRET_KEY=your-secret-key
   DEBUG=False
   ALLOWED_HOSTS=your-domain.com
   ```

2. Collect static files:
   ```
   python manage.py collectstatic
   ```

3. Use a WSGI server like Gunicorn:
   ```
   gunicorn Lms.wsgi:application
   ```

### Frontend Deployment
Build the Flutter app for your target platform:
```
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

<<<<<<< HEAD
## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request
=======

>>>>>>> 59185188576a4d1f6ef7a183291e2bbc2e860993

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to all contributors who have helped build this LMS
<<<<<<< HEAD
- Inspired by popular LMS platforms like Coursera, Udemy, and edX
=======
- Inspired by popular LMS platforms like Coursera, Udemy, and edX
>>>>>>> 59185188576a4d1f6ef7a183291e2bbc2e860993
