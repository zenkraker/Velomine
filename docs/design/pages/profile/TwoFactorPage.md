# TwoFactorPage

Two-factor sign-in: turn the authenticator on or off. Route `/profile/two-factor`, `features/profile/two_factor_screen.dart`.

- Off: the setup key and a code field. On: the state, New recovery codes, and Turn off. Both need the password. Single sign-on accounts already have a second step and see that instead.
