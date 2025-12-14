# Task Manager

A complete task management application built with Flutter, featuring native device integration including camera, GPS, sensors, and local database with SQLite.

## Features

### Core Functionality
- Task Management - Create, edit, delete and complete tasks
- Task Statistics - Track completion rates and pending tasks
- Pink Theme - Beautiful pink color scheme with light/dark mode support
- Multi-language - Currently supports English UI
- Cross-platform - Works on Android, iOS, Linux, Windows, and macOS

### Native Device Features

#### Camera Integration
- Take photos directly from the device camera
- Select photos from gallery
- Multiple photos per task - Add and manage several photos for each task
- Photo preview and full-screen view
- Photo deletion and management

#### GPS & Location Services
- Get current location with one tap
- Search addresses with geocoding
- Display formatted coordinates
- Calculate distance between locations
- Filter tasks by proximity (within 1km radius)
- Save location data with each task

#### Sensors
- Shake detection - Complete tasks by shaking your device
- Vibration feedback on shake detection
- Adjustable sensitivity threshold

#### Local Database
- SQLite database with sqflite
- Desktop support (Linux, Windows, macOS) via sqflite_common_ffi
- Automatic database migrations
- Efficient query system with filtering

### Task Categories
- Work
- Personal
- Study
- Health
- Shopping
- Finance
- Home
- Other

### Priority Levels
- Urgent
- High
- Medium
- Low

## Project Structure

```
task_manager/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   ├── task.dart                      # Task data model
│   │   └── category.dart                  # Category definitions
│   ├── services/
│   │   ├── database_service.dart          # SQLite operations
│   │   ├── camera_service.dart            # Camera & gallery integration
│   │   ├── sensor_service.dart            # Shake detection
│   │   ├── location_service.dart          # GPS & geocoding
│   │   └── notification_service.dart      # Local notifications
│   ├── screens/
│   │   ├── task_list_screen.dart          # Main task list view
│   │   ├── task_form_screen.dart          # Create/edit tasks
│   │   └── camera_screen.dart             # Camera preview
│   └── widgets/
│       ├── task_card.dart                 # Task display widget
│       └── location_picker.dart           # Location selection widget
├── android/                                # Android configuration
├── ios/                                    # iOS configuration
├── linux/                                  # Linux configuration
├── macos/                                  # macOS configuration
├── windows/                                # Windows configuration
└── pubspec.yaml                            # Dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart 3.9.2 or higher
- Android Studio / Xcode (for mobile development)
- Visual Studio / Xcode / Linux dev tools (for desktop development)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/arthurcuri/geolocalization-camera.git
cd geolocalization-camera
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**

For Android/iOS:
```bash
flutter run
```

For Linux:
```bash
flutter run -d linux
```

For Windows:
```bash
flutter run -d windows
```

For macOS:
```bash
flutter run -d macos
```


## Dependencies

### Core Dependencies
- `flutter` - Flutter SDK
- `flutter_localizations` - Internationalization support

### Database
- `sqflite: ^2.3.0` - SQLite database for mobile
- `sqflite_common_ffi: ^2.3.0` - SQLite for desktop platforms
- `path_provider: ^2.1.1` - Access to filesystem paths
- `path: ^1.8.3` - Path manipulation utilities

### Camera & Media
- `camera: ^0.10.5+9` - Camera access
- `image_picker: ^1.0.7` - Pick images from gallery

### Location
- `geolocator: ^14.0.2` - GPS and location services
- `geocoding: ^4.0.0` - Address to coordinates conversion

### Sensors
- `sensors_plus: ^7.0.0` - Accelerometer for shake detection
- `vibration: ^3.1.4` - Haptic feedback

### Notifications
- `flutter_local_notifications: ^19.5.0` - Local notifications
- `timezone: ^0.10.1` - Timezone support for notifications

### Utilities
- `uuid: ^4.2.1` - Generate unique IDs
- `intl: ^0.20.2` - Date formatting and internationalization
- `cupertino_icons: ^1.0.8` - iOS-style icons

## Implemented Features from Exercise List

### Completed

1. **Gallery Photos**
   - Option to select photos from gallery
   - Uses image_picker package
   - Integrated in camera service

2. **Multiple Photos**
   - Support for multiple photos per task
   - Photo gallery view
   - Individual photo deletion
   - Horizontal scrollable photo list


### Main Features
- Task list with statistics
- Task creation form with camera and GPS
- Multiple photo gallery view
- Location picker with map preview
- Shake to complete tasks



## Author

Arthur Curi
- GitHub: [@arthurcuri](https://github.com/arthurcuri)
- Repository: [geolocalization-camera](https://github.com/arthurcuri/geolocalization-camera)
