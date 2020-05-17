# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Pkg; Pkg.instantiate()
using BinaryBuilder

name = "HOOMDBlue"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/glotzerlab/hoomd-blue.git",
        "30b00532c427626b91ea91cd9403a9ed9a4abd7b"
    ),
    GitSource(
        "https://github.com/USCiLab/cereal.git",
        "34eb6f6bd6783018354c7043d5d6aa2eec4e4dbe"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cereal
mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DJUST_INSTALL_CEREAL=TRUE
cmake --build . --target install -j ${nproc}

cd ..
rm -rf build

cd $WORKSPACE/srcdir/hoomd-blue
git submodule update --init
mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=$prefix/bin/python3 \
    -DENABLE_MPI=ON \
    -DENABLE_GPU=ON \
    -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc
cmake --build . --target install -j ${nproc}

cd ..
install_license LICENSE
rm -rf build

LIBNVBLAS_PATH=$(find ${WORKSPACE}/destdir/ -name libnvblas.so)
cd $(dirname ${LIBNVBLAS_PATH})
cat << EOF > nvblas.conf
NVBLAS_CPU_BLAS_LIB $WORKSPACE/lib/libopenblas64_.so
EOF

cd $WORKSPACE/destdir
mv hoomd/include/* include/
rm -rf hoomd/include
mv hoomd lib/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("_md", :libmd, "lib/hoomd/md"),
    LibraryProduct("_dem", :libdem, "lib/hoomd/dem"),
    LibraryProduct("_mpcd", :libmpcd, "lib/hoomd/mpcd"),
    LibraryProduct("_example_plugin", :libplugin, "lib/hoomd/example_plugin"),
    LibraryProduct("_metal", :libmetal, "lib/hoomd/metal"),
    LibraryProduct("_hpmc", :libhpmc, "lib/hoomd/hpmc"),
    LibraryProduct("_hoomd", :libhoomd, "lib/hoomd")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CUDA_full_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Eigen_jll"),
    Dependency("OpenBLAS_jll"),
    Dependency("OpenMPI_jll"),
    Dependency("pybind11_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
