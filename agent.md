# Project Migration Blueprint: Web to Flutter (Crickifest)

## Core Objective
Convert the legacy web-based JavaScript application into a clean, modular, and highly readable Flutter/Dart mobile application. The target code must be written simply and follow clear design patterns so it can be effortlessly explained to a technical interviewer.

---

## Data Source Location
The agent must read all original business logic, UI layouts, and styling from the following directory:
*   `legacy_web_code/`

---

## Target Project Architecture
The agent must restrict all newly generated Dart files to the following specific folder structure inside the `lib/` directory. Do not generate flat files or alternative directory structures.

### 1. `lib/models/`
*   **Purpose:** Contains pure Dart data classes representing game states, player data, and power cards.
*   **Instruction:** Avoid mixing UI or database logic here. Focus on clear, object-oriented data properties and simple JSON serialization if needed.

### 2. `lib/screens/`
*   **Purpose:** Contains full-page layouts (e.g., Splash Screen, Game Board, Score Summary).
*   **Instruction:** These should primarily handle layout scaffolding and orchestrate child widgets.

### 3. `lib/widgets/`
*   **Purpose:** Contains reusable UI components (e.g., custom scorecards, individual buttons, hand gesture icons, power card buttons).
*   **Instruction:** Break complex UI trees into small, isolated stateless or stateful widgets. Keep them highly scannable and maintainable for easy interview dry-runs.

### 4. `lib/services/`
*   **Purpose:** Manages all external interactions (e.g., communication with Firebase Realtime Database, API calls to Groq AI for commentary).
*   **Instruction:** Isolate all backend asynchronously into these service classes so the UI remains completely independent of database implementation.

### 5. `assets/`
*   **Purpose:** Localized at the root level, containing static files, local JSON databases, and image configurations.

---

## Implementation Constraints
1.  **Readability First:** Favor explicit, clean layout code using standard Flutter widgets (`SizedBox`, `Spacer`, `Expanded`, `Column`, `Row`) over complex custom rendering.
2.  **Step-by-Step Execution:** Do not attempt to build the entire app at once. Focus on generating the structural models and static widgets first, then build up the stateful interaction layers.
3.  **No Extraneous Folders:** Adhere strictly to the five directories listed above. Do not create auxiliary architectural folders unless explicitly requested.