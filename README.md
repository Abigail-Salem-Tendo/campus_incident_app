# Campus Incident Reporting App

A Flutter mobile app where students report campus issues (maintenance, safety, cleanliness, utilities, IT, and network), and authorized staff track them by updating each report's status. Built with Flutter and Firebase for Individual Assignment 2.

**Author:** Abigail Salem Tendo

**Demo video:** https://youtu.be/cg5gOQMtX9E

**Technical report:** https://docs.google.com/document/d/1i_C0TRe1LyDb_MAj5b4BYkC_waxSw5n-Mdt3-A5j-_g/edit?usp=sharing

## Features

- **Sign up and login** limited to ALU emails (`@alustudent.com` for students, `@alueducation.com` for staff), with email verification required.
- **Reports:** students create reports with a title, description, category, location, optional photo, and an anonymous option.
- **Edit and delete:** students can change or delete their own report only while its status is *Submitted*.
- **Status tracking:** *Submitted*, *Under Review*, *In Progress*, *Resolved*. Only staff can change the status.
- **Live updates** through Firestore snapshots.
- **Staff view:** all reports, four status-count tiles, All/My reports toggle, search by title, status chips, and a category filter.
- **Bottom navigation** that depends on the role: students get Reports, New report and Settings; staff get Reports and Settings.
- **Settings:** light or dark theme (saved on the device with `shared_preferences`) and logout.
- **Photos:** compressed on the phone (1280 px, JPEG 75), rejected if still over 1 MB, and uploaded to Cloudinary.

## Roles and security

Everyone registers as a **student**. An administrator sets the **staff** role manually by editing `users/{uid}.role` in the Firestore console; it cannot be changed from the app.

Access is enforced by the Firestore security rules in [`firebase.rules`](firebase.rules), not by the interface:

- Students read only their own reports; staff read all.
- Students can create reports, and edit or delete their own only while the status is *Submitted*.
- Staff can change only `status` and `updatedAt`. They cannot create, edit or delete reports.

## Tech stack

| Area | Choice |
|---|---|
| App | Flutter (Dart), Material 3, teal seed `#00796B`, Inter font |
| Backend | Firebase Auth (email/password + verification), Cloud Firestore |
| Photos | Cloudinary (unsigned upload preset) |
| State management | Provider (`AuthProvider`, `ReportProvider`, `ThemeProvider`) |
| Local storage | `shared_preferences` (theme choice) |

## Project structure

```
lib/
  core/        theme, constants, utils
  models/      report_model, user_model
  services/    auth, report, photo and storage services
  providers/   AuthProvider, ReportProvider, ThemeProvider
  screens/     auth, home, reports, settings
  widgets/     shared widgets
test/          validators_test.dart, report_model_test.dart
firebase.rules
```

## Getting started

**Requirements:** Flutter 3.47.2 (Dart 3.13.2), an Android phone or emulator, and a Firebase project with Email/Password sign-in and Firestore enabled.

1. Clone the repository and install packages:
   ```
   git clone https://github.com/Abigail-Salem-Tendo/campus_incident_app.git
   cd campus_incident_app
   flutter pub get
   ```
2. Connect your own Firebase project:
   ```
   dart pub global run flutterfire_cli:flutterfire configure
   ```
3. Publish the rules in `firebase.rules` to your Firestore database, and create the composite index on `reports` (`reporterId` ascending, `createdAt` descending). Firestore shows a link to create it the first time the student query runs.
4. Set your Cloudinary cloud name and unsigned upload preset in the app's constants.
5. Run the app:
   ```
   flutter run
   ```

To test staff features, register an ALU staff-domain account, verify the email, then set `role` to `staff` in that user's document in the Firestore console.

## Tests

```
flutter test
```

22 unit tests cover the input validators and the report model (including a check that stored status and category names match the names used in the security rules). The security rules were checked in the Firebase Rules Playground.

## Known limitations

- Anonymity is UI-level only: `reporterId` and `reporterName` are always stored.
- The Cloudinary preset is unsigned, so uploads have no login check. Photos stay in Cloudinary after a report is deleted, because deleting needs a secret key that must not be placed in a mobile app.
- Screens and providers have no automated tests.
- The theme choice is saved per device, not per account.
