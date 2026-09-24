# БЛЕФ / BLEF — 0.1

## Русский

**БЛЕФ** — настольная игра о переговорах и обмене кейсами для **3–8 игроков** в одной локальной сети. Каждый видит содержимое только своего текущего кейса и решает, говорить правду или блефовать. В свой ход можно оставить кейс или обменяться им с другим участником. После последнего круга кейсы вскрываются, игроки получают очки и предметы в коллекцию.

### Скачать и запустить

На Windows нажмите **Code → Download ZIP**, распакуйте архив и запустите [`build/Играть.cmd`](build/Играть.cmd). Скрипт один раз извлечёт `BLEF.exe` из `BLEF-engine.zip`; `BLEF.pck` уже находится рядом. Установка Godot не нужна. Подробнее: [инструкция к сборке](build/README.md).

### Начать матч

1. На одном компьютере выберите **Создать лобби**.
2. На остальных откройте **Найти лобби** и подключитесь к комнате в той же локальной сети.
3. Все нажимают **Готов**, затем хост запускает матч.
4. Откройте свой кейс клавишей **E**, обсуждайте предметы и подтверждайте готовность. В свой ход оставьте кейс или обменяйтесь с другим игроком.

Для поиска нужны локальные UDP-порты **42043–42044**, для игры — **42042**. Если Windows спросит, разрешите приложению доступ в частных сетях. Все игроки должны использовать одну версию.

| Действие | Клавиша |
|---|---|
| Открыть / закрыть кейс | E |
| Колесо эмоций | T; выбор мышью или 1–6 |
| Осмотреться | Удерживать правую кнопку мыши |
| Меню матча | Esc |

### Исходный проект

Откройте `project.godot` в **Godot 4.6.2** и запустите проект клавишей F5. Windows-сборка создаётся командой `powershell -ExecutionPolicy Bypass -File tools/build.ps1` из корня проекта. После сборки `BLEF.exe` и `BLEF.pck` находятся в `build/`; для GitHub исполняемый файл также упакован в `BLEF-engine.zip`, чтобы каждый файл был меньше лимита GitHub.

Авторы и источники ассетов указаны в [CREDITS.md](CREDITS.md) и [ASSET_LICENSES.md](ASSET_LICENSES.md). У двух бесплатных офисных паков условия распространения не подтверждены; это отмечено в CREDITS. Лицензия на весь проект этим документом не предоставляется.

---

## English

**BLEF** is a case-trading and negotiation game for **3–8 players** on the same local network. You can see only the item in your current case, so you may tell the truth or bluff. On your turn, keep your case or trade it with another player. After the final round, the cases are revealed and players earn points and collection items. **The game UI is in Russian.**

### Download and play

On Windows, choose **Code → Download ZIP**, extract it, and run [`build/Играть.cmd`](build/Играть.cmd). The launcher extracts `BLEF.exe` from `BLEF-engine.zip` on first run; `BLEF.pck` is already alongside it. Godot is not required. See the [build instructions](build/README.md).

### Start a match

1. One player creates a lobby.
2. The others find it on the same LAN and join.
3. Everyone marks themselves ready; the host starts the match.
4. Press **E** to inspect your case, negotiate, then choose to keep or trade it on your turn.

LAN discovery uses UDP ports **42043–42044**; the game uses **42042**. Allow private-network access if Windows asks. All players need the same game version.

| Action | Key |
|---|---|
| Open / close your case | E |
| Emotion wheel | T; choose with mouse or 1–6 |
| Look around | Hold right mouse button |
| Match menu | Esc |

### Source project

Open `project.godot` in **Godot 4.6.2** and press F5. To rebuild on Windows, run `powershell -ExecutionPolicy Bypass -File tools/build.ps1` from the project root. The playable files `BLEF.exe` and `BLEF.pck` will be in `build/`; the executable is also compressed as `BLEF-engine.zip` to stay below GitHub's per-file limit.

Asset creators and sources are listed in [CREDITS.md](CREDITS.md) and [ASSET_LICENSES.md](ASSET_LICENSES.md). Redistribution terms for two free office asset packs remain unverified, as noted in CREDITS. This README does not grant a license to the whole project.
