# Lost & Found App: Project Review & Viva Prep

## 1. Project Review: Features & File Connections

### Main Features & Their Files

- **User Authentication (Register/Login)**
  - `lib/screens/register_screen.dart`: User registration UI and logic.
  - `lib/screens/login_screen.dart`: User login UI and logic.
  - Uses Firebase Authentication (see `firebase_options.dart` for config).

- **Home Screen (Item Feed & Search)**
  - `lib/screens/home_screen.dart`: Displays all lost/found items, search bar, navigation to chat/profile/post.

- **Post Item (Create Lost/Found Post)**
  - `lib/screens/post_item_screen.dart`: UI and logic for users to post new lost/found items (with image upload).

- **Profile**
  - `lib/screens/profile_screen.dart`: Shows user info, user’s posts, and logout option.

- **Chat**
  - `lib/screens/chat_screen.dart`: Messaging between users about items.

- **Firebase Integration**
  - `firebase_options.dart`, `pubspec.yaml`: Firebase setup and dependencies.

---

## 2. Authentication: Where, Why, and How

- **Where?**
  - In `register_screen.dart` and `login_screen.dart`.
  - Uses Firebase Authentication (see imports and usage of `FirebaseAuth`).

- **Why?**
  - To ensure only registered users can post, chat, or view certain features.
  - Protects user data and enables personalized experience.

- **How?**
  - Registration: User enters email/password → `FirebaseAuth.instance.createUserWithEmailAndPassword`.
  - Login: User enters email/password → `FirebaseAuth.instance.signInWithEmailAndPassword`.
  - Auth state is checked in main screens to show/hide content or redirect.

---

## 3. CRUD Operations: Where, Why, and How

- **Where?**
  - Create: `post_item_screen.dart` (posting new items), `register_screen.dart` (creating user).
  - Read: `home_screen.dart` (fetching items), `profile_screen.dart` (fetching user’s posts), `chat_screen.dart` (fetching messages).
  - Update: `profile_screen.dart` (updating user info), `post_item_screen.dart` (edit post, if implemented).
  - Delete: `profile_screen.dart` (delete user’s post), `post_item_screen.dart` (delete post, if implemented).

- **Why?**
  - CRUD = Create, Read, Update, Delete: Core to any app that manages data.
  - Allows users to manage their posts, profile, and messages.

- **How?**
  - Uses Firebase Firestore for data storage.
  - Example (Create): 
    - `FirebaseFirestore.instance.collection('items').add({...})` in `post_item_screen.dart`.
  - Example (Read): 
    - `StreamBuilder` or `FutureBuilder` to fetch data from Firestore in `home_screen.dart`.
  - Example (Update): 
    - `FirebaseFirestore.instance.collection('items').doc(id).update({...})`.
  - Example (Delete): 
    - `FirebaseFirestore.instance.collection('items').doc(id).delete()`.

---

## Quick Reference Table

| Feature         | Main File(s)                  | Firebase Used? | CRUD?      |
|-----------------|------------------------------|---------------|------------|
| Register/Login  | register_screen, login_screen | Yes           | Create/Read|
| Home/Feed       | home_screen                   | Yes           | Read       |
| Post Item       | post_item_screen              | Yes           | Create     |
| Profile         | profile_screen                | Yes           | Read/Update/Delete |
| Chat            | chat_screen                   | Yes           | Create/Read|
| Image Upload    | post_item_screen              | Yes (Storage) | Create     |

---

**Tip:** You can convert this file to PDF using any Markdown editor (Typora, VS Code extension, Dillinger.io, or even Google Docs/Word after copy-paste).
