# "iDoom Bookstore: Digital Reading Simplified"
## A Flutter & Django Application

---

## Slide 1: Introduction
**Title: "Digital Books at Your Fingertips"**

- Overview of iDoom Bookstore mobile application
- Problem: Limited access to digital books with personalized experience in Algeria
- Solution: An integrated platform for discovering and reading digital books
- Tech stack: Flutter (frontend) + Django REST Framework (backend)
- Project context: Developed for Algérie Télécom to modernize digital services

---

## Slide 2: Project Background
**Title: "Meeting a Growing Demand"**

- Digital book market growth in Algeria
- Algérie Télécom's need for a modern reading platform
- Target audience: General public and Algérie Télécom employees/clients
- Key objectives: Modernization of digital services, improved access to cultural content
- Main challenge: Creating a secure, fluid reading experience

---

## Slide 3: Architecture Overview
**Title: "How It All Works Together"**

- Client-server architecture with REST API communication
- Django backend with SQLite database
- Flutter frontend for cross-platform mobile experience
- File storage system for books (PDF, EPUB) and cover images
- Authentication flow with token-based security
- Multi-platform compatibility (Android, iOS, web browsers)

---

## Slide 4: User Authentication
**Title: "Secure & Simple Access"**

- Token-based authentication system
- Email verification with short tokens
- Password reset functionality
- Secure storage using FlutterSecureStorage
- Demo of sign-up and verification flow

---

## Slide 5: Genre Selection System
**Title: "Personalized Reading Experience"**

- Genre model with predefined categories
- User onboarding with genre selection
- ManyToMany relationship between users and genres
- Backend API for retrieving and updating preferences
- Demo of the genre selection screen

---

## Slide 6: Book Discovery
**Title: "Finding Books You'll Love"**

- Book browsing by genre
- Personalized "For You" recommendations based on user genres
- New releases section
- Book detail view with metadata
- Implementation of the get_all_books API endpoint

---

## Slide 7: Book Management
**Title: "Your Digital Library"**

- User's favorite books collection
- Reading progress tracking
- Book file access (PDF/EPUB)
- Book rating system
- Implementation of UserBookInteraction model

---

## Slide 8: File Storage & Access
**Title: "Organized Content Delivery"**

- File organization structure for books
- Custom upload paths for different file types
- File validation for PDFs, EPUBs, and images
- Secure file access through authenticated endpoints
- Implementation of book_file_path function

---

## Slide 9: User Profile Management
**Title: "Customizable User Experience"**

- Profile information management
- Password update functionality
- Profile image handling
- Genre preference updates
- Implementation of updateProfile endpoint

---

## Slide 10: Book Rating System
**Title: "Community-Driven Quality"**

- Rating submission implementation
- Average rating calculation
- Rating display in UI
- Backend validation of rating values
- Implementation of submit_rating endpoint

---

## Slide 11: Favorite Books Feature
**Title: "Keep Your Favorites Close"**

- Toggle favorite functionality
- Favorite books display
- Backend implementation with UserBookInteraction
- UI integration with heart icons
- Implementation of toggle_favorite endpoint

---

## Slide 12: Reading Progress Tracking
**Title: "Never Lose Your Place"**

- Progress percentage tracking
- Backend storage of reading position
- UI integration with progress indicators
- Implementation of update_progress endpoint
- Multi-device synchronization

---

## Slide 13: Offline Reading Capability
**Title: "Read Anywhere, Anytime"**

- DownloadService implementation for local storage
- PDF viewing with PDFView widget
- Hive boxes for storing book data
- Progress syncing between online and offline modes
- Demo of the offline reading experience

---

## Slide 14: Payment Integration
**Title: "Seamless Book Purchasing"**

- Cart system implementation with CartProvider
- Checkout process with Chargily integration
- Payment WebView implementation
- Order tracking and history
- Demo of the purchase flow

---

## Slide 15: Social Features
**Title: "Connect Through Reading"**

- Comment system implementation
- CommentWidget and CommentsSheet components
- User profile images in comments
- Reply functionality
- Demo of the commenting system

---

## Slide 16: Data Population Strategy
**Title: "Building a Rich Book Catalog"**

- Dummy data generation script
- Random book creation with varied metadata
- Genre assignment to books
- User interaction simulation
- Implementation of dummy_data_script.py

---

## Slide 17: Technical Challenges & Solutions
**Title: "Overcoming Development Hurdles"**

- Challenge: Managing file storage for different book formats
  - Solution: Custom file paths and validators
- Challenge: User preference tracking
  - Solution: ManyToMany relationships with Genre model
- Challenge: Book rating system
  - Solution: Aggregate calculations for average ratings

---

## Slide 18: Performance Optimization
**Title: "Speed and Efficiency"**

- Widget rebuild optimization
- Pagination implementation for API calls
- Data caching strategies
- RepaintBoundary usage for complex UI
- Implementation details from optimizing_tips.txt

---

## Slide 19: Project Constraints
**Title: "Development Considerations"**

- Security requirements for user data protection
- Multi-platform compatibility challenges
- Maintenance and scalability considerations
- Performance optimization for mobile devices
- Implementation of secure payment processing

---

## Slide 20: Conclusion
**Title: "A Complete Digital Reading Solution"**

- Summary of key features implemented
- Alignment with Algérie Télécom's objectives
- Benefits for the Algerian digital book market
- Technical achievements
- Lessons learned during development
- Q&A invitation

---

## Presentation Tips:

1. **For each feature demo:**
   - Show actual code from the codebase
   - Demonstrate the feature on a real device
   - Explain both frontend and backend components

2. **Visual aids:**
   - Include screenshots of key screens
   - Show model relationship diagrams
   - Highlight important code snippets from the actual codebase

3. **Technical focus points:**
   - Django model relationships (Book-Genre, User-Genre)
   - File handling implementation
   - Authentication flow
   - Flutter state management approach

4. **Business value emphasis:**
   - How the application modernizes Algérie Télécom's digital services
   - User experience improvements for Algerian readers
   - Cultural and educational access benefits
   - Potential for future expansion