# Источники окружения

## Кейс и аксессуары

Дополнительные модели, авторы, лицензии и изменения перечислены в [ASSET_LICENSES.md](ASSET_LICENSES.md).

Money Case Animation by [zulaldeveli](https://sketchfab.com/zulaldeveli), [source](https://sketchfab.com/3d-models/money-case-animation-1d0f2b45f5aa480daeef0cb61c6da79d), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Original geometry and animation retained; game scale and material parameters adjusted.

## Лица персонажей

10 прозрачных PNG-лиц предоставлены пользователем проекта и скопированы без изменения в `assets/character/faces/`. Файлы используются только как локальные игровые текстуры; соответствие исходников и SHA-256 указано в `docs/face_sources.json`.

## Карточки предметов

41 изображения лицевых сторон и изображение общей оборотной стороны предоставлены пользователем проекта и скопированы в `assets/cards/` без художественного редактирования. Исходники в `Визуальный стиль/карточки` остаются нетронутыми. Внешний светлый фон у лицевых изображений маскируется игровым шейдером `scripts/visual/card_surface.gdshader`; отдельный файл `scripts/ui/card_preview.gdshader` применяет ту же маску к превью коллекции.

Сцена переговорной «БЛЕФ», версия 0.4.0, 17 сентября 2026.

| Автор / пакет | Использование | Условия в скачанном пакете |
|---|---|---|
| [nappin — Office Props Softpack](https://nappin.itch.io/office-props-softpack) | Основные тумбы, кофейный модуль с полками, растения, подвесные лампы, книги, кофейник и кружки | Отдельная лицензия не указана на странице и не найдена в бесплатном Unity-пакете |
| [RRFreelance — Low Poly Office Props](https://rrfreelance.itch.io/low-poly-office-props) | Зелёное офисное кресло Chair_Office_Green | Отдельная лицензия не указана на странице и не найдена в FBX-архиве |
| [Kenney — Furniture Kit](https://kenney.nl/assets/furniture-kit) | Диван, подушки, журнальный стол, кофемашина | CC0 1.0; оригинальный License.txt сохранён |
| [Kenney — Food Kit](https://kenney.nl/assets/food-kit) | Фрукты, круассан, миска и тарелка | CC0 1.0; оригинальный License.txt сохранён |
| [Kenney — Cube Pets](https://kenney.nl/assets/cube-pets) | Три небольшие игрушки: кот, панда, пингвин | CC0 1.0; оригинальный License.txt сохранён |

Для nappin и RRFreelance отдельные условия распространения не были найдены в скачанных пакетах. Никаких лицензий этим моделям от имени авторов не присвоено.

FBX преобразованы в GLB встроенным импортёром Godot 4.6.2. Blender не использовался на этом этапе. Точки привязки приведены к центру основания; ориентация и размеры согласованы в сцене. Материалы мебели заменены общей палитрой Godot; атлас кресла уменьшен до 512×512. Для еды и игрушек сохранены исходные цветовые атласы.

Существующие игровые стол, кейсы, персонажи и механика сохранены. Геометрия оболочки комнаты, коллизии и шейдеры пола, дерева и контактного затемнения добавлены в проекте.

Godot Engine — MIT. Тексты лицензии и уведомлений движка находятся рядом со сборкой.

## Новый кейс и аксессуары — 0.8.0

Money Case Animation — zulaldeveli (CC BY 4.0). Pixel Glasses — iPoly3D (CC0); Sunglasses, Heart Glasses, Cap, Mask — J-Toastie (CC BY 3.0); Low-poly Beanie — Iggy3D (CC BY 4.0); Hard Hat и Wizard Hat — Poly by Google (CC BY 3.0); Crown — Quaternius (CC0); Hat Stylised — hat_my_guy (CC0).

Ссылки на оригинальные модели, полные названия лицензий и сведения об адаптации: [ASSET_LICENSES.md](ASSET_LICENSES.md).
