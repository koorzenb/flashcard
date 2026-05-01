# FlashCard

App for practicing foreign language vocabulary.

## Getting Started

- install [fvm](https://fvm.app/documentation/getting-started/installation) and use the version in "./.vscode/settings.json"
- requires installation of [SED](https://gnuwin32.sourceforge.net/packages/sed.htm)
- run **build-prod-apk.bat** to build the apk file.

Releases

- Releases can be found in the [releases](./release/) folder

# Authentication

- The app uses Firebase Authentication for user sign-in and sign-out.
- Once signed in, Firebase maintains the user's authentication state, which is used to determine whether to show the sign-in screen or the home screen.
