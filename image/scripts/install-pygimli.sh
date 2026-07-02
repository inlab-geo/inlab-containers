#!/bin/bash
set -euxo pipefail

mkdir -p /opt/gimli
cd /opt/gimli

git clone https://github.com/gimli-org/gimli.git

python -m pip install \
    sphinx \
    sphinx-book-theme \
    sphinx-design \
    sphinx-togglebutton \
    myst-nb \
    sphinx-gallery \
    pypandoc \
    sphinxcontrib-mermaid \
    sphinx-copybutton \
    pygccxml \
    pyplusplus

if [[ -f /opt/gimli/gimli/dev_requirements.txt ]]; then
    python -m pip install -r /opt/gimli/gimli/dev_requirements.txt
fi

mkdir -p /opt/gimli/build

mkdir -p /opt/gimli/thirdParty/src/triangle
cd /opt/gimli/thirdParty/src/triangle
curl -L -o triangle.zip http://www.netlib.org/voronoi/triangle.zip
unzip -o triangle.zip
TRIANGLE_CFLAGS=(-std=gnu89 -O -DTRILIBRARY -DNO_TIMER -fPIC)
case "$(uname -m)" in
    x86_64|amd64|i386|i686)
        # Triangle's LINUX block adjusts x87 FPU precision for 80x86. On ARM64
        # the same block trips SIGFPE in exactinit(), killing PyGIMLi notebooks.
        TRIANGLE_CFLAGS+=(-DLINUX)
        ;;
esac
cc "${TRIANGLE_CFLAGS[@]}" -c triangle.c
ar r libtriangle.a triangle.o

GCC_VERSION=$(gcc -dumpversion)
DIST_DIR="/opt/gimli/thirdParty/dist-GNU-${GCC_VERSION}-64"
mkdir -p "${DIST_DIR}/lib" "${DIST_DIR}/include"
cp libtriangle.a "${DIST_DIR}/lib/"
cp triangle.h "${DIST_DIR}/include/"

cd /opt/build-tmp
curl -LO https://archives.boost.io/release/1.87.0/source/boost_1_87_0.tar.gz
tar xzf boost_1_87_0.tar.gz
cd boost_1_87_0
./bootstrap.sh --with-python=python3.12
./b2 --with-python python=3.12 link=shared install
ldconfig

PY_INCLUDE=$(python -c "import sysconfig; print(sysconfig.get_path('include'))")

cd /opt/gimli/build
which castxml
castxml --version

cmake ../gimli \
    -DBOOST_ROOT=/usr/local \
    -DPYVERSION=3.12 \
    -DPython_EXECUTABLE=/usr/bin/python3.12 \
    -DPython_INCLUDE_DIR="${PY_INCLUDE}" \
    -DCASTXML_EXECUTABLE=/usr/bin/castxml \
    -DTriangle_INCLUDE_DIR="${DIST_DIR}/include" \
    -DTriangle_LIBRARIES="${DIST_DIR}/lib/libtriangle.a"
make -j"$(nproc)" gimli
make -j"$(nproc)" pygimli

echo /opt/gimli/build/lib > /etc/ld.so.conf.d/gimli.conf
ldconfig

SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")
echo /opt/gimli/gimli > "${SITE_PACKAGES}/gimli-source.pth"

PYTHONPATH=/opt/gimli/gimli LD_LIBRARY_PATH=/opt/gimli/build/lib python -c 'import pygimli as pg; print(pg.__version__)'
