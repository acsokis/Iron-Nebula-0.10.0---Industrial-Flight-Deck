# Iron Nebula

Az Iron Nebula önálló, sci-fi arcade játékprojekt három különálló változattal:
Windows, böngésző és Godot. A változatok fejlesztési területe és ellenőrzött
funkciói eltérnek; a teljes platformparitás még nem igazolt.

## Platformok

- **Windows:** .NET 10-alapú MonoGame asztali játék kampánnyal,
  kontrollerkezeléssel és sérülésre reagáló hajómegjelenítéssel, valamint
  továbbfejlesztett harci megjelenítéssel. A kiadási ellenőrzés állapotát az
  [AI-átadás](AI_HANDOFF.md) rögzíti.
- **Böngésző:** WebGL 2 megjelenítés, egyjátékos mód, választható online co-op
  és telefonos vezérlés. Részletek a [webes útmutatóban](Web/README.md).
- **Godot:** helyi 2.5D Pro-Arcade grafikai és fizikai preview harci HUD-dal,
  hangsávval, procedurális 3D bolygóháttérrel és rombolható űrobjektumokkal.
  Nem váltja ki a teljes Windows- vagy böngészős játékot. Lásd a
  [Godot-útmutatót](Godot/README.md).

A közös vizuális irány az eredeti szektorgrafikára, olvasható harci effektekre
és sérülésre reagáló hajómegjelenítésre épül. A Godot-preview többrétegű
hátteret, ipari stílusú repülési menüt és fizikailag sérülő űrobjektumokat kap.
Ez nem jelent automatikus funkcióparitást a platformok között.

## Fejlesztés

- Windows-fordítás: a .NET 10 SDK és a Windows build-eszközök szükségesek; a
  `BUILD_WINDOWS.bat` fordít, a `PUBLISH_WINDOWS.bat` pedig kompakt kiadási
  ZIP-et készít.
- Böngésző: lásd a [Web útmutatót](Web/README.md).
- Godot: a gyökérbeli `RUN_GODOT_PREVIEW.bat` indítja a helyi preview-t.

## Projektállapot és dokumentáció

- [AI-átadás és ellenőrzött állapot](AI_HANDOFF.md)
- [Kiadási ütemterv](ROADMAP.md)
- [Projektfrissítések](CHANGELOG.md)
- [Kiadás előtti ellenőrzőlista](TEST_CHECKLIST_HU.md)
- [Kontroller-útmutató](CONTROLLER_SUPPORT.md)
- [Co-op-útmutató](COOP_SUPPORT.md)

A Windows-, böngésző- és Godot-változat külön mentést és hálózati állapotot
használ; az adatok nem vihetők át automatikusan. A szükséges külső
licenc- és attribúciós tájékoztatók a kapcsolódó projektfájlok mellett maradnak.
