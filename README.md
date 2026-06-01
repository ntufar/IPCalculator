IPCalculator
===========

[![Release](https://img.shields.io/github/v/release/ntufar/IPCalculator?style=flat-square)](https://github.com/ntufar/IPCalculator/releases)
[![Platform](https://img.shields.io/badge/platform-Android-3ddc84?style=flat-square&logo=android)](https://github.com/ntufar/IPCalculator)
[![Min SDK](https://img.shields.io/badge/minSdk-21-orange?style=flat-square)](https://github.com/ntufar/IPCalculator)
[![Target SDK](https://img.shields.io/badge/targetSdk-36-brightgreen?style=flat-square)](https://github.com/ntufar/IPCalculator)
[![Kotlin](https://img.shields.io/badge/kotlin-1.9.x-7f52ff?style=flat-square&logo=kotlin)](https://github.com/ntufar/IPCalculator)
[![License](https://img.shields.io/badge/license-BSD%202--Clause-blue?style=flat-square)](https://github.com/ntufar/IPCalculator)

IP subnet calculator for Android.

![IP Calculator screenshot](site/images/screenshot.png)

## Building

```bash
./gradlew assembleDebug
```

APK output: `app/build/outputs/apk/debug/app-debug.apk`

## Modernization

Migrated from Eclipse/ADT (API 11-17) to Gradle + Kotlin (API 21-36).

- Android Gradle Plugin 9.2.1
- Kotlin
- ViewBinding
- Material Components theme
- Min SDK 21, Target SDK 36, Compile SDK 36

## Website

The app landing page and privacy policy are in `site/` and deployed to GitHub Pages on every push via `.github/workflows/deploy-pages.yml`.

Visit: https://ntufar.github.io/IPCalculator/

