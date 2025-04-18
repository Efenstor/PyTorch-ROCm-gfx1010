# PyTorch for Radeon RX 5600/5700 (gfx1010) on Debian 12

**Contents:**

1. [Pre-built wheels](#pre-built-wheels)
2. [Introduction](#introduction)
3. [Requirements](#requirements)
4. [Prepare](#prepare)
5. [Build](#build)
6. [Troubleshooting](#troubleshooting)
7. [TorchVision](#torchvision)
8. [TorchAudio](#torchaudio)
11. [Extras](#extras)

For usage examples (chaiNNer, ComfyUI, etc.) see the \`usage\` directory.

## Pre-built wheels

Pre-built wheels of PyTorch 2.6.0, TorchVision 0.2.1 and TorchAudio 2.6.0 (built for ROCm 6.3.4 and Python 3.11) are located in the \`prebuilt\` directory.

There is no guarantee that those will work with your particular configuration of video card, ROCm version, Python version, PyTorch version, kernel version, etc.

For best results use the following instructions to build those wheels yourself.

## Introduction

These instructions are the result of the efforts to make PyTorch work with unofficially-supported AMD gfx1010 GPUs (Radeon RX 5000 series) on Debian 12.

Unfortunately **none** of the pre-compiled binaries work for gfx1010 GPUs. Anecdotally they did work in the past but no more, even with not-so-fresh versions of PyTorch.

Using various tricks, such as setting the `HSA_OVERRIDE_GFX_VERSION=10.3.0` environment variable or using older versions of ROCm, PyTorch or kernel do not work as well causing either:

1. \`Compile with 'TORCH_USE_HIP_DSA' to enable device-side assertions\` message
2. Crashing X11 every time calculations begin
3. Calculations going on forever with 100% GPU load and no characteristic noises coming out of the GPU, which means no actual work is being done

The only working solution seems to be is to build PyTorch and TorchVision from the source code with the support for gfx1010 architecture explicitly on.

The resulting Python wheels were tested with [chaiNNer](https://github.com/chaiNNer-org/chaiNNer) and [ComfyUI](https://github.com/comfyanonymous/ComfyUI) and both seem to work fine.

## Requirements

    build-essential
    clang
    cmake
    python3
    git
    ROCm (for ROCm build)

To begin with you have to install ROCm. Unfortunately you have to trust AMD here: although ROCm is open-source building it from the source is another enormous task. Good news is that despite the instructions from AMD there is no actual need to install the proprietary amdgpu driver (amdgpu-dkms) and that the upcoming Debian 13 (trixie) will have ROCm in its repositories out of the box.

Download and install *amdgpu-install* as described [here](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/install-methods/amdgpu-installer/amdgpu-installer-debian.html). Then execute `apt install rocm` as root.

Then install all the rest of the requirements using the usual `apt install`.

## Prepare

Create and activate a venv:

    python3 -m venv pytorch
    cd pytorch
    source bin/activate

Later to exit the venv execute `deactivate`.

## Build

The following instructions are given for PyTorch 2.6, when a new version arrives just replace 2.6 with the new numbers.

    git clone https://github.com/pytorch/pytorch.git --branch=release/2.6 --recurse-submodules pytorch-release-2.6-git
    cd pytorch-release-2.6-git
    pip install -r requirements.txt
    python3 tools/amd_build/build_amd.py
    MAX_JOBS=$(nproc) CMAKE_BUILD_PARALLEL_LEVEL=$(nproc) CMAKE_POLICY_VERSION_MINIMUM=3.5 PYTORCH_ROCM_ARCH=gfx1010 python3 setup.py bdist_wheel

The resulting wheel will be in the *dist* directory. Be patient, build takes a very long time even on modern 8-core CPUs.

To install the built wheel execute inside a venv:

    pip install pytorch-release-2.6-git/dist/torch-2.6.0a0+git1eba9b3-cp311-cp311-linux_x86_64.whl

## Troubleshooting

If you get \`all warnings being treated as errors\` messages then do:

    echo "set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=maybe-uninitialized -Wno-error=uninitialized -Wno-error=restrict")" >> third_party/fbgemm/CMakeLists.txt
    echo "set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=maybe-uninitialized -Wno-error=uninitialized -Wno-error=restrict")" >> third_party/fbgemm/CMakeLists.txt

If you get \`error: use of undeclared identifier 'CK_BUFFER_RESOURCE_3RD_DWORD'\` messages then you have to apply patches (read [here](https://github.com/ROCm/composable_kernel/issues/775#issuecomment-2725632592) about this issue):

    git apply --directory=third_party/composable_kernel patches/5465fcc9e25ab9828b9d34ce5d341a127ff8ea9e.patch
    git apply --directory=third_party/composable_kernel patches/88952b6d4e6bea810aaa4c063bdaf5b8252acb1c.patch
    git apply --directory=third_party/composable_kernel patches/3e23090b5b29d0eea3bbec0ee1b03a182894c831.patch

Remember that \`patches\` is a subdirectory in this repository, so replace it with your path.

If a patch cannot be applied it is probably not needed for your version of Torch (in my case `3e23090b5b29d0eea3bbec0ee1b03a182894c831.patch` could not be applied but the build still completed successfully).

## TorchVision

This built should be done in a venv with the previously built pytorch wheel installed.

    git clone https://github.com/pytorch/vision.git --branch=release/0.21 --recurse-submodules vision-release-0.21-git
    cd vision-release-0.21-git
    MAX_JOBS=$(nproc) CMAKE_BUILD_PARALLEL_LEVEL=$(nproc) CMAKE_POLICY_VERSION_MINIMUM=3.5 python3 setup.py bdist_wheel

The resulting wheel will be in the *dist* directory.

## TorchAudio

This built should be done in a venv with the previously built pytorch wheel installed.

    git clone https://github.com/pytorch/audio.git --branch=release/2.6 --recurse-submodules audio-release-2.6-git
    cd audio-release-2.6-git
    MAX_JOBS=$(nproc) CMAKE_BUILD_PARALLEL_LEVEL=$(nproc) CMAKE_POLICY_VERSION_MINIMUM=3.5 python3 setup.py bdist_wheel

The resulting wheel will be in the *dist* directory.

## Extras

### xformers

So far the attempts to build **xformers v0.0.29.post3** for ROCm gfx1010 were unsuccessful.

The main culprit is *composable_kernel_tiled*, which has no support for gfx1010, and although I manually added it to *include/ck/ck.hpp* and *include/ck_tile/core/config.hpp* I got stuck with a completely different errors, likely related to the versions of gcc/clang that are available in Debian 12.

### Torch for Vulkan

Torch can be successfully built with the Vulkan backend which in theory would allow it to run without ROCm, but in practice unlike PyTorch for ROCm it is not a drop-in replacement for PyTorch for CUDA and should be explicitly supported by the end-user software. Therefore the following instructions are more like a bonus for those who one day may find such a software.

Additional requirements:

    glslc

All the instructions are the same as for ROCm, except for the build command:

    MAX_JOBS=$(nproc) CMAKE_BUILD_PARALLEL_LEVEL=$(nproc) CMAKE_POLICY_VERSION_MINIMUM=3.5 USE_VULKAN=1 USE_VULKAN_SHADERC_RUNTIME=1 USE_VULKAN_WRAPPER=0 python3 setup.py bdist_wheel

If you get \`is not a member of ‘torch::jit::cuda’\` errors then apply patch:

    git apply patches/a72d9c3b7554b78a91a3d61b9041b3d1d7acf319.patch

Additional environment variables to try (untested):

    USE_VULKAN_FP16_INFERENCE=ON
    USE_VULKAN_RELAXED_PRECISION=ON
