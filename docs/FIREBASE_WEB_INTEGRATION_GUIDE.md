# Bait Guard — Firebase Web Integration & Backend Logic Guide

**Target Audience**: Web Developer / Frontend Engineering Intern  
**Project Name**: Bait Guard  
**Firebase Project ID**: `bait-guard-6f470`  
**Firebase Project Number**: `609454017958`  
**Plan Tier**: Firebase Spark (Free Tier)  
**Last Updated**: September 5, 2026  

---

## 1. Executive Summary & Shared System Architecture

The Bait Guard system uses a single unified Firebase project shared between the **Flutter Mobile Application** (Android & iOS) and the **Web Dashboard Application** (React, Vue, Next.js, or Vanilla JS).

Both clients connect to the **exact same Firebase backend**:
- **Same Authentication Users**: Managed via Firebase Auth (Email & Password).
- **Same Cloud Firestore Database**: Same collections (`users`, `accessRequests`), same document IDs, and same field types.
- **Same Firestore Security Rules**: Enforced at the server level via `firestore.rules`.
- **Same Role & Permission Hierarchy**: `admin`, `technician`, and `viewer`.

```text
┌─────────────────────────────────────────────────────────────┐
│             Shared Firebase Project: bait-guard-6f470       │
├──────────────────────────────┬──────────────────────────────┤
│   Firebase Authentication    │       Cloud Firestore        │
│   (Email / Password, Reset)  │  - users/{uid}               │
│                              │  - accessRequests/{id}       │
└──────────────▲───────────────┴──────────────▲───────────────┘
               │                              │
       ┌───────┴────────┐             ┌───────┴────────┐
       │                │             │                │
┌──────┴───────┐ ┌──────┴──────┐ ┌────┴────────┐ ┌─────┴────────┐
│ Flutter App  │ │ Flutter App │ │ Web App     │ │ Web App      │
│ (Technician) │ │ (Admin)     │ │ (Admin Ops) │ │ (Tech/Viewer)│
└──────────────┘ └─────────────┘ └─────────────┘ └──────────────┘
```

> [!IMPORTANT]
> **Spark Plan Boundary**: The project runs on the free Spark tier without Cloud Functions or backend Node Admin SDK. Identity, roles, and facility access permissions are stored directly in Cloud Firestore (`users/{uid}` collection) and secured via Firestore Security Rules.

---

## 2. How to Check if the Web App is Connected to Firebase

To verify that your web application is successfully communicating with the Firebase project, use the following checks.

### 2.1 Step-by-Step Connection Check
1. **App Initialization Check**: Verify that `getApps().length > 0`.
2. **Auth Service Check**: Verify that `auth.name` is loaded and `onAuthStateChanged` fires.
3. **Firestore Service Check**: Attempt a read from Firestore.
4. **Authorized Domain Check**: Verify your development URL is allowed in Firebase Console.

### 2.2 Ready-to-Use Connection Test Script
Create a test file in your web project (e.g., `src/utils/testFirebaseConnection.js`):

```javascript
import { auth, db } from "../firebase/config";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";

export async function testFirebaseConnection() {
  console.log("🔍 Testing Firebase Connection...");

  // 1. Check App Config
  if (!auth.app) {
    console.error("❌ Firebase App is NOT initialized.");
    return { success: false, step: "init", error: "Firebase App not initialized" };
  }
  console.log("✅ Firebase App Initialized:", auth.app.name);
  console.log("   Project ID:", auth.app.options.projectId);

  // 2. Check Auth Service
  try {
    await new Promise((resolve) => {
      const unsubscribe = onAuthStateChanged(auth, (user) => {
        console.log("✅ Firebase Auth Connected. Current user:", user ? user.email : "No user signed in (Guest)");
        unsubscribe();
        resolve(user);
      });
    });
  } catch (err) {
    console.error("❌ Firebase Auth connection failed:", err.message);
    return { success: false, step: "auth", error: err.message };
  }

  // 3. Check Firestore Network Connection
  try {
    // Attempt to read a non-existent test document to verify Firestore network handshake
    const testRef = doc(db, "_health_check", "ping");
    await getDoc(testRef);
    console.log("✅ Cloud Firestore Connected successfully.");
  } catch (err) {
    // permission-denied is actually PROOF of connection! (Security rules responded)
    if (err.code === "permission-denied") {
      console.log("✅ Cloud Firestore Connected (Security Rules actively protecting database).");
    } else {
      console.error("❌ Firestore connection failed:", err.code, err.message);
      return { success: false, step: "firestore", error: err.message };
    }
  }

  console.log("🎉 All Firebase services are LIVE and connected!");
  return { success: true };
}
```

### 2.3 Ready-to-Use React Test Component
If you are using React, drop this component onto any page to get a live visual indicator:

```jsx
import React, { useEffect, useState } from "react";
import { auth, db } from "./firebase/config";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";

export function FirebaseStatusChecker() {
  const [status, setStatus] = useState({
    initialized: false,
    authConnected: false,
    firestoreConnected: false,
    currentUser: null,
    error: null,
  });

  useEffect(() => {
    async function check() {
      try {
        // 1. Init
        const isInit = Boolean(auth.app && auth.app.options.projectId === "bait-guard-6f470");

        // 2. Auth
        onAuthStateChanged(auth, async (user) => {
          let firestoreOk = false;
          let errorMessage = null;

          try {
            const testDoc = await getDoc(doc(db, "_health_check", "ping"));
            firestoreOk = true;
          } catch (e) {
            // permission-denied proves server responded
            if (e.code === "permission-denied" || e.code === "not-found") {
              firestoreOk = true;
            } else {
              errorMessage = `${e.code}: ${e.message}`;
            }
          }

          setStatus({
            initialized: isInit,
            authConnected: true,
            firestoreConnected: firestoreOk,
            currentUser: user ? user.email : "Not signed in",
            error: errorMessage,
          });
        });
      } catch (err) {
        setStatus((prev) => ({ ...prev, error: err.message }));
      }
    }
    check();
  }, []);

  return (
    <div style={{ padding: 16, border: "1px solid #E2E8F0", borderRadius: 8, background: "#F8FAFC", maxWidth: 450, fontFamily: "sans-serif" }}>
      <h4 style={{ margin: "0 0 12px 0", color: "#0F172A" }}>🔥 Firebase Connection Status</h4>
      <div style={{ fontSize: 14, lineHeight: "24px" }}>
        <div>Project ID: <b>bait-guard-6f470</b></div>
        <div>Firebase App: {status.initialized ? "🟢 Initialized" : "🔴 Failed"}</div>
        <div>Auth Service: {status.authConnected ? "🟢 Connected" : "🟡 Checking..."}</div>
        <div>Firestore DB: {status.firestoreConnected ? "🟢 Connected" : "🟡 Checking..."}</div>
        <div>Auth State: <b>{status.currentUser || "Checking..."}</b></div>
      </div>
      {status.error && (
        <div style={{ marginTop: 8, color: "#EF4444", fontSize: 12 }}>
          ⚠️ Error: {status.error}
        </div>
      )}
    </div>
  );
}
```

### 2.4 Browser DevTools (F12) Checklist & Common Errors
Open your browser's Developer Tools (`F12` or `Ctrl+Shift+I`) and look at the **Console** and **Network** tabs:

| Error Code / Symptom | Root Cause | Solution |
|---|---|---|
| `auth/unauthorized-domain` | Your current web URL is not on the Firebase authorized domain list. | In Firebase Console → **Authentication** → **Settings** tab → **Authorized domains** → Click **Add domain** → Add your host (e.g. `localhost`, `127.0.0.1`, or your deployment domain). |
| `auth/api-key-not-valid` | The API Key in `firebaseConfig` is mistyped or disabled. | Verify `apiKey: "AIzaSyCETKZpFXuyvY7dGEpyz5Q2dtqpDpE3kDg"` exactly. |
| `permission-denied` on unauthenticated read | Firestore Security Rules require authentication to read `users` or `accessRequests`. | This is normal! Log in with a valid account or submit a public request to test writes. |
| CORS or Network Error (`Failed to fetch`) | Ad-blocker (uBlock Origin, Brave Shields) or firewall blocking `*.googleapis.com`. | Whitelist Google/Firebase domains or temporarily disable ad-blockers during local dev. |

---

## 3. Web Firebase Configuration (`src/firebase/config.js`)

Copy this exact snippet into your web project:

```javascript
import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getAnalytics } from "firebase/analytics";

// Configured credentials for Bait Guard Web App
export const firebaseConfig = {
  apiKey: "AIzaSyCETKZpFXuyvY7dGEpyz5Q2dtqpDpE3kDg",
  authDomain: "bait-guard-6f470.firebaseapp.com",
  databaseURL: "https://bait-guard-6f470-default-rtdb.firebaseio.com",
  projectId: "bait-guard-6f470",
  storageBucket: "bait-guard-6f470.firebasestorage.app",
  messagingSenderId: "609454017958",
  appId: "1:609454017958:web:7e2c5b584bd0878ec8d367",
  measurementId: "G-5BRL68FG0Y"
};

// Initialize Firebase (prevents duplicate app initialization in frameworks like Next.js)
export const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const analytics = typeof window !== "undefined" ? getAnalytics(app) : null;
```

---

## 4. Complete Backend Logic & Service Implementations

Here is the exact backend logic implemented in the mobile app, translated into ready-to-use JavaScript service modules for the web app.

### 4.1 Authentication Service (`src/services/authService.js`)

```javascript
import {
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  onAuthStateChanged,
} from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "../firebase/config";

/**
 * Normalizes email: trim whitespace and convert to lowercase.
 */
export function normalizeEmail(email) {
  return email ? email.trim().toLowerCase() : "";
}

/**
 * Signs in a user and validates their Firestore application profile.
 * Rejects disabled users or accounts without a Firestore profile.
 */
export async function loginUser(email, password) {
  const cleanEmail = normalizeEmail(email);
  if (!cleanEmail || !password) {
    throw new Error("Please provide both email and password.");
  }

  // 1. Firebase Auth Sign-in
  const userCredential = await signInWithEmailAndPassword(auth, cleanEmail, password);
  const firebaseUser = userCredential.user;

  // 2. Fetch User Profile from Firestore
  const profileDoc = await getDoc(doc(db, "users", firebaseUser.uid));
  if (!profileDoc.exists()) {
    await signOut(auth);
    throw new Error("Your user profile does not exist. Please contact an administrator.");
  }

  const profile = profileDoc.data();

  // 3. Verify Account Status
  if (profile.status !== "active") {
    await signOut(auth);
    throw new Error("Your account has been disabled. Please contact your facility administrator.");
  }

  // 4. Return user and profile containing role ('admin' | 'technician' | 'viewer') and facilityIds
  return {
    uid: firebaseUser.uid,
    email: cleanEmail,
    displayName: profile.displayName || cleanEmail,
    role: profile.role,
    status: profile.status,
    facilityIds: profile.facilityIds || [],
    company: profile.company || "",
  };
}

/**
 * Signs out the currently authenticated user.
 */
export async function logoutUser() {
  await signOut(auth);
}

/**
 * Sends a password reset email using Firebase's default flow.
 */
export async function sendPasswordReset(email) {
  const cleanEmail = normalizeEmail(email);
  if (!cleanEmail) throw new Error("Please enter your email address.");
  await sendPasswordResetEmail(auth, cleanEmail);
}

/**
 * Subscribes to authentication state changes and loads profile.
 * Use this in your App/Router layout.
 */
export function subscribeToAuth(callback) {
  return onAuthStateChanged(auth, async (user) => {
    if (!user) {
      callback({ user: null, profile: null, loading: false });
      return;
    }

    try {
      const snap = await getDoc(doc(db, "users", user.uid));
      if (snap.exists() && snap.data().status === "active") {
        callback({ user, profile: snap.data(), loading: false });
      } else {
        await signOut(auth);
        callback({ user: null, profile: null, loading: false });
      }
    } catch (err) {
      console.error("Failed to load user profile:", err);
      callback({ user: null, profile: null, loading: false, error: err.message });
    }
  });
}
```

---

### 4.2 Access Request Service (`src/services/accessRequestService.js`)

Used for public applicants requesting access and administrators reviewing requests.

```javascript
import {
  collection,
  doc,
  addDoc,
  getDocs,
  query,
  where,
  orderBy,
  runTransaction,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "../firebase/config";
import { normalizeEmail } from "./authService";

/**
 * Public function: Submit a new access request.
 * Allowed by Firestore security rules for unauthenticated users.
 */
export async function submitAccessRequest({ fullName, email, company, phone, department = "", message = "" }) {
  const cleanEmail = normalizeEmail(email);
  if (!fullName || !cleanEmail || !company || !phone) {
    throw new Error("Full name, email, company, and phone are required.");
  }

  const payload = {
    fullName: fullName.trim(),
    email: email.trim(),
    normalizedEmail: cleanEmail,
    company: company.trim(),
    phone: phone.trim(),
    department: department ? department.trim() : "",
    message: message ? message.trim() : "",
    status: "pending",
    submittedAt: serverTimestamp(),
  };

  const docRef = await addDoc(collection(db, "accessRequests"), payload);
  return docRef.id;
}

/**
 * Admin function: Query pending access requests ordered newest first.
 * Requires active Admin session.
 */
export async function getPendingRequests() {
  const q = query(
    collection(db, "accessRequests"),
    where("status", "==", "pending"),
    orderBy("submittedAt", "desc")
  );

  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * Admin function: Approve a pending request.
 * Assigns role ('technician' | 'viewer') and facility IDs.
 */
export async function approveAccessRequest(requestId, { role, facilityIds, reviewerUid }) {
  if (!["technician", "viewer"].includes(role)) {
    throw new Error("Assigned role must be either 'technician' or 'viewer'.");
  }
  if (!facilityIds || facilityIds.length === 0) {
    throw new Error("At least one facility must be assigned.");
  }

  const reqRef = doc(db, "accessRequests", requestId);

  await runTransaction(db, async (transaction) => {
    const snap = await transaction.get(reqRef);
    if (!snap.exists()) throw new Error("Request document does not exist.");
    if (snap.data().status !== "pending") {
      throw new Error("This request has already been reviewed.");
    }

    transaction.update(reqRef, {
      status: "approved",
      assignedRole: role,
      assignedFacilityIds: facilityIds,
      reviewedBy: reviewerUid,
      reviewedAt: serverTimestamp(),
      approvalSource: "request",
    });
  });
}

/**
 * Admin function: Reject a pending request.
 */
export async function rejectAccessRequest(requestId, { reason = "", reviewerUid }) {
  const reqRef = doc(db, "accessRequests", requestId);

  await runTransaction(db, async (transaction) => {
    const snap = await transaction.get(reqRef);
    if (!snap.exists()) throw new Error("Request document does not exist.");
    if (snap.data().status !== "pending") {
      throw new Error("This request has already been reviewed.");
    }

    transaction.update(reqRef, {
      status: "rejected",
      rejectionReason: reason ? reason.trim() : null,
      reviewedBy: reviewerUid,
      reviewedAt: serverTimestamp(),
    });
  });
}
```

---

### 4.3 User Management Service (`src/services/userService.js`)

Used by all users for self-profile viewing/editing, and by Administrators for managing other users.

```javascript
import {
  collection,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  runTransaction,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "../firebase/config";

/**
 * Fetches user profile by UID.
 */
export async function getUserProfile(uid) {
  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() };
}

/**
 * Self-service: User updates their own personal profile fields.
 * Security rules only permit personal fields; role/status/facilities cannot be changed here.
 */
export async function updateSelfProfile(uid, { firstName = "", lastName = "", jobTitle = "", department = "", phone = "", bio = "" }) {
  const userRef = doc(db, "users", uid);
  const fullName = `${firstName.trim()} ${lastName.trim()}`.trim();

  await updateDoc(userRef, {
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    displayName: fullName || "User",
    jobTitle: jobTitle.trim(),
    department: department.trim(),
    phone: phone.trim(),
    bio: bio.trim(),
    updatedAt: serverTimestamp(),
  });
}

/**
 * Admin function: Get all users in the system.
 */
export async function getAllUsers() {
  const snapshot = await getDocs(collection(db, "users"));
  return snapshot.docs.map((d) => ({
    id: d.id,
    ...d.data(),
  }));
}

/**
 * Admin function: Update non-admin user role, application status, or facility IDs.
 * Strictly enforced: Cannot modify other admins or self.
 */
export async function adminManageUser(targetUid, { role, status, facilityIds }) {
  if (!["technician", "viewer"].includes(role)) {
    throw new Error("Role must be 'technician' or 'viewer'. Admins cannot be assigned via client.");
  }
  if (!["active", "disabled"].includes(status)) {
    throw new Error("Status must be 'active' or 'disabled'.");
  }
  if (!facilityIds || facilityIds.length === 0) {
    throw new Error("User must have at least one facility assigned.");
  }

  const targetRef = doc(db, "users", targetUid);

  await runTransaction(db, async (transaction) => {
    const snap = await transaction.get(targetRef);
    if (!snap.exists()) throw new Error("Target user profile does not exist.");
    if (snap.data().role === "admin") {
      throw new Error("Admin profiles cannot be modified from the client.");
    }

    transaction.update(targetRef, {
      role,
      status,
      facilityIds,
      updatedAt: serverTimestamp(),
    });
  });
}
```

---

## 5. Firestore Schemas & Data Model Reference

### 5.1 Collection: `users/{uid}`
Document ID **must equal the Firebase Auth UID**.

```json
{
  "uid": "ABcd1234XYZ...",
  "displayName": "John Doe",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "role": "technician",
  "status": "active",
  "facilityIds": ["site_1", "site_2"],
  "company": "Trinode Logistics",
  "department": "Pest Management",
  "phone": "+1-555-0199",
  "jobTitle": "Field Technician",
  "bio": "Lead station inspector for Warehouse A",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 5.2 Collection: `accessRequests/{requestId}`
Auto-generated document ID.

```json
{
  "fullName": "Jane Smith",
  "email": "jane@example.com",
  "normalizedEmail": "jane@example.com",
  "company": "Cold Storage Inc",
  "phone": "+1-555-0144",
  "department": "Facility Operations",
  "message": "Requesting viewer access for facility monitoring",
  "status": "approved",
  "submittedAt": "Timestamp",
  "reviewedBy": "ADMIN_UID_HERE",
  "reviewedAt": "Timestamp",
  "assignedRole": "viewer",
  "assignedFacilityIds": ["site_4"],
  "approvalSource": "request",
  "rejectionReason": null,
  "activatedUid": "ACTIVATED_AUTH_UID",
  "activatedAt": "Timestamp"
}
```

---

## 6. Firestore Composite Indexes

If the web application queries pending requests or performs activation queries, make sure these two composite indexes are created in Firebase Console under **Firestore Database → Indexes**:

1. **Pending Requests Index**:
   - Collection: `accessRequests`
   - Fields:
     - `status` (Ascending)
     - `submittedAt` (Descending)
2. **Account Activation Index**:
   - Collection: `accessRequests`
   - Fields:
     - `normalizedEmail` (Ascending)
     - `status` (Ascending)
     - `activatedUid` (Ascending)

---

## 7. Seeded Facility / Site IDs

Both Mobile and Web share the same pre-seeded facility mapping:

| Facility ID | Display Name | Type |
|---|---|---|
| `site_1` | Warehouse A | Industrial Storage |
| `site_2` | Warehouse B | Commercial Distribution |
| `site_3` | Distribution Center | Logistics Hub |
| `site_4` | Cold Storage | Refrigerated Warehouse |
| `site_5` | Manufacturing Plant | Production Facility |

> **Facility Isolation Rule**: Always filter the stations, alerts, and metrics on your web dashboard by the user's `profile.facilityIds`. If a user only has `["site_1"]`, they must never see data for `site_2`–`site_5`.

---

## 8. What is Implemented in Firebase vs. What is Left (The Mock vs. Real Boundary)

To ensure the web app and mobile app stay completely aligned, here is the official feature boundary:

| Feature Area | Implementation Status | Data Source | Details & Rules for Web Developer |
|---|---|---|---|
| **User Sign-In & Logout** | ✅ Complete | Real Firebase Auth | Email/Password with Firestore status verification. |
| **User Roles & Access** | ✅ Complete | Real Firestore `users` | Roles: `admin`, `technician`, `viewer`. |
| **Request Access Pipeline** | ✅ Complete | Real Firestore `accessRequests` | Public submission → Admin Approve/Reject. |
| **User Management** | ✅ Complete | Real Firestore `users` | Admin can view users, change roles/status/facilities. |
| **Self Profile Editing** | ✅ Complete | Real Firestore `users` | Users can edit bio, name, phone, job title. |
| **Password Reset** | ✅ Complete | Real Firebase Auth | Standard Firebase reset email flow. |
| **Station Records & Roster** | ⏳ Mock Data on Frontend | Seeded Mock Data | **Do NOT create Firestore tables for stations yet.** Hardware telemetry schema is pending supervisor approval. |
| **Live Camera / Video** | ⏳ Static Placeholder | Visual UI Only | **No RTSP, WebRTC, or camera streaming.** Style as a static camera placeholder. |
| **Rodent Evidence Images** | ⏳ Mock Assets | Local/Mock URLs | **Firebase Storage is NOT enabled.** Do not write image upload logic. |
| **Real-time Telemetry Ingestion** | ⏳ Pending Hardware | Seeded Metrics | Battery %, bait %, load cell, and tamper states are currently simulated on client. |
| **Reports / PDF Exports** | ⏳ Client-Side Simulation | Mock Calculations | Generated client-side. No Cloud Functions. |
| **Facility Map** | ⏳ Mock Floor Plan | Custom Vector / SVG Map | Use a custom floor plan diagram; do not integrate Google Maps API yet. |

---

## 9. Web Integration Checklist

Follow this checklist to connect your web app:
- [ ] Paste the `firebaseConfig` object into `src/firebase/config.js`.
- [ ] Add your development URL (`localhost`, `127.0.0.1`) to **Authorized domains** in Firebase Console.
- [ ] Run the `testFirebaseConnection()` function or embed `<FirebaseStatusChecker />` to verify connection.
- [ ] Implement login using `loginUser()` and verify that `users/{uid}` is loaded.
- [ ] Use `profile.role` to conditionally render Admin navigation vs. Technician/Viewer navigation.
- [ ] Filter all dashboard cards and data views by `profile.facilityIds`.
- [ ] Wire the public "Request Access" form to `submitAccessRequest()`.
- [ ] Keep station metrics, telemetry, and camera views consistent with the mock specification until the hardware backend is deployed.
