# Iron Nebula — kiadás előtti tesztlista

Ez a lista a Web, Windows desktop és Godot változat külön ellenőrzésére szolgál.
Az automatizált PASS nem helyettesíti a fizikai hardveres és teljes játékmeneti
teszteket. Az aktuális ágak és ismert blokkolók: [AI handoff](AI_HANDOFF.md).

## Web

- [ ] `cd Web; npm.cmd test` — szimuláció, bossfázisok, party-skálázás és protokoll.
- [ ] Playwright `damage.spec.js` — sérülésnél frame, javításnál eltűnik.
- [ ] Playwright hat böngészős P2P-teszt — mozgás, lövések, ready állapot, szektorváltás.
- [ ] Telefonos vezérlés, kontrollerhint, loading retry és WebGL2 smoke.
- [ ] `npm.cmd run build` és `npm.cmd run release:verify`.
- [ ] Fizikai telefon, gamepad, HDR-kijelző és többgépes Internet/NAT-próba.

## Windows desktop (.NET 10 release ág)

- [ ] Tisztán restaurálható .NET 10 Release build.
- [ ] Controller- és co-op loopback-checkek, majd host plusz öt kliens smoke.
- [ ] Metallic hull-frame láthatósága sérülés/javítás alatt.
- [ ] Boss attack/shield/damage fázis, mindkét fegyversebzés útvonal és pickuphozam.
- [ ] Easy/Normal/Hard nehézség és 1–6 játékos összehasonlítása.
- [ ] Témázott ablak, induló loading UI, hangok és mentés.
- [ ] Release ZIP indítása tiszta gépen; csak szükséges futtatási fájlok legyenek benne.

## Godot preview

- [ ] Projektgyökérbeli `RUN_GODOT_PREVIEW.bat` editor és preview módban.
- [ ] Betöltőképernyő, textúra alfájához igazodó sérülési frame, majd javítás.
- [ ] Boss attack/shield/damage ciklus és pajzs/sebzés ablak.
- [ ] `Godot/tests/gameplay_checks.gd` PASS.
- [ ] `--party-size=1..6` értékekkel ellenség- és pickup-skálázás.
- [ ] NVIDIA path-tracing és raster fallback, valós GPU-n.
- [ ] Kiadási ZIP launch; editor, cache és engine-forrás nem kerül az assetbe.

## Összesített kiadási feltételek

- [ ] A három változatban a kért játékmenet-paritás igazolt.
- [ ] Minden kapcsolódó Markdown, changelog és [AI_HANDOFF.md](AI_HANDOFF.md) aktuális.
- [ ] A release csomagok és ellenőrzési jegyzőkönyvek elkészültek.
- [ ] Commit/push és GitHub Release csak a fenti tesztek után.
