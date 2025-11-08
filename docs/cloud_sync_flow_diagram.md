# Cloud Sync Flow Diagrams

## User Login Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Opens App                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   User Logs In       │
              │  (Phone or Email)    │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Auth State Changed  │
              │   (AuthService)      │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ Check Local Database │
              │      Is Empty?       │
              └──────────┬───────────┘
                         │
                ┌────────┴────────┐
                │                 │
            YES │                 │ NO
                │                 │
                ▼                 ▼
    ┌──────────────────┐  ┌──────────────────┐
    │ Check Cloud Data │  │  Upload Local    │
    │     Exists?      │  │  Data to Cloud   │
    └────────┬─────────┘  └──────────────────┘
             │
      ┌──────┴──────┐
      │             │
  YES │             │ NO
      │             │
      ▼             ▼
┌──────────┐  ┌──────────┐
│ Restore  │  │  Start   │
│   From   │  │  Fresh   │
│  Cloud   │  │          │
└────┬─────┘  └────┬─────┘
     │             │
     └──────┬──────┘
            │
            ▼
  ┌──────────────────┐
  │  Enable Auto-    │
  │  Sync (5 min)    │
  └──────────────────┘
```

## Data Sync Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Periodic Sync (Every 5 min)               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Read Local SQLite   │
              │  Database (All Data) │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Create Backup      │
              │   JSON Structure     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Determine Storage   │
              │  Path (Phone/Email)  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Upload to Cloud    │
              │   (Firestore)        │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Update Last Sync    │
              │     Timestamp        │
              └──────────────────────┘
```

## Data Restore Flow

```
┌─────────────────────────────────────────────────────────────┐
│              User Reinstalls App & Logs In                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Local DB is Empty   │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Determine Storage   │
              │  Path (Phone/Email)  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Fetch from Cloud    │
              │    (Firestore)       │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Parse JSON Data    │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Start Transaction   │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Insert Classes      │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Insert Students     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Insert Sessions     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Insert Records      │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Commit Transaction  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Data Restored! ✓    │
              └──────────────────────┘
```

## Storage Path Determination

```
┌─────────────────────────────────────────────────────────────┐
│                      User Model                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Has Phone Number?   │
              └──────────┬───────────┘
                         │
                ┌────────┴────────┐
                │                 │
            YES │                 │ NO
                │                 │
                ▼                 ▼
    ┌──────────────────┐  ┌──────────────────┐
    │  Sanitize Phone  │  │   Has Email?     │
    │  (+1234567890)   │  └────────┬─────────┘
    └────────┬─────────┘           │
             │              ┌──────┴──────┐
             │              │             │
             │          YES │             │ NO
             │              │             │
             │              ▼             ▼
             │    ┌──────────────┐  ┌──────────┐
             │    │ Sanitize     │  │ Use UID  │
             │    │ Email        │  │          │
             │    └──────┬───────┘  └────┬─────┘
             │           │               │
             ▼           ▼               ▼
    ┌──────────────────────────────────────────┐
    │         Firestore Path                   │
    ├──────────────────────────────────────────┤
    │ users_by_phone/{sanitized_phone}         │
    │ users_by_email/{sanitized_email}         │
    │ users_by_uid/{uid}                       │
    └──────────────────────────────────────────┘
```

## Data Structure in Firestore

```
Firestore Database
│
├── users_by_phone/
│   │
│   ├── _1234567890/                    ← Sanitized phone number
│   │   ├── user_id: "abc123"
│   │   ├── phone_number: "+1234567890"
│   │   ├── email: null
│   │   ├── last_sync: Timestamp(2024-01-15 10:30:00)
│   │   ├── app_version: 2
│   │   │
│   │   ├── data/
│   │   │   ├── classes: [
│   │   │   │     {id: 1, name: "Math 101", created_at: "...", ...},
│   │   │   │     {id: 2, name: "Physics", created_at: "...", ...}
│   │   │   │   ]
│   │   │   │
│   │   │   ├── students: [
│   │   │   │     {id: 1, class_id: 1, name: "John", ...},
│   │   │   │     {id: 2, class_id: 1, name: "Jane", ...}
│   │   │   │   ]
│   │   │   │
│   │   │   ├── attendance_sessions: [
│   │   │   │     {id: 1, class_id: 1, date: "2024-01-15", ...}
│   │   │   │   ]
│   │   │   │
│   │   │   └── attendance_records: [
│   │   │         {id: 1, session_id: 1, student_id: 1, is_present: 1, ...}
│   │   │       ]
│   │   │
│   │   └── metadata/
│   │       ├── total_classes: 2
│   │       ├── total_students: 50
│   │       ├── total_sessions: 30
│   │       └── total_records: 1500
│   │
│   └── _9876543210/                    ← Another user
│       └── ...
│
└── users_by_email/
    │
    ├── user_example_com/               ← Sanitized email
    │   ├── user_id: "xyz789"
    │   ├── phone_number: null
    │   ├── email: "user@example.com"
    │   ├── last_sync: Timestamp(2024-01-15 10:35:00)
    │   └── ... (same structure as above)
    │
    └── another_user_gmail_com/
        └── ...
```

## Security Rules Flow

```
┌─────────────────────────────────────────────────────────────┐
│              User Attempts to Access Data                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Is User             │
              │  Authenticated?      │
              └──────────┬───────────┘
                         │
                ┌────────┴────────┐
                │                 │
             NO │                 │ YES
                │                 │
                ▼                 ▼
         ┌──────────┐   ┌──────────────────┐
         │  DENY    │   │  Check Path      │
         │  ACCESS  │   │  Type            │
         └──────────┘   └────────┬─────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
         ┌──────────────┐ ┌──────────┐ ┌──────────┐
         │ Phone Path   │ │Email Path│ │ UID Path │
         └──────┬───────┘ └────┬─────┘ └────┬─────┘
                │              │            │
                ▼              ▼            ▼
         ┌──────────────┐ ┌──────────┐ ┌──────────┐
         │ Does User's  │ │Does User'│ │Does User'│
         │ Phone Match? │ │Email     │ │UID Match?│
         └──────┬───────┘ │Match?    │ └────┬─────┘
                │         └────┬─────┘      │
                │              │            │
         ┌──────┴──────┐  ┌───┴────┐  ┌────┴─────┐
         │             │  │        │  │          │
      YES│          NO │  │        │  │          │
         │             │  │        │  │          │
         ▼             ▼  ▼        ▼  ▼          ▼
    ┌─────────┐   ┌──────────────────────────────┐
    │ ALLOW   │   │         DENY ACCESS          │
    │ ACCESS  │   │                              │
    └─────────┘   └──────────────────────────────┘
```

## Multi-Device Sync Scenario

```
Device A                    Cloud (Firestore)              Device B
────────                    ─────────────────              ────────

User creates data
     │
     │ Sync (5 min)
     ├──────────────────────►
     │                       Data stored
     │                            │
     │                            │
     │                            │ User logs in
     │                            │◄────────────
     │                            │
     │                            │ Auto-restore
     │                            ├────────────►
     │                            │             Data appears!
     │                            │
User adds more data              │
     │                            │
     │ Sync (5 min)              │
     ├──────────────────────────►│
     │                       Updated data
     │                            │
     │                            │ Sync (5 min)
     │                            ├────────────►
     │                            │             Updated data!
     │                            │
     │                            │ User adds data
     │                            │◄────────────
     │                            │
     │                            │ Sync (5 min)
     │                            │◄────────────
     │                       Updated data
     │                            │
     │ Sync (5 min)              │
     │◄──────────────────────────┤
Updated data!                    │
```

## Legend

```
┌─────────┐
│  Box    │  = Process or State
└─────────┘

    │
    ▼         = Flow Direction

    ├──►      = Data Transfer

   YES/NO     = Decision Branch

    ✓         = Success/Complete
```
