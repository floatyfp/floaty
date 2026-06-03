# Floaty
#### An unofficial Floatplane client for Windows, Linux, MacOS, iOS and Android.
#### ⚠️Spaghetti code
This repository is the tartar sauce spaghetti code of Floaty.

### [Download Here](https://floaty.fyi/download) 

## 📃Feature Matrix
| **Feature**                | **Windows** | **MacOS** | **Linux** | **Android** | **iOS** | **Info**                  |
|----------------------------|-------------|-----------|-----------|-------------|---------|---------------------------|
| **Channel Page**           | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Post Page**              | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Playback**               | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Livestream Page**        | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Livesteam playback**     | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Live Chat**              | ⚠️           | ⚠️         | ⚠️         | ⚠️           | ⚠️       | Awaiting Fix from floatplane.             | 
| **Live Chat Polls**        | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Live Chat Emotes**       | ⚠️           | ⚠️         | ⚠️         | ⚠️           | ⚠️       |                                           |
| **Floatplane Settings**    | ⚠️           | ⚠️         | ⚠️         | ⚠️           | ⚠️       | Some settings are there.                  |
| **Home Page**              | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Whenplane intergration** | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Updater**                | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **PiP**                    | ✅           | ✅         | ✅         | ✅           | ❌       |                                           |
| **Mini Player**            | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Subtitles**              | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Download**               | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |
| **Login**                  | ✅           | ✅         | ✅         | ✅           | ✅       |                                           |                                        |
| **Notifications**          | ❌           | ❌         | ❌         | ❌           | ❌       | Deciding on how to complete this.         |


## 🛠️ How to Compile and Run

### 1. Install Flutter

First, install Flutter by following the official guide:  
➡️ [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)

Make sure to set up your system PATH to include the `flutter/bin` directory.  
Verify installation:
```bash
flutter --version
```

### 2. Clone the repository

```bash
git clone https://github.com/floatyfp/floaty.git
cd floaty
```

### 3. Install dependencies

Some dependencies rely on Rust, install Rust first by following the official guide:  
➡️ [Rust Installation Guide](https://www.rust-lang.org/tools/install)

```bash
flutter pub get
```

### 4. Run the app

Make sure you have an Android/iOS device or a desktop environment ready.

To get a list of available devices and select an option to run on:
```bash
flutter run
```
Or list devices and run on a specific one:
```bash
flutter devices
flutter run -d DEVICE_ID
```

### 5. Build the app
You can build the app in either release or debug mode. If you're building it in release refer to step 6 to setup certificates.

- **Android APK**  
  Build a release APK:
  ```bash
  flutter build apk --<INSERT MODE>
  ```

- **iOS**  
  Build for iOS (requires macOS and Xcode):
  ```bash
  flutter build ios --<INSERT MODE>
  ```

## iOS install via SideStore / AltStore

CI builds an IPA on each deploy, packages it for SideStore (correct `Payload/` zip layout + ad-hoc `codesign` on macOS), and regenerates an [AltStore source](https://faq.altstore.io/developers/make-a-source) at `docs/altstore-source.json` from **all** GitHub Releases, including pre-releases.

**Source URL** (add once in SideStore or AltStore):

`https://github.com/floatyfp/floaty/blob/release/docs/altstore-source.json?raw=true`

(or the equivalent raw URL for your fork/branch)

Edit static metadata in `docs/altstore-source.meta.json`; version entries are filled automatically from release assets (`floaty-*-ios.ipa`).

- **Windows**
  ```bash
  flutter build windows --<INSERT MODE>
  ```

- **macOS**
  ```bash
  flutter build macos --<INSERT MODE>
  ```

- **Linux**
  ```bash
  flutter build linux --<INSERT MODE>
  ```

### 6. (Optional) Setup Release Signing for Android

To publish a signed APK or App Bundle:

1. Generate a signing key:
   ```bash
   keytool -genkey -v -keystore ~/your_keystore_name.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your_key_alias
   ```
2. Create a `key.properties` file in the `android/` directory:
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=your_key_alias
   storeFile=/path/to/your_keystore_name.jks
   ```
3. Edit `android/app/build.gradle` to load the `key.properties` and configure signingConfigs.

Full guide here: [Signing Flutter apps](https://docs.flutter.dev/deployment/android#signing-the-app)
