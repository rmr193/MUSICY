# Musicy Mobile - Spotify Clone Flutter Application

This is a build-ready standalone mobile application replica of **Musicy**, styled with Spotify's dark theme, responsive layouts, and full playlist capabilities. 

It is self-contained: it searches YouTube and streams audio files natively on the device via the `youtube_explode_dart` client, meaning **it does not require running the Python server** on your desktop.

---

## Prerequisites for Compilation

To compile this project to an APK, you will need to set up the Flutter development environment on your machine.

1. **Install Flutter SDK**:
   - Download the SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows).
   - Extract it (e.g. `C:\src\flutter`) and add the `bin` directory to your System PATH variables.
   
2. **Install Java Development Kit (JDK)**:
   - Install JDK 17 (recommended for modern Gradle wrapper compilation).
   - Set the `JAVA_HOME` environment variable to your JDK path.

3. **Install Android Studio / Android SDK**:
   - Download Android Studio.
   - Install the **Android SDK Command-line Tools** and **Android SDK Build-tools** via the SDK Manager.
   - Run `flutter doctor --android-licenses` in your command line and accept all terms.

4. **Verify Setup**:
   - Run `flutter doctor` in your shell and resolve any missing configurations.

---

## Build Instructions (How to compile the APK)

Navigate to the `mobile_app` folder in your terminal and execute the following commands:

### 1. Download Dependencies
```bash
flutter pub get
```

### 2. Run in Debug Mode (on a connected device or emulator)
```bash
flutter run
```

### 3. Compile the Release APK
```bash
flutter build apk --release
```

After compilation completes, your APK file will be located at:
`[project-root]/mobile_app/build/app/outputs/flutter-apk/app-release.apk`

Copy this file to your Android phone (or download it directly), open it, and tap **Install** to run the app natively on your mobile phone!

---

## App Features (Standalone Mobile Architecture)
- **Home Screen**: Features quick playlist actions (Liked Songs and custom playlists) and recently played history.
- **Search Screen**: Connects directly to YouTube to list tracks, featuring manual Like and Add-to-Playlist buttons.
- **Library Screen**: Fully manages playlists (Create, Rename, Delete).
- **Persistent Player**: Features a mini-player bar and a full-screen player deck with shuffle toggles, repeat loops (One/All), and a seekable progress bar.
- **Data Persistence**: Playlists, history, volume, and likes are written to the local device storage using `shared_preferences`.
