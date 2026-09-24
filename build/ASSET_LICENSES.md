# Добавленные модели: источники и лицензии

## Money Case Animation

- Автор: [zulaldeveli](https://sketchfab.com/zulaldeveli).
- Источник: [Money Case Animation](https://sketchfab.com/3d-models/money-case-animation-1d0f2b45f5aa480daeef0cb61c6da79d).
- Лицензия: [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
- Проверено на странице автора и в штатном окне загрузки Sketchfab 23 сентября 2026.
- Исходник без изменений: `assets/models/money_case/source/money_case_animation.glb` (официальная GLB-конверсия Sketchfab, текстура 1K).
- Runtime: `assets/models/money_case/imported/money_case.glb`.
- Изменения в игровой wrapper-сцене: равномерный масштаб 0.42; смещение Y −0.083; roughness 0.48, metallic 0.38. Геометрия, UV и исходные animation tracks сохранены.
- AnimationPlayer: `ImportedCaseModel/AnimationPlayer`; библиотека с пустым именем; `OpeningBaked`, 1.32 секунды. Закрытие: обратное проигрывание.
- Деньги: **KEPT**. Единственный mesh `Case_MoneyCaseColorPalette_0`, деньги имеют собственную анимированную кость `Money_06`, но не отдельный mesh. Удаление потребовало бы редактирования общей skinned-геометрии.

Другие источники окружения, пользовательских изображений и Godot перечислены в [CREDITS.md](CREDITS.md).

## Аксессуары персонажей — 23 сентября 2026

Лицензия каждого ассета проверена по ссылке на его странице. Исходные GLB сохранены без изменения геометрии; отдельные `accessory.tscn` нормализуют масштаб, ориентацию и начало координат. Игровая посадка задаётся в `data/cosmetics/catalog.json`. В игре материалы получают освещение и roughness 0.40 (очки) / 0.72 (остальное), metallic ограничен 0.25. Шапка скачана пользователем в официальном GLB с текстурами 1K.

| ID | Asset / Source | Author | License | Runtime folder |
|---|---|---|---|---|
| `pixel` | [Pixel Glasses](https://poly.pizza/m/VQuqLwtyTa) | iPoly3D | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `assets/characters/accessories/eyes/pixel_glasses/` |
| `sunglasses` | [Sunglasses](https://poly.pizza/m/jfVp7cW8E5) | J-Toastie | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/characters/accessories/eyes/sunglasses/` |
| `heart_glasses` | [Heart Glasses](https://poly.pizza/m/6B6ijFF01X) | J-Toastie | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/characters/accessories/eyes/heart_glasses/` |
| `cap` | [Cap](https://poly.pizza/m/aWxhfEnYwl) | J-Toastie | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/characters/accessories/head/cap/` |
| `beanie` | [Low-poly Beanie](https://sketchfab.com/3d-models/low-poly-beanie-f1d328dc5d49429e8b381ca3c38a25c4) | Iggy3D | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | `assets/characters/accessories/head/beanie/` |
| `hardhat` | [Hard Hat](https://poly.pizza/m/9AMKar2NlkX) | Poly by Google | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/characters/accessories/head/hard_hat/` |
| `crown` | [Crown](https://poly.pizza/m/i0PZVuVlYv) | Quaternius | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `assets/characters/accessories/head/crown/` |
| `wizard` | [Wizard Hat](https://poly.pizza/m/7VVumyY7L_u) | Poly by Google | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/characters/accessories/head/wizard_hat/` |
| `stylised_hat` | [Hat Stylised](https://poly.pizza/m/lNN3PlrjSa) | hat_my_guy | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `assets/characters/accessories/head/stylised_hat/` |
| `mask` | [Mask](https://poly.pizza/m/RqJn2J53Sd) | J-Toastie | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/characters/accessories/face/mask/` |

Во всех папках находятся `model.glb` и `accessory.tscn`. Авторы оригиналов указаны выше; адаптация посадки и освещения выполнена для БЛЕФ. Crown используется только как аксессуар головы. Четыре ранее созданных аксессуара (round, hamster, 3d, incognito) сохранены.
