# IRON NEBULA — fejlesztési áttekintés

Az Iron Nebula egy sci-fi, oldalnézetes arcade shooter három külön fejlesztési
változattal: Windows desktop, WebGL2 böngészős kiadás és kísérleti Godot-preview.
A változatok még nem teljesen paritásosak; a Web/Godot fejlesztési állapot és a
következő lépések az [AI handoff fájlban](AI_HANDOFF.md) követhetők.

## Jelenlegi fejlesztés

- A sérülés kezdetétől, a hajó textúrájának alfáját követő metallic frame jelenik
  meg; teljes javításnál eltűnik.
- A bossok támadás-, pajzs- és sebzésfázisokat váltanak. A pajzs blokkolja a
  találatokat, a sebzésfázis nagyobb sebzést enged.
- Co-opban a játékosszám enyhén növeli az ellenségek erejét. Öt-hat játékosnál
  az egészség- és pajzsfelvétel, valamint a kreditek egy további egységet adnak.
- A Web és Godot változat célzott automatikus ellenőrzései átmentek. A Windows
  desktop megfelelő funkciói és a kiadás még nincsenek befejezve.

## Fejlesztés és ellenőrzés

- Web: `cd Web`, `npm.cmd test`, `npm.cmd run build`,
  `npm.cmd run release:verify`.
- Godot: a projektgyökérbeli `RUN_GODOT_PREVIEW.bat`; célzott teszt:
  `Godot/tests/gameplay_checks.gd`.
- Windows: a desktop-release ág .NET 10-et céloz. Release-buildet és a
  platformparitást az átadási fájl állapotának megfelelően kell befejezni.

Az AI-k közötti folytatáshoz minden munkamenet elején olvasd el, a végén pedig
frissítsd az [AI_HANDOFF.md](AI_HANDOFF.md) fájlt. Felhasználó által
visszavont szerkesztést ne állíts vissza engedély nélkül.
