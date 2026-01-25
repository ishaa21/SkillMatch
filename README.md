# 📌 SkillMatch – Internship Matching Platform

## About the Project

SkillMatch is an internship matching platform designed to connect students with relevant internships based on their skills, interests, and preferences. The project focuses on solving a real problem faced by students — finding internships that actually match their profiles — while giving companies a structured way to manage applications.

This project is built as a full-stack application and is suitable for academic submission as well as future expansion into a startup-ready product.

## 🛠 Tech Stack Used

- **Frontend**: Flutter (Android / Web support)
- **Backend**: Node.js with Express
- **Database**: MongoDB
- **Authentication**: JWT-based authentication
- **AI Logic**: Rule-based weighted scoring algorithm

## 🔐 User Roles

The application supports three types of users:

### Student
- Create and manage profile
- View AI-recommended internships
- Apply for internships and track application status

### Company
- Register and wait for admin approval
- Post and manage internship listings
- View applicants and update application status

### Admin
- Approve or reject company registrations
- Monitor users, internships, and applications
- Control basic system configurations

## 🤖 Internship Matching Logic

The internship matching logic is implemented on the backend using a weighted scoring approach. Each internship is scored based on how well it matches a student’s profile.

**Main factors considered:**
- Skills match
- Domain interest
- Location preference
- Experience / proficiency
- Availability and work mode

The final score is used to rank internships for each student.

## 📁 Project Structure

```
internship_app/
│
├── backend/
│   ├── models/        # Mongoose schemas
│   ├── controllers/   # API logic
│   ├── routes/        # Express routes
│   ├── utils/         # AI matching logic
│   └── server.js
│
├── frontend/
│   └── lib/
│       ├── core/      # Theme, constants, helpers
│       ├── features/  # Auth, dashboards, profiles
│       └── main.dart
```

## 🚀 How to Run the Project

### Backend Setup
```bash
cd backend
npm install
npm run dev
```
Make sure you have a valid MongoDB connection string set in the `.env` file.

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

## 🎨 UI Theme

The app uses a clean and minimal green-based theme to keep the interface calm and professional.

- **Primary Color**: Deep Green
- **Background**: Light Mint
- **Accent**: Soft Sage Green

## 📌 Notes

- This project is actively evolving and structured to allow easy future improvements.
- Real-time updates are supported using Socket.IO.
- The codebase follows modular and readable practices to simplify maintenance.

## 📄 License

This project is developed for learning and academic purposes.
