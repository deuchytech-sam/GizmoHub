# 🛍️ GizmoHub

<div align="center">

### A modern gadget shopping experience built with Flutter & Firebase

A production-style e-commerce application focused on **clean UI, scalable architecture, real-time data, and a smooth shopping experience.**

<br>



\

<br>

**🚧 Currently in development**

</div>

---

## 📱 Preview

> GizmoHub is a modern e-commerce experience for discovering and purchasing gadgets and electronics.

<div align="center">

<!-- Replace these placeholders with your screenshots -->

|     Onboarding    |        Home       |      Products     |
| :---------------: | :---------------: | :---------------: |
| 📱 Add Screenshot | 🏠 Add Screenshot | 🛒 Add Screenshot |

|  Product Details  |      Wishlist     |      Profile      |
| :---------------: | :---------------: | :---------------: |
| 📦 Add Screenshot | ❤️ Add Screenshot | 👤 Add Screenshot |

</div>

---

## ✨ What is GizmoHub?

**GizmoHub** is a Flutter-based e-commerce application designed around the experience of shopping for modern gadgets and electronics.

The project goes beyond simply recreating a UI. It is being built as a **full-stack mobile application**, combining a polished Flutter interface with Firebase-powered authentication, cloud data, storage, and persistent application state.

The goal is to demonstrate how a real-world e-commerce application can be structured using modern Flutter development practices.

### 🎯 Project Focus

* 🎨 Modern and responsive UI
* 🧩 Reusable Flutter components
* 🏗️ Scalable application architecture
* 🔥 Firebase backend integration
* 🔐 Secure authentication
* ⚡ Reactive state management
* ☁️ Cloud-hosted product data
* ❤️ Persistent wishlist functionality
* 🛒 E-commerce workflows
* 💳 Payment integration roadmap

---

# 🚀 Features

## 🔐 Authentication

GizmoHub uses Firebase Authentication to handle user accounts and sessions.

* Sign up
* Sign in
* Sign out
* Email verification
* Password reset
* Password visibility toggle
* Authentication state handling
* Social authentication UI

---

## 🏠 Home Experience

The home screen is designed around product discovery.

### Promotional Carousel

Promotional content is dynamically loaded from Firebase rather than being hardcoded into the application.

Features include:

* Dynamic promotional banners
* Firebase-powered content
* Promotional images from Firebase Storage
* Automatic carousel navigation
* Page indicators
* Active/inactive promotion handling

### ⚡ Deal of the Day

A dedicated Deal of the Day section provides:

* Dynamic deal information
* Product image
* Discounted pricing
* Countdown timer
* Firebase-powered data

---

## 🛒 Dynamic Products

Products are fetched directly from Cloud Firestore.

Each product can contain:

* Product name
* Description
* Current price
* Previous price
* Discount
* Rating
* Reviews
* Product image

Product images are hosted using **Firebase Storage**, allowing the product catalog to be updated without rebuilding the application.

---

## ❤️ Wishlist

Users can save products they are interested in.

* Add products
* Remove products
* Wishlist screen
* Persistent local wishlist data
* Product state synchronization

---

## 🎨 Theme System

GizmoHub supports:

* ☀️ Light mode
* 🌙 Dark mode
* 🖥️ System theme

Theme preferences are persisted using `hydrated_bloc`.

---

## 🚀 Onboarding

The onboarding experience uses Lottie animations to introduce users to the application.

* Animated onboarding screens
* Skip functionality
* Next / Previous navigation
* Page indicators
* Persistent onboarding completion
* Automatic navigation to authentication

---

# 🧠 Architecture

GizmoHub follows a modular architecture designed to keep UI, business logic, data, and configuration separate.

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
│   │   ├── bloc/
│   │   └── pages/
│   │
│   ├── category/
│   ├── home/
│   │   └── bloc/
│   │
│   ├── onboarding/
│   ├── product/
│   ├── wishlist/
│   └── profile/
│
├── firebase_options.dart
└── main.dart
```

---

# ⚡ State Management

GizmoHub uses **BLoC/Cubit** to separate UI from application logic.

Current Cubits include:

```text
AuthCubit
ThemeCubit
OnboardingCubit
PromoCubit
ProductCubit
DealCubit
```

This allows individual features to manage their own state while keeping widgets focused primarily on presentation.

### Example flow

```text
UI
 ↓
Cubit
 ↓
Repository
 ↓
Firebase
 ↓
Repository
 ↓
Cubit
 ↓
UI
```

This approach makes the application easier to maintain as more features are added.

---

# 🔥 Firebase Architecture

Firebase acts as the backend infrastructure for GizmoHub.

```text
                    GizmoHub
                       │
          ┌────────────┴────────────┐
          │                         │
       Flutter                    Firebase
          │                         │
     ┌────┴────┐          ┌─────────┼─────────┐
     │         │          │         │         │
   Cubit      UI       Auth     Firestore  Storage
     │                    │         │         │
     └────────────────────┴─────────┴─────────┘
```

### Firebase Authentication

Handles:

```text
Users
 ├── Registration
 ├── Login
 ├── Email verification
 ├── Password reset
 └── Session management
```

### Cloud Firestore

Stores application data such as:

```text
products/
promos/
deals/
users/
```

### Firebase Storage

Stores remotely hosted media:

```text
products/
promos/
deals/
profile/
```

---

# 🧰 Tech Stack

| Technology                  | Usage                                  |
| --------------------------- | -------------------------------------- |
| **Flutter**                 | Cross-platform application development |
| **Dart**                    | Application programming language       |
| **Firebase Authentication** | User authentication                    |
| **Cloud Firestore**         | Cloud database                         |
| **Firebase Storage**        | Image and media storage                |
| **flutter_bloc**            | State management                       |
| **hydrated_bloc**           | Persistent state                       |
| **get_it**                  | Dependency injection                   |
| **Lottie**                  | Animated onboarding                    |
| **flutter_svg**             | SVG assets                             |
| **Satoshi**                 | Application typography                 |

---

# 📂 Key Project Concepts

### Repository Pattern

Firebase communication is abstracted through repositories rather than placing database calls directly inside widgets.

```text
Presentation
      ↓
    Cubit
      ↓
 Repository
      ↓
   Firebase
```

This makes the code easier to test, maintain, and extend.

### Dependency Injection

`get_it` is used to register and access application dependencies.

```text
Service Locator
      │
      ├── Repositories
      ├── Cubits
      ├── Services
      └── Database
```

### Persistent State

`hydrated_bloc` is used for state that needs to survive application restarts.

Currently used for areas such as:

* Theme preference
* Onboarding completion

---

# 🛣️ Roadmap

## ✅ Completed

* [x] Flutter project setup
* [x] Custom application theme
* [x] Light / Dark / System theme
* [x] Splash screen
* [x] Animated onboarding
* [x] Persistent onboarding state
* [x] Firebase initialization
* [x] Firebase Authentication
* [x] Sign in
* [x] Sign up
* [x] Password reset
* [x] Dynamic promotional carousel
* [x] Firebase product fetching
* [x] Firebase Storage images
* [x] Product cards
* [x] Deal of the Day
* [x] Countdown timer
* [x] Wishlist
* [x] BLoC/Cubit state management
* [x] Dependency injection

## 🔨 In Progress

* [x] Product details
* [x] Advanced product search
* [x] Product filtering
* [x] Product sorting
* [x] Complete profile management
* [x] Cloud wishlist synchronization

## 🔮 Planned

* [x] Shopping cart
* [x] Cart persistence
* [x] Checkout
* [x] Delivery information
* [x] Order management
* [x] Order history
* [ ] Paystack integration
* [ ] Payment verification
* [ ] Google authentication
* [ ] Apple authentication
* [x] Product reviews
* [x] Related products
* [x] Push notifications
* [x] Admin product management

---

# 💳 Planned Checkout Flow

The planned shopping experience will follow:

```text
Browse Products
      ↓
Product Details
      ↓
Add To Cart
      ↓
Shopping Cart
      ↓
Checkout
      ↓
Delivery Information
      ↓
Order Summary
      ↓
Paystack Payment
      ↓
Payment Verification
      ↓
Order Confirmation
      ↓
Order History
```

---

# 🛡️ Security

Firebase security rules will control access to application resources.

The planned permission model is:

```text
Public
 ├── Read products
 ├── Read promotions
 └── Read deals

Authenticated Users
 ├── Manage wishlist
 ├── Manage profile
 └── Manage orders

Authorized Admins
 ├── Create products
 ├── Update products
 ├── Delete products
 ├── Manage promotions
 └── Manage deals
```

> Production security rules will be configured according to the final authentication and authorization architecture.

---

# ⚙️ Getting Started

## Requirements

Make sure you have:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Git
* Firebase project
* FlutterFire CLI

Check your Flutter environment:

```bash
flutter doctor
```

---

## 📥 Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/GizmoHub.git
```

Navigate to the project:

```bash
cd GizmoHub
```

Install dependencies:

```bash
flutter pub get
```

---

## 🔥 Configure Firebase

Create a Firebase project and enable:

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

Then configure FlutterFire:

```bash
flutterfire configure
```

Run the application:

```bash
flutter run
```

---

# 🧪 Development

Analyze the project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Format the project:

```bash
dart format .
```

---

# 📸 Screenshots

Once the UI is finalized, screenshots can be added here to showcase the application.

Recommended structure:

```text
screenshots/
│
├── onboarding/
│   ├── onboarding_1.png
│   ├── onboarding_2.png
│   └── onboarding_3.png
│
├── authentication/
│   ├── sign_in.png
│   └── sign_up.png
│
├── home/
│   ├── home.png
│   ├── promotions.png
│   └── deals.png
│
├── products/
│   ├── products.png
│   └── product_details.png
│
└── wishlist/
    └── wishlist.png
```

---

# 🎯 What I Learned

Building GizmoHub has provided practical experience with:

* Flutter application architecture
* Dart programming
* BLoC/Cubit state management
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Dependency injection
* Persistent application state
* Repository patterns
* Reusable widgets
* Dynamic UI
* E-commerce application architecture
* Authentication flows
* Cloud-backed data
* Responsive mobile interfaces

---

# 🌟 Why GizmoHub?

GizmoHub was created to go beyond building static Flutter interfaces.

The project focuses on understanding how the different pieces of a real application work together:

```text
                    ┌──────────────┐
                    │     UI       │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │     BLoC      │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  Repository   │
                    └──────┬───────┘
                           │
                ┌──────────▼──────────┐
                │       Firebase      │
                └──────────┬──────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
          Auth        Firestore      Storage
```

The end goal is to turn GizmoHub into a complete mobile commerce experience with authentication, product discovery, wishlist management, cart functionality, checkout, payments, and order management.

---

# 👨‍💻 About The Developer

**Samuel**

Flutter Developer focused on building modern, scalable mobile applications with clean UI and practical backend integrations.

### Currently working with

```text
Flutter
Dart
Firebase
BLoC / Cubit
Cloud Firestore
Firebase Storage
Git & GitHub
```

---

# ⭐ Support

If you like the project, consider giving the repository a ⭐ on GitHub.

It helps support the project and motivates continued development.

---

<div align="center">

### Built with ❤️ using Flutter & Firebase

**GizmoHub — Your gadgets. Your way.**

</div>
