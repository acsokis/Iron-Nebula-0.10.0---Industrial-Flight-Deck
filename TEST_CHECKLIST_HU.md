# Kiadás előtti ellenőrzőlista

Az automatizált PASS nem helyettesíti a fizikai hardveres, hálózati és teljes
játékmeneti ellenőrzést. Az ágankénti állapotot az [AI-átadás](AI_HANDOFF.md)
rögzíti.

## Böngésző

- [ ] `cd Web; npm.cmd test`
- [ ] `npm.cmd run build` és `npm.cmd run release:verify`
- [ ] A böngészős smoke és a hat résztvevős co-op regressziós teszt sikeres
- [ ] Fizikai telefon, kontroller, HDR-kijelző és többgépes hálózat ellenőrizve

## Windows desktop

- [ ] Tisztán restaurálható Release build, figyelmeztetés és fordítási hiba nélkül
- [ ] Kontroller- és co-op-ellenőrzések a jelenlegi desktop forráson
- [ ] Sérülés és javítás visszajelzése, valamint ko-op jutalmazás ellenőrizve
- [ ] Témázott ablak, induló betöltőfelület, hang és mentés ellenőrizve
- [ ] Kiadási csomag tiszta Windows-környezetben elindul

## Godot preview

- [ ] Projektgyökérbeli `RUN_GODOT_PREVIEW.bat` preview és editor módban
- [ ] Betöltőképernyő és ipari repülési menü ellenőrizve
- [ ] Többrétegű háttér, szektorváltás és eredeti díszítőgrafika ellenőrizve
- [ ] Pro-Arcade HUD, score-attack újraindítás, hangsáv és térbeli effektek ellenőrizve
- [ ] Procedurális bolygótextúrák, FSR térbeli skálázás és bossfázisok ellenőrizve
- [ ] Hajó frame-je a sérüléskor megjelenik, javításkor eltűnik
- [ ] Lövés eltávolít voxelcellákat, és fizikai törmelék keletkezik
- [ ] `Godot/tests/gameplay_checks.gd` és `Godot/tests/smoke.gd` sikeres
- [ ] RTX és raszteres megjelenítés ellenőrizve támogatott GPU-n
- [ ] Kiadási ZIP tiszta környezetben indul; editor és cache nem kerül bele

## Közös kiadási feltételek

- [ ] A platformonkénti funkciók és korlátozások dokumentáltak
- [ ] Licenc- és biztonsági felülvizsgálat lezárult
- [ ] Minden csomag és checksum ellenőrzött
- [ ] Commit, push és kiadás csak sikeres elfogadási ellenőrzés után
