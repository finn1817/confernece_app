# **Conference Event App**

**CSIT 425 – Software Engineering | Final Project**

---

## Description

This is a Flutter made Android app for viewing, searching, filtering and managing conference talks or events in real time.  
All data is stored in Firebase Cloud Database, and only admin users can log in to add or edit Events.

---

## Prerequisites

- Flutter SDK (greater than 3.0)  
- either an Android emulator or real Android device
- A Firebase project with **Cloud Firestore** enabled

---

## Setup & Run

1. **Clone the repo**  
   ```bash
   git clone https://github.com/<your-org>/conference_event_app.git
   cd conference_event_app

2. **Add Firebase Packages to your Flutter Project**
   ```bash
   flutter pub add firestore_core
   flutter pub add cloud_firestore

3. **Install Dependencies**
    ```bash
    flutter pub get

4. **Run on your Android Device**
   ```bash
   flutter run --release

**Or if you would rather download an APK and run it that way...**
   ```bash
   flutter build apk --split-per-abi
   ```
- And your project should show up at build\app\outputs\flutter-apk\
 
# How the database holds data for each Event
- Every new event creates new instances in the database instantly upon creation.

{\
  "day":                   "Tuesday",\
  "time":                  "11:00 AM",\
  "duration":              "1 Hour, 20 Min",\
  "title":                 "Class Time!",\
  "speaker":               "Dr. Haider",\
  "description":           "Not sure yet!",\
  "location":              "Science Center",\
  "track":                 "School",\
  "attendees":             "Dan, Greg, Aurora, Jiwon",\
  "colorCode":             "#FF5733",\
}

# How the database holds Users allowing admin Privilages
- We set this up so only admins can add new users or other Admins to the database. An admin is to be trated as highly important, as they have the privilage to delete other admins or Users in the database

{\
  "username":                   "exampleUser",\
  "password":                  "examplePass",\
  "isAdmin":              "[1 for admin | 0 for normal]",\
}

## Admin Mode
- Implements all **CRUD** fearures, lets you add, remove, and edit all events and info in each event! Also Allows you to add & remove Users or other Admins from the database!

---
# This project is in the master branch, not the main!
---

## Creators

- Dan [@finn1817](https://www.github.com/finn1817)

- Greg [@grega1303](https://www.github.com/grega1303)

- Aurora [@gome9667](https://www.github.com/gome9667)

- Jiwon: [@chae0123](https://www.github.com/chae0123)
