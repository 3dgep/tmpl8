# BRIEF INFO ON THE 2026 TEMPLATE

Template, BUAS version https://www.buas.nl/games
IGAD/BUAS(NHTV)/UU - Jacco Bikker - 2006-2020
CMGT/BUAS - Jeremiah van Oosten - 2021-2026

## Purpose

The template has been designed to make it easy to start coding C++
using games and graphics. It intends to offer the programmer a
simple library with the main purpose of providing a 32-bit graphical
window with a linear frame buffer. Some basic additional functionality
is available, such as sprites, bitmap fonts, and vector math support.

## How to use

1. Download the template as a zip file (the green **Code** button on GitHub,
   then **Download ZIP**) and extract it to a fresh folder for your project.
2. Double-click `tmpl8.slnx` to open it in Visual Studio 2026.
3. Press **F5** (or the green **Local Windows Debugger** button) to build and run it.
4. Replace the example code in `game.cpp` with your own code.

Press **Alt+Enter** or **F11** to switch between fullscreen and a window (in a web build too), and **Escape**
to quit (in a browser, Escape leaves fullscreen). To start in fullscreen, set `StartFullscreen` to `true` in
`template.hpp`; your game can also call `ToggleFullscreen()`, `SetFullscreen( bool )` and `IsFullscreen()`.

The game waits for the screen before it shows the next frame (VSync), so it runs at the refresh rate of your screen
(e.g. 60 frames per second). To draw as many frames as your computer can, set `StartVSync` to `false` in
`template.hpp`, or call `SetVSync( false )` or `ToggleVSync()` from your game; `IsVSync()` tells you whether it's on.
(In a browser, the browser always waits for the screen.)

Everything the template needs is included: you don't need to install or
download anything else.

## Sharing your game

Double-click `package.bat`. It builds the Release version and packs your game in a zip file,
`build\<name of your game>.zip`, and shows it in Explorer. The name of your game is the name of the
template folder (you can also type a name at the top of `package.bat`).

The zip file contains a folder with `<name of your game>.exe`, `SDL3.dll`, the `assets` folder and the SDL3
license. Players unzip it and double-click the `.exe`: they don't need to install anything (the Release
build has the C++ runtime built in). Send the zip file to your friends, upload it to itch.io, or hand it in.

## Making a web build

The template can also be built for the web with [Emscripten](https://emscripten.org), so you can
share your game as a web page (for example on itch.io or GitHub Pages):

1. Install the emsdk once, following https://emscripten.org/docs/getting_started/downloads.html
   (install it to `C:\emsdk`, or next to your template folder).
2. Double-click `build-web.bat`. The first build takes a few minutes, because it also
   downloads and builds SDL3 for the web.
3. The game opens in your browser. The files for the web are in the `web-build` folder: upload
   all of them (`index.html`, `index.js`, `index.wasm` and `index.data`) to your web host.

The game fills the browser window; the button in the top-right corner (it fades out while the mouse doesn't move),
F11 or Alt+Enter switch to fullscreen. In the browser, `std::cout` writes to the browser console (press F12 to see it).
The `assets` folder is packed into `index.data`, so loading images works the same way as on Windows.

## Building with CMake (Windows, Linux and the web)

If you know CMake, you can also build the template with `CMakeLists.txt` and the presets in
`CMakePresets.json`. Visual Studio (File > Open > Folder), VS Code and CLion pick up the presets
automatically. From a terminal:

| Platform | Configure | Build (also `-release` or `-relwithdebinfo`) |
|---|---|---|
| Windows, Visual Studio 2026 solution | `cmake --preset windows-vs` | `cmake --build --preset windows-vs-debug` |
| Windows, Ninja (in a Developer Command Prompt) | `cmake --preset windows-ninja` | `cmake --build --preset windows-ninja-debug` |
| Linux, Ninja | `cmake --preset linux` | `cmake --build --preset linux-debug` |
| Web, Ninja + Emscripten | `cmake --preset web` | `cmake --build --preset web-release` |

Or configure and build Release in one step: `cmake --workflow --preset windows-vs` (or `linux`, or `web`).
The builds go to `build/<preset>/<configuration>`, with the assets copied next to the executable.
Use RelWithDebInfo (optimized, with debug information) for profiling.

- **Windows** uses the SDL3 in `lib/SDL3`, like `tmpl8.slnx`.
- **Linux** uses an installed SDL3 (e.g. the `libsdl3-dev` package). If there is none, SDL3 is downloaded and
  built as part of the project; that needs the X11 and/or Wayland development packages, see
  https://wiki.libsdl.org/SDL3/README-linux#build-dependencies. You need CMake 3.26 or newer and Ninja.
- **Web** uses Emscripten from the `EMSDK` environment variable (or `-DEMSDK=<folder>`), from `emcc` on the PATH,
  or from `C:\emsdk` or an `emsdk` folder next to the template folder. If Emscripten isn't found, the emsdk is
  downloaded and installed once (in `%LOCALAPPDATA%\tmpl8\emsdk`, or `~/.local/share/tmpl8/emsdk` on Linux),
  which needs Python 3. The result is `build/web/Release/index.html` (with `index.js`, `index.wasm` and
  `index.data`): upload those files, or test them with `emrun build/web/Release/index.html`.
- `-DTMPL8_FETCH_SDL3=ON` always builds SDL3 from source.

## You can go further by

- Expanding the game class in `game.hpp` (add your sprites and other game objects as members of `Game`);
- Reading the keyboard with `GetKey`, `GetKeyPressed` and `GetKeyReleased` in
  `Game::Tick`, and implementing the empty mouse functions in `game.hpp`;
- Sprite sheets with the frames in a grid: `Sprite( "assets/hero.png", 8, 4 )` has 8 columns and 4 rows, and
  `SetFrame( column, row )` picks a frame by its place in the grid;
- Sharing one image between many sprites: copy a `Sprite` (e.g. `std::vector<Sprite> enemies( 10, enemySprite )`),
  or create them from the same `std::shared_ptr<Surface>`. Each sprite has its own current frame;
- Exploring the code of the template in `surface.cpp` and `template.cpp`.

When handing in assignments based on this template, close Visual Studio
and double-click `clean.bat` before zipping the folder. This deletes the
files created during compilation (including the hidden `.vs` folder, which
can be hundreds of megabytes).

The Template is a 'quickstart' template, and not meant to be elaborate
performant or complete.
At some point, and depending on your requirements, you may want to
advance to a more full-fledged library, or you can expand the template
with your own SDL3 code.

## Credits

Although the template is small and bare bones, it still uses a lot of
code gathered over the years:

- EasyCE's 5x5 bitmap font (primarily used for debugging);
- EasyCE's surface class (with lots of modifications);
- [SDL3](https://www.libsdl.org) for the window, the frame buffer and the input
  (zlib license, see `lib/SDL3/LICENSE.txt`);
- [stb_image](https://github.com/nothings/stb) to load images
  (public domain / MIT license, see the end of `lib/stb/stb_image.h`).

## License

The template is free to use and distribute in any form: it is licensed under the
[MIT No Attribution](LICENSE) license, so you don't even need to mention the template in your game.
SDL3 (zlib license) and stb_image (public domain or MIT) have their own licenses, see [LICENSE](LICENSE).
The images in the `assets` folder may be used freely in projects made with the template.

## Template Naming

Starting January 2017, the name of the template represents the version.
This version also appears in the title of the window. Make sure you
are using the most recent version.

Breda, 2014-2026, Games @ Breda University (NHTV/IGAD)
Utrecht, 2015-2019, Utrecht University
Report problems and suggestions to Jeremiah van Oosten if working on this connected to Breda University then email oosten.j@buas.nl otherwise bikker.j@gmail.com.

## Changelog

**v2026-11**:

- SDL3 (3.4.20) instead of SDL2 2.0.3; the window can be resized or made fullscreen, and the frame buffer is scaled to fit.
- stb_image instead of FreeImage to load images (PNG, TGA, JPEG, BMP, GIF).
- No more DLL folders: `SDL3.dll` is copied next to the `.exe` when you build. Removed FreeImage, GLEW, the OpenGL
  code path and the 32-bit (x86) files.
- Debug builds open a console window next to the game window for `printf` and `std::cout` (no extra code needed);
  Release builds only show the game window.
- The keyboard state is updated before every `Tick` (no need to call `ProcessInput` yourself), and a key that is
  tapped quickly (pressed and released within one frame) still counts as pressed.
- `MouseMove` receives the mouse position in the window (it used to be the relative motion).
- Fullscreen: Alt+Enter or F11 (and `ToggleFullscreen()`, `SetFullscreen()`, `IsFullscreen()`), on Windows and in the
  browser. `StartFullscreen` in `template.hpp` replaces `#define FULLSCREEN`. In the browser the page fills the whole
  window, with as many pixels as the screen has, so SDL_SCALEMODE_PIXELART does all the scaling.
- VSync: `StartVSync` in `template.hpp`, and `SetVSync()`, `IsVSync()` and `ToggleVSync()` (no need to change
  `template.cpp` to turn it off).
- Web builds with Emscripten: double-click `build-web.bat`. SDL runs the main loop (SDL3's main callbacks in
  `template.cpp`), so the same code runs on Windows and in the browser.
- CMake build (`CMakeLists.txt`, `CMakePresets.json`) for Windows (Visual Studio or Ninja), Linux and the web.
  The Emscripten toolchain (`cmake/EmscriptenToolchain.cmake`) installs the emsdk when it isn't found.
- Images are also found next to the executable when the game is started from another folder, and file names
  with accents or other scripts work.
- `package.bat` builds the Release version and packs the game in a zip file to share. Release builds link the C++
  runtime statically, so players don't need the Visual C++ Redistributable.
- 2D sprite sheets: `Sprite( file, columns, rows )` (rows is 1 by default, so `Sprite( file, frames )` still works),
  `SetFrame( column, row )`, `Columns()` and `Rows()`. `DrawScaled` no longer draws outside the target surface.
- Removed the unused `Sprite` flags (`FLARE`, `OPFLARE`, ... and `SetFlags`/`GetFlags`); only `FLARE` did anything.
  For additive blending, use `AddBlend` or `Surface::BlendCopyTo`.
- A `LICENSE` file: MIT No Attribution (the template was already free to use in any form).
- Clearer error message when an image can't be loaded.
- Sprites share their image: `Sprite( "assets/file.png", frames )` loads it, `Sprite( std::shared_ptr<Surface>, frames )`
  shares an image that is already loaded, and copies of a sprite share the image (each with its own frame).
  `Sprite( new Surface( ... ), frames )` (the sprite took ownership of a raw pointer) is gone.
- `Game` gets the screen in its constructor (`Surface& screen`, so `screen.Plot( ... )` instead of `screen->Plot( ... )`),
  and the example sprite is a member of `Game` instead of a global variable. `SetTarget` is gone.
- References instead of pointers for parameters that can't be null (C++ Core Guidelines F.60): `Sprite::Draw( Surface&, ... )`,
  `Surface::CopyTo`, `BlendCopyTo`, `Resize` and the `Font` functions.
- Modern C++ instead of C: `std::string_view` for text, `std::vector` instead of `new[]`/`delete[]`, `std::cout`/`std::cerr`
  instead of `printf`, `<algorithm>` instead of `memcpy`/`memset`, `static_cast` instead of C-style casts, and a
  `constexpr` table for the built-in font. C APIs are only used for SDL and stb_image.
- Const-correct `Surface`, `Sprite` and `Font` functions; surfaces can be moved but not copied by accident.
- C++ headers use the `.hpp` extension (`game.hpp`, `surface.hpp`, `template.hpp`).
- `template.hpp` only has what the template and the tutorials use: screen size, `Rand`/`IRand`, `Min`/`Max`/`Clamp`,
  `PI`, `vec2` and `vec3`.
- C++23, intermediate files in `build/vs` (outside the source folders, ignored by git), and a shorter `clean.bat`.

**v2026-02**: Removed Visual Studio 2022 solution and project files.

**v2026**: Update project and solution files to Visual Studio 2022 and Visual Studio 2026.
Fix compiler errors when using C++17 or higher.

**v2019-08**: Removed headers from the precompiled header file to speed up compilation.
fixed uninitialised values in the surface class.

**v2017-01**: initial DGDARC release.

**v2017-02**:

- added a changelog.
- debug mode now also emits .exe to project folder.
- removed rogue SDL2 folder.
- added assert.h to precomp.h.
