# HOOMDBlueBuilder

Builder for [HOOMD-blue](https://github.com/glotzerlab/hoomd-blue) using
[BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).
currently builds the `next` branch of HOOMD-blue for the following platforms:

 - Linux (`x86_64`)

with MPI and CUDA support (it assumes you have a CUDA-enabled GPU).

## Usage

Simply clone the repository and run (you need [Julia](https://julialang.org/)
installed):

```
$ julia --project=. build_tarballs.jl
```
