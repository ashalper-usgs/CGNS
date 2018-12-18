set(CTEST_PROJECT_NAME "cgns")
set(CTEST_BUILD_NAME "$ENV{SGEN}-cgns")
set(CTEST_SITE "$ENV{COMPUTERNAME}")

set(VER "$ENV{CGNSLIB_VER}")
if(WIN32 AND "${VER}" STREQUAL "3.2.1")
  set(VER "$ENV{CGNSLIB_VER}-patch1")
endif()
set(HDF5_VER "$ENV{HDF5_VER}")
set(CTEST_SOURCE_DIRECTORY "${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}")
set(CTEST_BINARY_DIRECTORY "${CTEST_SCRIPT_DIRECTORY}/lib/build/cgnslib-${VER}")

if (WIN32)
  set(HDF_INC "${CTEST_SCRIPT_DIRECTORY}/lib/install/hdf5-${HDF5_VER}/${CONF_DIR}/include")
  if("${CONF_DIR}" STREQUAL "debug")
    set(HDF_LIB "${CTEST_SCRIPT_DIRECTORY}/lib/install/hdf5-${HDF5_VER}/${CONF_DIR}/lib/hdf5_D.lib")
  else()
    set(HDF_LIB "${CTEST_SCRIPT_DIRECTORY}/lib/install/hdf5-${HDF5_VER}/${CONF_DIR}/lib/hdf5.lib")

    # HACK to force extract_subset.c to compile (fails w/ VS2013 Release build)
    file(RENAME
      ${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c
      ${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c.orig
    )
    file(WRITE
      ${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c
      "int main(int argc, char *argv[]) { return 0; }\n"
    )
  endif()
else()
  # See
  # https://cmake.org/cmake/help/v2.8.12/cmake.html#module:FindHDF5
  find_package(HDF5)
  set(HDF_LIB "${HDF5_C_LIBRARIES}")
endif()

set(CGNS_ENABLE_FORTRAN ON)
set(
  BUILD_OPTIONS 
  -DCMAKE_INSTALL_PREFIX:PATH=${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}
  -DCGNS_BUILD_CGNSTOOLS:BOOL=$ENV{BUILD_TOOLS}
  -DCGNS_ENABLE_FORTRAN:BOOL=${CGNS_ENABLE_FORTRAN}
  -DCGNS_ENABLE_HDF5:BOOL=ON
  -DCGNS_ENABLE_LFS:BOOL=ON
  -DHDF5_LIBRARY:FILEPATH=${HDF_LIB}
  -DCGNS_RPMBUILD:BOOL=${CGNS_RPMBUILD}
)

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  list(APPEND BUILD_OPTIONS
    "-DCMAKE_C_FLAGS:STRING=-D_LARGEFILE64_SOURCE")
endif()

CTEST_START("Experimental")
CTEST_CONFIGURE(BUILD "${CTEST_BINARY_DIRECTORY}"
                OPTIONS "${BUILD_OPTIONS}")
CTEST_BUILD(BUILD "${CTEST_BINARY_DIRECTORY}")
if (WIN32)
  file(COPY "${CTEST_SCRIPT_DIRECTORY}/lib/build/cgnslib-${VER}/src/${CONF_DIR}/cgnsdll.dll" DESTINATION "${CTEST_SCRIPT_DIRECTORY}/lib/build/cgnslib-${VER}/src")
endif()
CTEST_BUILD(BUILD "${CTEST_BINARY_DIRECTORY}" TARGET install)

if (CGNS_ENABLE_FORTRAN)
  # fix comments for cgnslib_f.h
  file(RENAME
    ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/include/cgnslib_f.h
    ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/include/cgnslib_f.h.orig)

  file(STRINGS
    ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/include/cgnslib_f.h.orig
    lines)
endif()

foreach(line IN LISTS lines)
  if (line)
    STRING(REGEX REPLACE "^c" "!c" new_line ${line})
  else()
    set(new_line ${line})
  endif()
  file(APPEND
    ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/include/cgnslib_f.h
    "${new_line}\n"
  )
endforeach()

if($ENV{BUILD_TOOLS} MATCHES "[Oo][Nn]" AND "${CONF_DIR}" STREQUAL "release")
  if (WIN32)
    # restore original extract_subset.c
    file(REMOVE
      ${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c
    )
    file(RENAME
      ${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c.orig
      ${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c
    )
    # delete fake extract_subset.exe
    file(REMOVE
      ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/extract_subset.exe
    )
    # write note about extract-subset.exe
    file(WRITE
      ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/extract_subset.exe.txt
      "${CTEST_SCRIPT_DIRECTORY}/lib/src/cgnslib-${VER}/src/cgnstools/utilities/extract_subset.c causes an internal compiler error in VS2013 Release. (see ${CTEST_SCRIPT_DIRECTORY}/build-cgnslib.cmake.\n"
    )
  endif()
endif()

if ($ENV{BUILD_TOOLS} MATCHES "[Oo][Nn]")
  if (WIN32)
    # add hdf5 path to cgconfig.bat
    file(RENAME
      ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/cgconfig.bat
      ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/cgconfig.bat.orig
    )
    file(STRINGS
      ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/cgconfig.bat.orig
      lines
    )
    foreach(line IN LISTS lines)
      file(APPEND
        ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/cgconfig.bat
        "${line}\n"
      )
    endforeach()
    file(TO_NATIVE_PATH "${CTEST_SCRIPT_DIRECTORY}/lib/install/hdf5-${HDF5_VER}/${CONF_DIR}/bin" HDF5PATH)
    file(APPEND
      ${CTEST_SCRIPT_DIRECTORY}/lib/install/cgnslib-${VER}/${CONF_DIR}/bin/cgconfig.bat
      "set PATH=%PATH%;${HDF5PATH}\n"
    )
  endif()
endif()
