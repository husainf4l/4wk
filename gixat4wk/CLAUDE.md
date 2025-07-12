# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React Native 0.80.1 application written in TypeScript. It's a fresh project bootstrapped with `@react-native-community/cli` and follows standard React Native conventions.

## Development Commands

### Core Development
- `npm start` - Start the Metro bundler (JavaScript build tool)
- `npm run android` - Build and run on Android emulator/device
- `npm run ios` - Build and run on iOS simulator/device
- `npm test` - Run Jest tests
- `npm run lint` - Run ESLint for code quality checks

### iOS-specific Setup
iOS development requires CocoaPods dependency management:
- `bundle install` - Install Ruby bundler (first time only)
- `bundle exec pod install` - Install CocoaPods dependencies (run after cloning or updating native deps)

### Platform Build Commands
- Android: Can also build directly from Android Studio
- iOS: Can also build directly from Xcode

## Architecture

### Entry Points
- `index.js` - Main application entry point, registers the App component
- `App.tsx` - Root React component using `@react-native/new-app-screen` template

### Project Structure
- `android/` - Android native code and configuration
- `ios/` - iOS native code and configuration 
- `__tests__/` - Jest test files
- Root level contains React Native and React components

### Configuration Files
- `tsconfig.json` - Extends `@react-native/typescript-config`
- `babel.config.js` - Uses `@react-native/babel-preset`
- `.eslintrc.js` - Extends `@react-native` ESLint config
- `jest.config.js` - Uses `react-native` preset
- `metro.config.js` - Metro bundler configuration

### Development Environment
- Node.js >= 18 required
- Uses TypeScript 5.0.4
- Jest for testing with React Test Renderer
- ESLint for code quality
- Prettier 2.8.8 for code formatting

## Testing
The project uses Jest with the `react-native` preset. Tests use React Test Renderer for component testing. Run individual tests with Jest's standard patterns (e.g., `npm test -- App.test.tsx`).