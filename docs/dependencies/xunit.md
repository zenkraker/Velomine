# xUnit.net v3 (xunit.v3 4.0.2)

Checked 2026-11-02 from [NuGet](https://www.nuget.org/packages/xunit.v3), [xunit.net](https://xunit.net/) and the [GitHub repo](https://github.com/xunit/xunit). *Unverified* items were not confirmed.

## Need
Unit and integration test framework for the server. The official alternative is MSTest (Microsoft); the owner chose xUnit.

## Alternatives considered
- **MSTest 4.x** (Microsoft, official): used for the first tests; works with `WebApplicationFactory`. No approval needed.
- **NUnit:** community, no advantage here.

## Licence
Apache-2.0. A test-only dependency; it does not ship in the server image.

## Maintenance
- Latest stable 4.0.2 (2026-10-09); 4.0.1 (2026-09-12), 4.0.0 (2026-08-15). Frequent releases.
- Part of the .NET Foundation; led by Brad Wilson, who signs the releases. 4.6k stars, 16 open issues, 1 open PR.
- v2 is in maintenance mode; all new work is v3.
- 63.4M downloads.

## Security
- Known advisories: none shown on NuGet; the GitHub advisory tab was not checked.
- Dependencies: `xunit.v3` → `xunit.v3.mtp-v2` and its xunit.v3 sub-packages (same project). No outside packages.

## Platform support
- .NET: "xUnit.net v3 supports .NET 8.0 or later"; the package declares net8.0 and net472, and .NET 10 uses the net8.0 asset. Verified here: builds and runs on .NET 10.0.403.
- Test projects are stand-alone executables (`<OutputType>Exe</OutputType>`).
- On the .NET 10 SDK, `dotnet test` with xUnit v3 needs the Microsoft Testing Platform runner, set in `global.json` (`"test": {"runner": "Microsoft.Testing.Platform"}`) and run as `dotnet test --solution Velomine.slnx`. The old VSTest packages (`xunit.runner.visualstudio`, `Microsoft.NET.Test.Sdk`) are not used. IDEs need Microsoft Testing Platform support to list and run the tests.
- Works with `Microsoft.AspNetCore.Mvc.Testing` (`WebApplicationFactory<Program>` as a class fixture): verified by the server tests.

## Size and performance
Test-only.

## Risk and exit plan
- Risk: low. The v3 line is new (first 4.0 release in August 2026); minor API changes between majors.
- Exit: tests are plain `[Fact]` methods with class fixtures; moving to MSTest is mechanical.

## Recommendation
Approved by the owner on 2026-11-02. Pin 4.0.x; `xunit.v3` only.
