# GlassChat

**A private, offline chat studio for Android.** GlassChat lets you write conversations —
one-to-one or in groups — with people you invent, people you know, or characters you are
still figuring out. You author both sides of every thread. Nothing is transmitted, nothing
is uploaded, and the app does not even declare the `INTERNET` permission.

Built with Kotlin, Jetpack Compose (Material 3) and an original "liquid glass" design system:
frosted, layered surfaces, refraction highlights, drifting aurora backdrops and spring-driven
motion.

> **GlassChat is an independent project.** It is not affiliated with, endorsed by or connected
> to Apple, Google, Signal, Meta or any messaging provider. No third-party UI assets, icons,
> copy or brand marks are used, and the app makes no claims about interoperability with any
> other messaging service. Delivery ticks, typing dots and unread badges are clearly-labelled
> simulations for the conversations you write.

---

## 1. What you can do

### Chats
- A **Chats** home screen with avatars/initials, last-message preview, timestamp,
  unread badge, muted and pinned states.
- **Swipe right to pin**, **swipe left to archive**, long-press for a contextual sheet
  (pin, mute, archive, mark unread, delete with undo).
- Live **search** across titles and participants.
- Floating glass **bottom navigation**: Chats · Contacts · Media · Settings.

### Authoring conversations
- Create a **1:1 chat or a group**, with existing contacts or brand-new ones created inline
  (name, phone label, bio, notes, avatar colour or photo).
- **Chat templates** seed a natural-looking opening exchange, or start from a blank thread.
- A composer **sender switch** that always reads **“Me”** versus the other participant — with
  their accent colour, a tinted field border and a **“Message as …”** placeholder, so it is
  never ambiguous who you are writing as. In groups it opens a participant picker.
- Multiline composer, emoji picker, drafts saved per chat, reply-with-quote, edit, delete for
  me / for everyone, reaction chips, in-chat search, starred messages, timestamps, day
  separators and clearly-labelled simulated delivery states.
- Manual **“Simulate typing”** toggle per chat (never invented automatically).

### Media
- Attach photos (Android **Photo Picker**), videos, audio/voice notes, and documents (SAF).
- Every file is **copied into app-private storage**; the app keeps thumbnails, captions and
  per-file metadata.
- Full-screen viewer with **pinch-to-zoom**, swipe between a chat’s media, inline video,
  waveform audio playback, save-a-copy and delete.
- Aggregated **Media** tab grouped per conversation, filterable by photos / videos / audio /
  documents.
- Location and contact-card placeholders in the attachment sheet.

### Contacts & profile
- Contact CRUD with search, A–Z grouping, favourites, accent colours, avatars, notes.
- Contact detail: shared media, starred messages, chat appearance shortcut, hide/block and
  delete.
- **My profile**: display name, about, avatar, accent, plus quick access to backups.

### Appearance
- System / light / dark theme, accent palette, per-chat accent, bubble colours, wallpapers
  (including your own image), text-size scale, reduce transparency, reduce motion.
- Optional per-chat customisation: rename, wallpaper, accent, bubble colours, participants,
  archive, pin, mute, clear messages, delete.

### Privacy & data
- Optional **app lock** using biometrics or the device credential, hide previews in the
  recent-apps switcher, blur media thumbnails in lists.
- **ZIP backup export** (JSON manifest + every media file) and **import/merge**, cache
  clearing, and a guarded *delete everything* action.
- No accounts, no analytics, no ad IDs, no cloud backup (`allowBackup=false`).

### Accessibility & devices
- TalkBack labels on every icon-only control, 44–48 dp minimum touch targets, merged
  semantics for compound rows.
- System font scaling **plus** an in-app text scale; contrast-aware palette; reduce
  transparency and reduce motion switches.
- Responsive layout for small phones, large phones, foldables and tablets (≤600 dp uses the
  bottom bar and sheet-based navigation; wider windows get more breathing room).

---

## 2. Screens

| Screen | Purpose |
| --- | --- |
| Onboarding (3 steps) | Name, accent + theme, optional sample chats |
| Chats | List, search, swipe actions, archive badge, FAB |
| Chat | Timeline, composer with sender switch, in-chat search, starred filter, menus |
| Chat settings | Rename, wallpaper, accent, bubbles, participants, mute/pin/archive, data |
| New chat | Contact multi-select, inline contact creation, group naming, templates |
| Contacts | Search, favourites, A–Z list |
| Contact editor / Contact detail | CRUD, shared media, starred messages, hide/block |
| Media | Per-chat media grid with filters |
| Media viewer | Zoom, swipe, save, delete, video/audio/document rendering |
| Archived chats | Restore or permanently delete |
| Settings | Hub + Appearance, Chat behaviour, Privacy, Data & backups, About |
| My profile | Identity and accent used for “Me” |
| App lock | Biometric / device-credential gate |

---

## 3. Tech stack

| Area | Choice |
| --- | --- |
| Language | Kotlin 2.0.20 |
| UI | Jetpack Compose, Material 3, Compose Animation (shared elements) |
| Architecture | MVVM + unidirectional state, `StateFlow`, coroutines |
| DI | Hilt 2.52 |
| Persistence | Room 2.6.1 (chats, participants, messages, attachments, reactions, settings) |
| Preferences | DataStore Preferences |
| Media | App-private storage + `FileProvider`, Coil (incl. video frames), platform `VideoView`, `MediaRecorder`/`MediaPlayer` |
| Backup | `kotlinx.serialization` JSON inside a ZIP |
| Auth | `androidx.biometric` |
| Build | AGP 8.6.1, Gradle 8.9, compileSdk 35, targetSdk 35, minSdk 26 |

### Layers

```
ui/            Compose screens, glass components, navigation, ViewModels
domain/        Models, repository contracts, use cases (CreateChatUseCase)
data/          Room (entities, DAOs), DataStore, mappers, repository impls,
               media storage, backup (ZIP + JSON)
di/            Hilt modules
util/          Ids, formatters, time formatting
```

Data flow: `Room/DataStore → Repository → Flow → ViewModel (StateFlow) → Compose`. UI events
go the other way as plain callbacks; one-shot messages travel through a `Channel<UiEvent>`.

### Repository contracts (abridged)

- `ChatRepository`: observe summaries/detail/archived count, create, rename, pin, mute,
  archive, soft delete, permanent delete, appearance, drafts, participants, read state.
- `MessageRepository`: observe timeline/starred/unread, in-chat search, send, edit, delete
  for me/everyone, star, react, simulated status progression, clear chat.
- `MediaRepository`: observe media, import from URI, camera capture, recording, export,
  delete, cache size/clear, orphan pruning.
- `ContactRepository`, `SettingsRepository`, `BackupRepository`.

---

## 4. Requirements

- **JDK 17** (AGP 8.6 requires it; Android Studio’s bundled JBR works).
- **Android SDK Platform 35** and **Build-Tools 35.x** installed.
- Android Studio Ladybug (2024.2.1) or newer — or a command-line SDK with `ANDROID_HOME`.
- A device or emulator running **Android 8.0 (API 26)** or newer.

---

## 5. Build

```bash
# 1. Point Gradle at your SDK (or export ANDROID_HOME / ANDROID_SDK_ROOT instead)
cp local.properties.sample local.properties
$EDITOR local.properties        # sdk.dir=/path/to/Android/Sdk

# 2. Debug build
./gradlew assembleDebug

# 3. Output
#    app/build/outputs/apk/debug/app-debug.apk
```

Release:

```bash
./gradlew assembleRelease
# app/build/outputs/apk/release/app-release.apk
# (falls back to debug signing when keystore.properties is absent — installable, not
#  suitable for store upload)
```

App bundle:

```bash
./gradlew bundleRelease
# app/build/outputs/bundle/release/app-release.aab
```

Useful variants: `./gradlew clean`, `./gradlew lint`, `./gradlew test`,
`./gradlew connectedDebugAndroidTest`.

> The debug build uses the application id `com.glasschat.app.debug`, so a debug and a release
> install can coexist on one device.

---

## 6. Signing

Create a keystore once:

```bash
keytool -genkeypair -v \
  -keystore glasschat-release.jks \
  -alias glasschat \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass 'CHANGE_ME' -keypass 'CHANGE_ME' \
  -dname "CN=GlassChat, OU=Personal, O=GlassChat, L=Ludhiana, S=Punjab, C=IN"
```

Create `keystore.properties` in the repository root (never commit it):

```properties
storeFile=/absolute/path/to/glasschat-release.jks
storePassword=CHANGE_ME
keyAlias=glasschat
keyPassword=CHANGE_ME
```

Then `./gradlew assembleRelease` produces a properly signed APK. Verify it:

```bash
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs \
  app/build/outputs/apk/release/app-release.apk
```

Without `keystore.properties` the release variant is signed with the debug key so the
project always yields an installable artifact. The script and property file are already
listed in `.gitignore`.

---

## 7. Install

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

If several devices are attached:

```bash
adb devices
adb -s <serial> install -r app/build/outputs/apk/debug/app-debug.apk
```

Uninstall (removes the private database and media):

```bash
adb uninstall com.glasschat.app.debug   # debug build
adb uninstall com.glasschat.app         # release build
```

First run: onboarding → pick a name and accent → optionally start with sample chats →
create a contact → “New chat” → choose the contact → write as **Me**, then flip the sender
switch to answer as them.

### Prebuilt APK

No APK is committed to this repository — the build environment used to author the source
had no JDK/Android SDK, so the artifact could not be produced here. Running the two commands
in section 5 on any machine with JDK 17 + SDK 35 produces exactly:

```
app/build/outputs/apk/debug/app-debug.apk
app/build/outputs/apk/release/app-release.apk
```

---

## 8. Tests

Unit tests (`app/src/test`):

```bash
./gradlew testDebugUnitTest
```

- `FormattersTest` — byte/duration/initial/file-name formatting.
- `TimeFormatTest` — chat-list stamps, day separators, day keys.
- `MappersTest` — entity ⇄ domain round trips, null overrides, drafts.
- `BackupBundleTest` — JSON round trip and forward-compatible unknown keys.
- `CreateChatUseCaseTest` — contact creation, participant de-duplication, title fallbacks,
  template seeding timestamps and unread state (uses in-memory fakes).

Instrumented tests (`app/src/androidTest`, needs a device/emulator):

```bash
./gradlew connectedDebugAndroidTest
```

- `GlassChatFlowTest` — create a contact through the editor, create a chat, send as **Me**,
  switch the sender to the contact and reply, open the attachment chooser, search the chat
  list.
- `BackupInstrumentedTest` — export a real ZIP (asserts `backup.json` and the stamped backup
  time), wipe the database, then import and verify contacts return.

Both suites use Hilt (`HiltTestRunner`) with the real Room database, so they exercise the
production wiring rather than mocks.

---

## 9. What GlassChat deliberately does not do

- **No networking.** No `INTERNET` permission, no sockets, no uploads. Nothing leaves the
  device.
- **No account system, no contact syncing.** Contacts are local records, not address-book
  entries.
- **No fake realism.** Simulated delivery/read ticks, unread badges and typing dots are
  labelled as simulations wherever they appear.
- **No cloud backup.** `allowBackup=false`; use the ZIP export instead.
- **No real phone calls.** The phone label on a contact is descriptive text only.
- **Media is not magically recovered.** Deleting a chat deletes its private copies.

---

## 10. Backups

`Export everything` writes a ZIP to a location you choose:

```
backup.json          # manifest: preferences, contacts, chats, participants,
                     # messages, attachments, reactions, settings
media/…              # the private copies of every attached file
```

`Import a backup` merges by id — existing rows are kept, missing ones are restored, so
importing the same file twice is harmless. Backups are **not encrypted**; store them
somewhere you trust.

---

## 11. Troubleshooting

| Symptom | Fix |
| --- | --- |
| `SDK location not found` | Create `local.properties` with `sdk.dir=…` or export `ANDROID_HOME`. |
| `Unsupported class file major version` / Kotlin daemon JDK error | Use JDK 17: `./gradlew -Dorg.gradle.java.home=$JAVA_HOME_17 assembleDebug`. |
| `compileDebugKotlin` fails after changing Room entities | Room schema output lives in `app/schemas`; run `./gradlew clean assembleDebug`. |
| Voice notes do nothing | Grant the microphone permission when prompted; it is the only runtime permission. |
| Photo picker shows nothing | The device needs a gallery provider; on emulators add images via Files. |
| App lock prompt never appears | Add a fingerprint/face/PIN in system settings; the Privacy screen explains this. |
| Large APK size | Release builds shrink resources; the debug build ships the full Material icon set for convenience. |

---

## 12. Project layout

```
.
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/com/glasschat/app/
│       │   │   ├── MainActivity.kt, GlassChatApplication.kt
│       │   │   ├── data/{local/{db,datastore,media},mapper,repository,backup}
│       │   │   ├── di/, domain/{model,repository,usecase}, util/
│       │   │   └── ui/{theme,glass,components,common,navigation,features/*}
│       │   └── res/{values,values-night,xml,drawable,mipmap-*}
│       ├── test/java/com/glasschat/app/…        # JVM unit tests
│       └── androidTest/java/com/glasschat/app/… # instrumented UI/repo tests
├── gradle/wrapper/…
├── build.gradle.kts, settings.gradle.kts, gradle.properties
├── local.properties.sample
└── README.md
```

---

## 13. Design notes

The visual language is original: layered translucent panels with a highlight ring, a soft
inner shadow, and a blurred aurora backdrop whose palettes are defined in code
(`Wallpapers.palette`). Accent colours are semantic tokens — nothing is hardcoded per screen,
so per-chat and app-wide accents, dark mode and reduce-transparency all stay consistent.

Motion is spring-based and respects both the in-app *reduce motion* switch and the system
animator scale; shared-element transitions carry an avatar from the chat list into the header.

---

## 14. License

Source is provided for personal use and study. Bundled third-party libraries keep their own
licenses (Apache 2.0 unless noted); see Settings → About for the list. Emoji glyphs are
rendered by the device font — no emoji artwork ships with the app.
