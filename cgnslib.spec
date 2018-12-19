Name:           cgnslib
Version:        3.2.1
Release:        3%{?dist}
Summary:        Computational Fluid Dynamics General Notation System

License:        zlib
URL:            http://www.cgns.org/
Source0:        https://github.com/ashalper-usgs/CGNS/archive/rpmbuild.zip

BuildRequires:  unzip, cmake, gcc-gfortran, hdf5-devel

%description
The Computational Fluid Dynamics General Notation System (CGNS) provides a
general, portable, and extensible standard for the storage and retrieval of
computational fluid dynamics (CFD) analysisdata. It consists of a collection
of conventions, and free and open software implementing those conventions. It
is self-descriptive, machine-independent, well-documented, and administered by
an international steering committee.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description    devel
The %{name}-devel package contains libraries and header files for
developing applications that use %{name}.


%prep
%setup -q -n CGNS


%build
# See Fastmech-BMI/bin/build-gcc-solver.sh

GENERATOR="Unix Makefiles"
SGEN="gcc"

export GENERATOR SGEN

# See iricdev/build-cgnslib.sh

if [ -z "$GENERATOR" ]; then
  echo "No Generator has been set"
  exit 1
fi

. ./versions.sh
VER=$CGNSLIB_VER

rm -rf lib/src/cgnslib-$VER
rm -rf lib/build/cgnslib-$VER
rm -rf lib/install/cgnslib-$VER

# CMake insists on building in a not-source directory
mkdir -p lib/src/cgnslib-$VER
cp -r build-cgnslib.cmake build-cgnslib.sh build-gcc-solver.sh \
    changelog CMakeLists.txt cmake_uninstall.cmake.in \
    create-dirExt-prop-solver.sh create-paths-pri-solver.sh \
    fortran_test/ install.lyx install.txt license.txt readme.lyx \
    readme.txt src/ versions.sh lib/src/cgnslib-$VER

# "-DCGNS_RPMBUILD:BOOL=ON"'s only purpose in life at the moment is to
# disable RPATH fiddling in CMakeLists.txt. See also:
#
#   https://stackoverflow.com/questions/37683526/linking-runtime-library-for-test-with-cmake and
#   https://gitlab.kitware.com/cmake/community/wikis/doc/cmake/RPATH-handling
#
ctest -S build-cgnslib.cmake -DCONF_DIR:STRING=release \
    "-DCTEST_CMAKE_GENERATOR:STRING=${GENERATOR}" "-DCGNS_RPMBUILD:BOOL=ON" \
    -C Release -VV -O ${SGEN}-cgnslib-release.log

# See Fastmech-BMI/bin/build-gcc-solver.sh. Might not be necessary for
# RPM build.
./create-paths-pri-solver.sh > paths.pri
./create-dirExt-prop-solver.sh > dirExt.prop


%install
rm -rf $RPM_BUILD_ROOT
# no conventional `install' target, so we have to simulate that
mkdir -p $RPM_BUILD_ROOT%{_bindir} $RPM_BUILD_ROOT%{_includedir} $RPM_BUILD_ROOT%{_libdir}
install lib/install/cgnslib-%{version}/release/bin/* $RPM_BUILD_ROOT%{_bindir}
install lib/install/cgnslib-%{version}/release/include/*.h $RPM_BUILD_ROOT%{_includedir}
install lib/install/cgnslib-%{version}/release/include/cgnsBuild.defs $RPM_BUILD_ROOT%{_includedir}
install lib/install/cgnslib-%{version}/release/lib/*.so.* $RPM_BUILD_ROOT%{_libdir}
(cd $RPM_BUILD_ROOT%{_libdir} && ln -s libcgns.so.3.2 libcgns.so)
find $RPM_BUILD_ROOT -name '*.la' -exec rm -f {} ';'


%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig


%files
%doc
%{_bindir}/*
%{_libdir}/*.so.*

%files devel
%doc
%{_includedir}/*
%{_libdir}/*.so


%changelog
* Wed Dec 19 2018 Andrew Stephen Halper <ashalper@usgs.gov> - 3.2.1-3
- Built on CentOS 7.
