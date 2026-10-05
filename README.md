# 🛍️ GizmoHub

A modern **Flutter e-commerce application for gadgets and electronics**, built with Flutter and Firebase.

GizmoHub is designed to provide a clean, responsive, and intuitive shopping experience where users can browse products, view deals, manage their wishlist, and authenticate securely.

> 🚧 **Status:** In Development

---

## 📱 About The Project

GizmoHub is a personal Flutter project focused on building a production-style e-commerce application while applying modern Flutter development practices.

The project uses **Firebase for authentication and cloud data**, **BLoC/Cubit for state management**, and a modular architecture to keep the codebase scalable and maintainable.

The application is inspired by modern e-commerce UI designs and is being developed with a focus on clean UI, reusable components, and real-time data.

---

## ✨ Features

### 🔐 Authentication

* User registration
* User login
* Firebase Authentication
* Email verification
* Password reset
* Password visibility toggle
* Social authentication UI

### 🏠 Home

* Dynamic promotional banners
* Promotional carousel
* Deal of the Day
* Functional countdown timer
* Product categories
* Dynamic product listings
* Product ratings and reviews
* Search functionality

### 🛒 Products

* Products loaded from Firebase
* Product images from Firebase Storage
* Product pricing
* Discounted pricing
* Product ratings
* Product reviews
* Product details

### ❤️ Wishlist

* Add products to wishlist
* Remove products from wishlist
* Persistent wishlist data
* Dedicated wishlist screen

### 👤 Profile

* User profile
* Account information
* Authentication actions

### 🎨 Theme

* Light theme
* Dark theme
* System theme support
* Persistent theme selection

### 🚀 Onboarding

* Animated onboarding screens
* Lottie animations
* Skip functionality
* Persistent onboarding state
* Automatic navigation after onboarding

---

## 🛠️ Tech Stack

| Technology                  | Purpose                        |
| --------------------------- | ------------------------------ |
| **Flutter**                 | Cross-platform UI framework    |
| **Dart**                    | Programming language           |
| **Firebase Authentication** | User authentication            |
| **Cloud Firestore**         | Product and application data   |
| **Firebase Storage**        | Product and promotional images |
| **flutter_bloc**            | State management               |
| **hydrated_bloc**           | Persistent state               |
| **get_it**                  | Dependency injection           |
| **Lottie**                  | Onboarding animations          |
| **flutter_svg**             | SVG assets                     |
| **Satoshi Font**            | Application typography         |

---

## 🏗️ Architecture

GizmoHub follows a modular architecture that separates presentation, data, and core application logic.

```text
lib/
│
├── common/
│   └── widgets/
│
├── core/
│   ├── configs/
│   │   ├── assets/
│   │   ├── theme/
│   │   └── ...
│   │
│   ├── database/
│   └── di/
│
├── data/
│   ├── models/
│   └── repositories/
│
├── presentation/
│   ├── auth/
│   ├── category/
│   ├── home/
│   ├── onboarding/
│   ├── product/
│   ├── wishlist/
│   └── profile/
│
├── firebase_options.dart
└── main.dart
```

### State Management

GizmoHub uses **BLoC/Cubit** to manage application state.

Examples include:

```text
AuthCubit
ThemeCubit
OnboardingCubit
PromoCubit
ProductCubit
DealCubit
```

This keeps business logic separate from the UI and makes individual features easier to maintain and test.

---

## 🔥 Firebase

GizmoHub uses Firebase as its backend.

### Firebase Authentication

Used for:

* Account creation
* Login
* Email verification
* Password reset
* User sessions

### Cloud Firestore

Firestore stores application data such as:

```text
products
promos
deals
users
```

### Firebase Storage

Storage is used for remotely hosted assets such as:

```text
products/
promos/
deals/
```

This allows product and promotional images to be managed without bundling them directly into the application.

---

## 🎨 Screens

The application currently includes or is being developed around the following screens:

* Splash Screen
* Onboarding
* Sign In
* Sign Up
* Forgot Password
* Home
* Categories
* Product Details
* Wishlist
* Profile

### 📸 Screenshots

Screenshots will be added as the application reaches stable UI milestones.

```text
screenshots/
├── onboarding.png
├── login.png
├── home.png
├── products.png
├── product_details.png
└── wishlist.png
```

---

## 🚀 Getting Started

### Prerequisites

Before running GizmoHub, make sure you have installed:

* Flutter
* Dart
* Android Studio or VS Code
* Git
* A Firebase project

Check your Flutter installation with:

```bash
flutter doctor
```

---

## 📥 Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/GizmoHub.git
```

Navigate into the project:

```bash
cd GizmoHub
```

Install dependencies:

```bash
flutter pub get
```

---

## 🔥 Firebase Configuration

Create a Firebase project and connect it to your Flutter application.

Enable:

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

Then configure Firebase for your target platforms.

For FlutterFire CLI:

```bash
flutterfire configure
```

This generates the required:

```text
firebase_options.dart
```

> **Note:** Firebase configuration files contain project-specific information. Make sure your authentication and Firestore/Storage security rules are properly configured before deploying the application.

---

## ▶️ Running The App

Run the application with:

```bash
flutter run
```

For a specific device:

```bash
flutter devices
```

Then:

```bash
flutter run -d <device_id>
```

---

## 📦 Dependencies

The main packages used by GizmoHub include:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  flutter_svg:
  flutter_bloc:
  hydrated_bloc:
  path_provider:
  lottie:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  firebase_storage:
  get_it:
```

Run:

```bash
flutter pub get
```

after adding or updating dependencies.

---

## 🗺️ Roadmap

### Authentication

* [x] Sign In
* [x] Sign Up
* [x] Forgot Password
* [ ] Email verification flow refinement
* [ ] Google authentication
* [ ] Apple authentication
* [ ] Facebook authentication

### Home

* [x] Home UI
* [x] Promotional carousel
* [x] Dynamic promotions
* [x] Deal of the Day
* [x] Countdown timer
* [x] Dynamic products
* [x] Advanced search
* [x] Product filtering
* [x] Product sorting

### Products

* [x] Firebase product fetching
* [x] Product cards
* [x] Product images
* [x] Product pricing
* [x] Discount display
* [x] Product details
* [x] Product reviews
* [ ] Related products

### Wishlist

* [x] Wishlist UI
* [x] Add/remove products
* [x] Cloud synchronization

### Cart & Checkout

* [x] Shopping cart
* [x] Quantity management
* [x] Order summary
* [x] Checkout
* [x] Delivery information
* [ ] Payment integration
* [x] Order history

### Payments

* [ ] Paystack integration
* [x] Payment confirmation
* [x] Transaction history

### Profile

* [x] Profile UI
* [x] Edit profile
* [ ] Profile image upload
* [x] Order history
* [x] Account settings

---

## 💳 Payments

Payment functionality is planned using **Paystack**.

The planned checkout flow is:

```text
Product
   ↓
Cart
   ↓
Checkout
   ↓
Order Summary
   ↓
Paystack
   ↓
Payment Verification
   ↓
Order Confirmation
```

---

## 🔒 Security

Firebase security rules will be used to control access to application data.

Examples include:

```text
Public
 ├── Product reads
 ├── Promotion reads
 └── Deal reads

Authenticated Users
 ├── Wishlist
 ├── User profile
 └── Orders

Authorized/Admin Users
 ├── Create products
 ├── Update products
 ├── Delete products
 ├── Create promotions
 └── Manage deals
```

Production security rules should always be configured according to the application's final authentication and authorization requirements.

---

## 🧪 Testing

Run Flutter's test suite with:

```bash
flutter test
```

Analyze the project with:

```bash
flutter analyze
```

---

## 📁 Project Goals

GizmoHub is being developed to demonstrate practical experience with:

* Flutter development
* Dart
* Firebase
* REST/backend concepts
* State management
* BLoC/Cubit architecture
* Dependency injection
* Cloud Firestore
* Firebase Storage
* Authentication
* Responsive UI
* Reusable widgets
* E-commerce workflows

---

## 🤝 Contributing

Contributions, suggestions, and improvements are welcome.

To contribute:

1. Fork the repository.
2. Create a feature branch.

```bash
git checkout -b feature/new-feature
```

3. Commit your changes.

```bash
git commit -m "Add new feature"
```

4. Push your branch.

```bash
git push origin feature/new-feature
```

5. Open a Pull Request.

---

## 📄 License

This project is currently intended for **learning and portfolio purposes**.

---

## 👨‍💻 Author

**Samuel Ucheobi Uchechukwu**

Built with ❤️ using Flutter and Firebase.

---

⭐ If you find this project useful or interesting, consider giving the repository a star!
