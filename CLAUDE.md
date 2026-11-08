@AGENTS.md

## Test naming

Every test name follows `Subject_ShouldDoSomething_WhenCondition`: three PascalCase parts separated by underscores, naming the method, class, screen or controller under test, the observable behaviour, and the condition that triggers it. This applies to xUnit test methods and to the description strings of Dart `test(...)` and `testWidgets(...)`; group labels stay descriptive prose.

Examples: `NormalizedPower_ShouldReturnThatPower_WhenPowerIsSteady`, `SignInScreen_ShouldExplainWrongPassword_WhenSignInFails`, `MapView_ShouldZoomInMoreForShortRoutes_WhenFittingTheRoute`.
