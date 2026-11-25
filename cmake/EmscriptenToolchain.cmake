# Emscripten toolchain for the "web" CMake presets (see CMakePresets.json).
#
# Uses an Emscripten that is already installed, or downloads and installs the emsdk the first time:
#   1. -DEMSDK=<folder> or the EMSDK environment variable: an emsdk folder (set by emsdk_env).
#   2. emcc on the PATH.
#   3. An emsdk in C:\emsdk or next to the template folder, or one that this file installed before (TMPL8_EMSDK_DIR).
#   4. Otherwise the emsdk (version TMPL8_EMSDK_VERSION) is downloaded to TMPL8_EMSDK_DIR and installed there.
#      This needs Python 3 and takes a while (about 1 GB), but only happens once per computer.
#
# CMake reads a toolchain file several times while it configures (also for its compiler checks), so the
# Emscripten folder that was found is remembered in an environment variable of the CMake process.

set(TMPL8_EMSDK_VERSION "6.0.11" CACHE STRING "emsdk version to install when Emscripten is not found")
if(CMAKE_HOST_WIN32)
	set(_tmpl8_default_emsdk_dir "$ENV{LOCALAPPDATA}/tmpl8/emsdk")
else()
	set(_tmpl8_default_emsdk_dir "$ENV{HOME}/.local/share/tmpl8/emsdk")
endif()
set(TMPL8_EMSDK_DIR "${_tmpl8_default_emsdk_dir}" CACHE PATH "Where to install the emsdk when Emscripten is not found")
file(TO_CMAKE_PATH "${TMPL8_EMSDK_DIR}" TMPL8_EMSDK_DIR)

# Returns the Emscripten folder of an emsdk folder, if it has one.
function(_tmpl8_emscripten_in_emsdk emsdk_dir out_var)
	set(${out_var} "" PARENT_SCOPE)
	if(emsdk_dir AND EXISTS "${emsdk_dir}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake")
		set(${out_var} "${emsdk_dir}/upstream/emscripten" PARENT_SCOPE)
	endif()
endfunction()

# Returns a Python 3 interpreter that works (on Windows, "python3" can be a shortcut to the Microsoft Store).
function(_tmpl8_find_python out_var)
	set(${out_var} "" PARENT_SCOPE)
	set(_candidates "$ENV{EMSDK_PYTHON}")
	foreach(_name python3 python py)
		find_program(_tmpl8_python_${_name} NAMES ${_name} NO_CACHE)
		list(APPEND _candidates "${_tmpl8_python_${_name}}")
	endforeach()
	foreach(_python IN LISTS _candidates)
		if(NOT _python)
			continue()
		endif()
		execute_process(COMMAND "${_python}" -c "import sys; print(sys.version_info[0])"
			OUTPUT_VARIABLE _major OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE _result ERROR_QUIET)
		if(_result EQUAL 0 AND _major STREQUAL "3")
			set(${out_var} "${_python}" PARENT_SCOPE)
			return()
		endif()
	endforeach()
endfunction()

set(_tmpl8_emscripten "$ENV{TMPL8_EMSCRIPTEN_ROOT}")

# 1. An emsdk folder given on the command line or in the environment.
if(NOT _tmpl8_emscripten)
	if(NOT EMSDK AND DEFINED ENV{EMSDK})
		set(EMSDK "$ENV{EMSDK}")
	endif()
	file(TO_CMAKE_PATH "${EMSDK}" EMSDK)
	_tmpl8_emscripten_in_emsdk("${EMSDK}" _tmpl8_emscripten)
endif()

# 2. emcc on the PATH.
if(NOT _tmpl8_emscripten)
	find_program(_tmpl8_emcc NAMES emcc NO_CACHE)
	if(_tmpl8_emcc)
		file(REAL_PATH "${_tmpl8_emcc}" _tmpl8_emcc)
		get_filename_component(_tmpl8_emcc_dir "${_tmpl8_emcc}" DIRECTORY)
		if(EXISTS "${_tmpl8_emcc_dir}/cmake/Modules/Platform/Emscripten.cmake")
			set(_tmpl8_emscripten "${_tmpl8_emcc_dir}")
		endif()
	endif()
endif()

# 3. An emsdk in the usual places (the same ones build-web.bat looks in), or one that was installed before.
foreach(_tmpl8_dir "C:/emsdk" "${CMAKE_CURRENT_LIST_DIR}/../../emsdk" "${TMPL8_EMSDK_DIR}")
	if(NOT _tmpl8_emscripten)
		get_filename_component(_tmpl8_dir "${_tmpl8_dir}" ABSOLUTE)
		_tmpl8_emscripten_in_emsdk("${_tmpl8_dir}" _tmpl8_emscripten)
	endif()
endforeach()

# 4. Download and install the emsdk.
if(NOT _tmpl8_emscripten)
	_tmpl8_find_python(_tmpl8_python)
	if(NOT _tmpl8_python)
		message(FATAL_ERROR
			"Emscripten was not found, and installing it needs Python 3, which was not found either.\n"
			"Install Python 3 (https://www.python.org/downloads/) and configure again, or install the emsdk yourself "
			"(https://emscripten.org/docs/getting_started/downloads.html) and set the EMSDK environment variable "
			"to its folder.")
	endif()
	message(STATUS "Emscripten was not found: installing emsdk ${TMPL8_EMSDK_VERSION} in ${TMPL8_EMSDK_DIR} (this takes a while, but only once)")
	if(NOT EXISTS "${TMPL8_EMSDK_DIR}/emsdk.py")
		get_filename_component(_tmpl8_parent "${TMPL8_EMSDK_DIR}" DIRECTORY)
		set(_tmpl8_zip "${_tmpl8_parent}/emsdk-${TMPL8_EMSDK_VERSION}.zip")
		file(DOWNLOAD "https://github.com/emscripten-core/emsdk/archive/refs/tags/${TMPL8_EMSDK_VERSION}.zip"
			"${_tmpl8_zip}" STATUS _tmpl8_status SHOW_PROGRESS)
		list(GET _tmpl8_status 0 _tmpl8_code)
		if(NOT _tmpl8_code EQUAL 0)
			list(GET _tmpl8_status 1 _tmpl8_error)
			message(FATAL_ERROR "Downloading the emsdk failed: ${_tmpl8_error}")
		endif()
		file(ARCHIVE_EXTRACT INPUT "${_tmpl8_zip}" DESTINATION "${_tmpl8_parent}")
		file(REMOVE_RECURSE "${TMPL8_EMSDK_DIR}")
		file(RENAME "${_tmpl8_parent}/emsdk-${TMPL8_EMSDK_VERSION}" "${TMPL8_EMSDK_DIR}")
		file(REMOVE "${_tmpl8_zip}")
	endif()
	foreach(_tmpl8_step install activate)
		execute_process(COMMAND "${_tmpl8_python}" emsdk.py ${_tmpl8_step} ${TMPL8_EMSDK_VERSION}
			WORKING_DIRECTORY "${TMPL8_EMSDK_DIR}" RESULT_VARIABLE _tmpl8_result)
		if(NOT _tmpl8_result EQUAL 0)
			message(FATAL_ERROR "\"emsdk ${_tmpl8_step} ${TMPL8_EMSDK_VERSION}\" failed (see the messages above).")
		endif()
	endforeach()
	_tmpl8_emscripten_in_emsdk("${TMPL8_EMSDK_DIR}" _tmpl8_emscripten)
	if(NOT _tmpl8_emscripten)
		message(FATAL_ERROR "The emsdk was installed in ${TMPL8_EMSDK_DIR}, but Emscripten was not found in it.")
	endif()
endif()

set(ENV{TMPL8_EMSCRIPTEN_ROOT} "${_tmpl8_emscripten}")

# On Windows, emcc.exe runs emcc.py with the Python in EMSDK_PYTHON (or "python" on the PATH). Use the Python that
# the emsdk installed, so the build also works outside an emsdk command prompt. The compiler and linker get it through
# a launcher, because CMake doesn't pass its own environment on to the build.
if(CMAKE_HOST_WIN32)
	get_filename_component(_tmpl8_emsdk_root "${_tmpl8_emscripten}/../.." ABSOLUTE)
	file(GLOB _tmpl8_emsdk_python "${_tmpl8_emsdk_root}/python/*/python.exe")
	if(_tmpl8_emsdk_python)
		list(SORT _tmpl8_emsdk_python ORDER DESCENDING)
		list(GET _tmpl8_emsdk_python 0 _tmpl8_emsdk_python)
	else()
		_tmpl8_find_python(_tmpl8_emsdk_python)
	endif()
	if(NOT _tmpl8_emsdk_python)
		message(FATAL_ERROR "Emscripten needs Python 3, which was not found. Install Python 3 (https://www.python.org/downloads/) or set EMSDK_PYTHON.")
	endif()
	set(ENV{EMSDK_PYTHON} "${_tmpl8_emsdk_python}")
	set(CMAKE_C_COMPILER_LAUNCHER "${CMAKE_COMMAND};-E;env;EMSDK_PYTHON=${_tmpl8_emsdk_python}")
	set(CMAKE_CXX_COMPILER_LAUNCHER "${CMAKE_COMMAND};-E;env;EMSDK_PYTHON=${_tmpl8_emsdk_python}")
	set(CMAKE_C_LINKER_LAUNCHER "${CMAKE_COMMAND};-E;env;EMSDK_PYTHON=${_tmpl8_emsdk_python}")
	set(CMAKE_CXX_LINKER_LAUNCHER "${CMAKE_COMMAND};-E;env;EMSDK_PYTHON=${_tmpl8_emsdk_python}")
	# Static libraries (that are built as part of the game) are packed by emar and emranlib, which are Python scripts
	# too, but CMake has no launcher for them: give them the Python in the rules that make a static library.
	set(_tmpl8_env "\"${CMAKE_COMMAND}\" -E env \"EMSDK_PYTHON=${_tmpl8_emsdk_python}\"")
	foreach(_tmpl8_lang C CXX)
		set(CMAKE_${_tmpl8_lang}_ARCHIVE_CREATE "${_tmpl8_env} <CMAKE_AR> qc <TARGET> <LINK_FLAGS> <OBJECTS>")
		set(CMAKE_${_tmpl8_lang}_ARCHIVE_APPEND "${_tmpl8_env} <CMAKE_AR> q <TARGET> <LINK_FLAGS> <OBJECTS>")
		set(CMAKE_${_tmpl8_lang}_ARCHIVE_FINISH "${_tmpl8_env} <CMAKE_RANLIB> <TARGET>")
	endforeach()
endif()

include("${_tmpl8_emscripten}/cmake/Modules/Platform/Emscripten.cmake")
