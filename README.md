# Parle — personal French speaking coach (iOS)

A personal, subscription‑free iOS app for French pronunciation practice. It's modelled
on the feature set of *Parle: Learn French & Speak*: you listen to a phrase, say it out loud,
and get instant word‑by‑word feedback.

It was written from scratch with SwiftUI, built only from the App Store listing's description
of what the app does. It contains no code, audio or artwork from the original app. There are
no paywalls, no accounts and no analytics, and your data stays on your device.

## Features

| | |
|---|---|
| **Speaking practice** | 14 units (~140 phrases) from greetings to idioms and tongue twisters, grouped A1 → B2+ |
| **Instant feedback** | On‑device French speech recognition. Each word is coloured green, orange or red, and you get a 0–100 score |
| **Listen & shadow** | Native‑speed and slow playback. Tap any word to hear it slowly |
| **Practice Zone** | 15 sound drills (French *u*, nasal vowels, R, liaison…) with mouth‑position steps, examples, minimal pairs and a listening quiz |
| **My phrases** | Add your own sentences (paste many at once, one per line) and practise them |
| **Review** | Automatically collects the phrases you scored under 80 |
| **AI tutor** | Spoken role‑play conversations (café, directions, hotel…) with corrections. Runs free on‑device with Apple Intelligence, or with your own Claude API key |
| **Level check** | An onboarding self‑assessment plus a 3‑phrase speaking test sets your path |
| **Progress › Overview** | Streak, average score, average gain from first try to best, this week vs last week, score and activity charts (14/30 days), a practice calendar, average by unit, best time of day, level progress, recent attempts |
| **Progress › Improve** | Coach's notes in plain language, the French sounds you mispronounce most (linked to their drills), the words you miss most (tap to hear them, practise them as a set), and phrases still under 80 |
| **Reminders** | Daily practice notification at a time you choose |

## Install it on your iPhone

You need a Mac with **Xcode 16 or later** (Xcode 26 enables the on‑device AI tutor) and a free
Apple ID.

```bash
brew install xcodegen      # one-time
git clone <this repo> && cd parlefrancais
xcodegen generate          # creates Parle.xcodeproj from project.yml
open Parle.xcodeproj
```

In Xcode:

1. Select the **Parle** target → *Signing & Capabilities* → choose your **Team** (your personal Apple ID works).
   If the bundle ID is taken, change `com.personal.parlefrancais` to something unique.
2. Plug in your iPhone, select it as the run destination, and press **⌘R**.
3. On the iPhone, trust the developer under *Settings › General › VPN & Device Management* the first time.

> With a free Apple ID, the app has to be re‑installed from Xcode every 7 days. With a paid
> developer account, it lasts a year.

**No Mac?** Each push runs the GitHub Actions workflow (`.github/workflows/build.yml`). It
uploads an **unsigned `.ipa`** artifact, which you can sign and install with a sideloading tool
such as Sideloadly or AltStore using your Apple ID.

## Tips for the best results

- **Better voice:** download an *Enhanced* or *Premium* French voice in iOS *Settings ›
  Accessibility › Spoken Content › Voices › French*, then pick it in Parle › Settings › Voice.
- **Offline recognition:** add French as a dictation language (*Settings › General › Keyboard ›
  Dictation Languages*). Parle then recognises speech fully on‑device.
- **AI tutor:**
  - On iOS 26 devices with Apple Intelligence turned on, it works out of the box, free and private.
  - Otherwise, paste a Claude API key from console.anthropic.com in *Settings › AI tutor*. You pay
    Anthropic per message; there's no subscription. The key is stored in the iOS Keychain.

## How scoring works

Speech recognition turns what you said into French words. Parle aligns those words with the
target phrase using fuzzy matching (Levenshtein distance, with accents folded and numbers spelled
out). Each word then gets a 0–1 score. A word the recogniser mis‑heard is almost always one you
mispronounced, so red words are the ones to work on. A phrase counts as **mastered** once you've
scored 80 or more on it.

## Project layout

```
project.yml                 XcodeGen spec (iOS 17+, iPhone & iPad)
Parle/App/                  App entry point and tab bar
Parle/Models/               SwiftData models (Attempt, CustomPhrase) and progress maths
Parle/Content/              Phrase units and sound lessons — add your own here
Parle/Services/             Speech recognition, TTS, scoring, AI tutor, reminders
Parle/Views/                SwiftUI screens
```

To add content, append a `LessonUnit` to `PhraseLibrary.units` or a `SoundLesson` to
`SoundLibrary.lessons`.
