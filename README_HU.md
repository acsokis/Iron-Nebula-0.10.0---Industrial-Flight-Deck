# IRON NEBULA — Windows desktop Alpha 0.9.12

A Windows kiadás C# / .NET 10 / MonoGame WindowsDX alapú. A projekt három szektort,
öt primary fegyvert, mentést, shopot, kontrollerkezelést és 2–6 fős Online/LAN
kooperatív módot tartalmaz.

## Fordítás és publikálás

- Forrásfordítás: `BUILD_WINDOWS.bat`.
- Self-contained Windows x64 kiadás egyetlen ZIP-letöltésként:
  `PUBLISH_WINDOWS.bat`.
- Kimenet: `dist/IronNebula-win-x64.zip`; kicsomagolás után az
  `IronNebula.exe` és az `Assets/` mappa együtt szükséges.
- A publikálás ellenőrzi a kötelező artwork- és hangfájlokat, és nem indítja el
  automatikusan a játékot.
- Az eredeti fejlesztő megerősítette a `Propulsive Peak` terjesztési engedélyét;
  az MP3 és a streamelt WAV is része a Windows kiadásnak.

## Indítás
Windows: `BUILD_WINDOWS.bat`. .NET 10 SDK szükséges.

## Automatizált ellenőrzések

```powershell
dotnet build IronNebula.csproj -c Release
dotnet run --project Tools/ControllerChecks/ControllerChecks.csproj -c Release
dotnet run --project Tools/CoopChecks/CoopChecks.csproj -c Release
dotnet run --project Tools/VisualChecks/VisualChecks.csproj -c Release
```

Ezek a tesztek nem helyettesítik a fizikai kontrolleres, tiszta gépes vagy teljes
kampánytesztet. A kooperatív teszt valós loopback TCP klienseket használ; internetes
NAT-viselkedést nem igazol.
