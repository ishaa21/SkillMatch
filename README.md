# AI Internship Matching Platform

## Project Overview
This represents a scalable, professional-grade architecture for an AI-powered internship matching application.

### Tech Stack
- **Frontend**: Flutter (Mobile & Web)
- **Backend**: Node.js + Express
- **Database**: MongoDB
- **AI Engine**: Custom Weighted Scoring Algorithm (Node.js)

### Architecture
1.  **Role-Based Access Control (RBAC)**: secure JWT authentication for `Student`, `Company`, `Admin`.
2.  **AI Matching**: 
    - Located in `backend/src/utils/aiMatcher.js`.
    - Evaluates 5 key metrics: Skills (40%), Domain Interest (20%), Location (15%), Profilciency (15%), Logistics (10%).
3.  **Scalable Schema**: MongoDB collections designed for high-volume data (indexing recommended on `skills` and `location`).

### Setup Instructions

#### 1. Backend Setup
```bash
cd backend
npm install
# Ensure MongoDB is running locally or update .env
npm run dev
```

#### 2. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

### Color Palette
Generated from your provided image:
- **Primary**: `#235347` (Deep Green)
- **Background**: `#DAF1DE` (Mint Light)
- **Accent**: `#8EB69B` (Sage)

### Directory Structure
```
/internship_app
  /backend
    /src
      /models      # Mongoose Schemas
      /controllers # Business Logic
      /utils       # AI Matcher
  /frontend
    /lib
      /core/theme  # Applied Professional Theme
      /features    # Clean Architecture Layers
```
