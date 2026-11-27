# CMake build for the template: Windows, Linux and the web (Emscripten).
# Beginners don't need this: open tmpl8.slnx in Visual Studio instead. See README.md and CMakePresets.json.
cmake_minimum_required(VERSION 3.26)

project(tmpl8 VERSION 2026.11 LANGUAGES C CXX)

# Configurations: Debug, Release, RelWithDebInfo (optimized, with debug information: use this one for profiling)
# and MinSizeRel. Single-configuration generators build Debug by default.
get_property(_tmpl8_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT _tmpl8_multi_config AND NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build configuration (Debug, Release, RelWithDebInfo or MinSizeRel)" FORCE)
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# MSVC: link the C++ runtime into the executable (except in Debug), so players don't need to install the Visual C++
# Redistributable. (Set before any target is created, so a SDL3 that is built from source uses the same runtime.)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:DebugDLL>")

option(TMPL8_FETCH_SDL3 "Download and build SDL3 from source instead of using the SDL3 in lib/SDL3 (Windows) or an installed SDL3 (Linux)" OFF)
set(TMPL8_SDL3_VERSION "3.4.20")

add_executable(tmpl8)
# The source files: every .cpp and .hpp file in the src folder and its subfolders (game.cpp and game.hpp, the files you
# add, and the template in src/Tmpl8). CONFIGURE_DEPENDS makes the build notice a file that you add (or remove).
file(GLOB_RECURSE _tmpl8_sources CONFIGURE_DEPENDS src/*.cpp src/*.hpp)
target_sources(tmpl8 PRIVATE ${_tmpl8_sources})
# Show the subfolders of src in the IDE too.
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src" PREFIX src FILES ${_tmpl8_sources})
target_include_directories(tmpl8 PRIVATE src src/Tmpl8 lib/stb)
set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT tmpl8)

if(MSVC)
	target_compile_definitions(tmpl8 PRIVATE _CRT_SECURE_NO_WARNINGS)
	target_compile_options(tmpl8 PRIVATE /W3 /permissive- /utf-8 $<$<CONFIG:Debug>:/sdl>)
	if(CMAKE_GENERATOR MATCHES "Visual Studio")
		target_compile_options(tmpl8 PRIVATE /MP)
	endif()
endif()

# --- SDL3 -----------------------------------------------------------------------------------------------------------

if(EMSCRIPTEN)
	# Emscripten has SDL3 built in ("port"): it is downloaded and built the first time.
	target_compile_options(tmpl8 PRIVATE --use-port=sdl3)
	target_link_options(tmpl8 PRIVATE --use-port=sdl3)
else()
	if(NOT TMPL8_FETCH_SDL3)
		if(MSVC AND CMAKE_SIZEOF_VOID_P EQUAL 8 AND NOT CMAKE_SYSTEM_PROCESSOR MATCHES "ARM|arm")
			# Windows (x64): the SDL3 in lib/SDL3, the same one the Visual Studio solution uses.
			find_package(SDL3 CONFIG REQUIRED PATHS "${CMAKE_CURRENT_SOURCE_DIR}/lib/SDL3/cmake" NO_DEFAULT_PATH)
			set(_tmpl8_sdl3_dll ON) # SDL3.dll must be copied next to the .exe
		else()
			# Linux (and others): an installed SDL3 (e.g. the libsdl3-dev package), if there is one.
			find_package(SDL3 3.2 CONFIG QUIET)
		endif()
	endif()
	if(NOT TARGET SDL3::SDL3)
		# No SDL3 found: download and build it, as part of this project (only the first time).
		message(STATUS "SDL3 was not found: building SDL ${TMPL8_SDL3_VERSION} from source")
		include(FetchContent)
		set(SDL_SHARED OFF CACHE BOOL "" FORCE)
		set(SDL_STATIC ON CACHE BOOL "" FORCE)
		set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
		set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
		if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
			# SDL stops when an X11 extension it wants isn't installed. The template doesn't need them, so only use
			# the ones that are installed (install libxss-dev, libxtst-dev, ... to enable the others).
			include(CheckIncludeFile)
			foreach(_tmpl8_x11 "XCURSOR;X11/Xcursor/Xcursor.h" "XDBE;X11/extensions/Xdbe.h" "XINPUT;X11/extensions/XInput2.h"
					"XFIXES;X11/extensions/Xfixes.h" "XRANDR;X11/extensions/Xrandr.h" "XSCRNSAVER;X11/extensions/scrnsaver.h"
					"XSHAPE;X11/extensions/shape.h" "XSYNC;X11/extensions/sync.h" "XTEST;X11/extensions/XTest.h")
				list(GET _tmpl8_x11 0 _tmpl8_ext)
				list(GET _tmpl8_x11 1 _tmpl8_header)
				check_include_file("${_tmpl8_header}" TMPL8_HAVE_X11_${_tmpl8_ext})
				if(NOT TMPL8_HAVE_X11_${_tmpl8_ext})
					message(STATUS "SDL3: X11 extension ${_tmpl8_ext} not installed (${_tmpl8_header}), building without it")
					set(SDL_X11_${_tmpl8_ext} OFF CACHE BOOL "" FORCE)
				endif()
			endforeach()
		endif()
		FetchContent_Declare(SDL3
			URL "https://github.com/libsdl-org/SDL/releases/download/release-${TMPL8_SDL3_VERSION}/SDL3-${TMPL8_SDL3_VERSION}.tar.gz"
			URL_HASH SHA256=f3bb06f55bed9557227a700af2ea62e49497ebdf58037732a731a5fb3ef8581f
			DOWNLOAD_EXTRACT_TIMESTAMP ON
			EXCLUDE_FROM_ALL
		)
		FetchContent_MakeAvailable(SDL3)
	endif()
	target_link_libraries(tmpl8 PRIVATE SDL3::SDL3)
endif()

# --- Output -----------------------------------------------------------------------------------------------------------

if(EMSCRIPTEN)
	# A web page: index.html with index.js, index.wasm and index.data (the assets) next to it.
	set_target_properties(tmpl8 PROPERTIES OUTPUT_NAME index SUFFIX ".html")
	target_link_options(tmpl8 PRIVATE
		"--preload-file=${CMAKE_CURRENT_SOURCE_DIR}/assets@assets"
		"--shell-file=${CMAKE_CURRENT_SOURCE_DIR}/src/Tmpl8/web-shell.html"
		-sALLOW_MEMORY_GROWTH
	)
	set_property(TARGET tmpl8 APPEND PROPERTY LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/Tmpl8/web-shell.html")
	file(GLOB_RECURSE _tmpl8_assets CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/assets/*")
	set_property(TARGET tmpl8 APPEND PROPERTY LINK_DEPENDS ${_tmpl8_assets})
	# "cmake --build --preset web-release --target run" builds the game and opens it in the browser. A browser can't
	# run it from a file on disk (file://), so emrun serves it from a local web server, until you stop it (Ctrl+C).
	find_program(TMPL8_EMRUN NAMES emrun emrun.bat HINTS "${EMSCRIPTEN_ROOT_PATH}" NO_DEFAULT_PATH)
	if(TMPL8_EMRUN)
		set(_tmpl8_emrun "${TMPL8_EMRUN}")
		if(CMAKE_HOST_WIN32 AND DEFINED ENV{EMSDK_PYTHON})
			# emrun is a Python script too: give it the Python that the toolchain found (see EmscriptenToolchain.cmake).
			set(_tmpl8_emrun "${CMAKE_COMMAND}" -E env "EMSDK_PYTHON=$ENV{EMSDK_PYTHON}" "${TMPL8_EMRUN}")
		endif()
		add_custom_target(run
			COMMAND ${_tmpl8_emrun} --no_emrun_detect "$<TARGET_FILE:tmpl8>"
			DEPENDS tmpl8
			USES_TERMINAL
			VERBATIM)
	endif()
else()
	if(WIN32)
		# Only Debug builds have a console window (like the Visual Studio solution).
		set_target_properties(tmpl8 PROPERTIES WIN32_EXECUTABLE $<NOT:$<CONFIG:Debug>>)
		if(_tmpl8_sdl3_dll)
			# SDL3.dll next to the .exe.
			add_custom_command(TARGET tmpl8 POST_BUILD
				COMMAND "${CMAKE_COMMAND}" -E copy_if_different $<TARGET_RUNTIME_DLLS:tmpl8> $<TARGET_FILE_DIR:tmpl8>
				COMMAND_EXPAND_LISTS)
		endif()
	endif()
	# The assets next to the executable, so the game also runs from the build folder.
	add_custom_target(tmpl8_assets
		COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different "${CMAKE_CURRENT_SOURCE_DIR}/assets" "$<TARGET_FILE_DIR:tmpl8>/assets"
		COMMENT "Copying the assets next to the executable")
	add_dependencies(tmpl8 tmpl8_assets)
	# Visual Studio: run from the template folder when debugging (F5), like the solution does.
	set_target_properties(tmpl8 PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
endif()

# --- Packaging --------------------------------------------------------------------------------------------------------

# "cmake --workflow --preset windows-vs-package" (or "web-package") builds the Release version and packs the game in a
# zip file that you can share: build/<name of your game>.zip (build/<name of your game>-web.zip for the web).
# package.bat runs the Windows one. The install rules below say what goes in it (only the "game" component, so the
# install rules of libraries that are built as part of the project are left out).

# The name of your game: TMPL8_GAME_NAME (package.bat sets it from the GAME_NAME at its top, through the environment
# variable of the same name, see CMakePresets.json), or else the name of the Visual Studio project (*.vcxproj),
# which you can rename in the Solution Explorer.
set(_tmpl8_game_name "${TMPL8_GAME_NAME}")
if(NOT _tmpl8_game_name)
	file(GLOB _tmpl8_vcxproj "${CMAKE_CURRENT_SOURCE_DIR}/*.vcxproj")
	if(_tmpl8_vcxproj)
		list(GET _tmpl8_vcxproj 0 _tmpl8_vcxproj)
		get_filename_component(_tmpl8_game_name "${_tmpl8_vcxproj}" NAME_WE)
		file(STRINGS "${_tmpl8_vcxproj}" _tmpl8_project_name REGEX "<ProjectName>.*</ProjectName>" LIMIT_COUNT 1)
		if(_tmpl8_project_name MATCHES "<ProjectName>(.*)</ProjectName>")
			set(_tmpl8_game_name "${CMAKE_MATCH_1}")
		endif()
	else()
		set(_tmpl8_game_name "${PROJECT_NAME}")
	endif()
endif()

if(EMSCRIPTEN)
	# The web page, with index.html at the top of the zip file (itch.io looks for it there).
	install(FILES
		"$<TARGET_FILE:tmpl8>"
		"$<TARGET_FILE_DIR:tmpl8>/index.js"
		"$<TARGET_FILE_DIR:tmpl8>/index.wasm"
		"$<TARGET_FILE_DIR:tmpl8>/index.data"
		DESTINATION . COMPONENT game)
	set(CPACK_PACKAGE_FILE_NAME "${_tmpl8_game_name}-web")
	set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
else()
	# <name of your game>.exe, with the assets folder next to it (and SDL3.dll and its license on Windows).
	install(PROGRAMS "$<TARGET_FILE:tmpl8>" DESTINATION . RENAME "${_tmpl8_game_name}${CMAKE_EXECUTABLE_SUFFIX}"
		COMPONENT game)
	install(DIRECTORY assets/ DESTINATION assets COMPONENT game)
	if(WIN32)
		install(FILES $<TARGET_RUNTIME_DLLS:tmpl8> DESTINATION . COMPONENT game)
	endif()
	if(_tmpl8_sdl3_dll AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lib/SDL3/LICENSE.txt")
		install(FILES lib/SDL3/LICENSE.txt DESTINATION . RENAME LICENSE-SDL3.txt COMPONENT game)
	endif()
	# The zip file has a folder with the name of your game, so it unzips into a folder of its own.
	set(CPACK_PACKAGE_FILE_NAME "${_tmpl8_game_name}")
	set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY ON)
	set(CPACK_COMPONENT_INCLUDE_TOPLEVEL_DIRECTORY ON)
endif()

set(CPACK_PACKAGE_NAME "${_tmpl8_game_name}")
set(CPACK_GENERATOR ZIP)
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build")
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_COMPONENTS_ALL game)
set(CPACK_COMPONENTS_GROUPING ALL_COMPONENTS_IN_ONE)
set(CPACK_VERBATIM_VARIABLES ON)
include(CPack)
