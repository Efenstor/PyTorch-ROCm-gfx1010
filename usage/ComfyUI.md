# Using with ComfyUI

1. [Install](install)
2. [Run](run)
3. [HIP out of memory problems](hip-out-of-memory-problems)

## Install

Create and activate a venv:

    python3 -m venv comfyui
    cd comfyui

Clone the ComfyUI repository:

    git clone https://github.com/comfyanonymous/ComfyUI.git

Open the `ComfyUI/requirements.txt` file in a text editor and comment out *torch*, *torchvision* and *torchaudio* (keep *torchsde*):

    #torch
    torchsde
    #torchvision
    #torchaudio

Install your torch, torchvision and torchaudio:

    bin/pip install <torch.whl> <torchvision.whl> <torchaudio.whl>

Replace <torch.whl\> <torchvision.whl\> and <torchaudio.whl\> with paths to the wheels you built.

Install the rest of the requirements:

    bin/pip install -r ComfyUI/requirements.txt

## Run

Run ComfyUI:

    PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512 bin/python ComfyUI/main.py --reserve-vram 0.9

If you want to launch the default browser automatically add *--auto-launch*.

## HIP out of memory problems

Radeon XT 5600/5700 cards are pretty low on memory (6 GB) yet there are options which may help.

First of all, stick to fp8 (8-bit) models (6.5 GB in size or smaller). Those are fast, more or less trouble-free and produce reasonable quality output.

### Turn on garbage collector

First of all turn on the HIP garbage collector, it cleans VRAM of unused fragments. It is controllable via an environment variable `PYTORCH_HIP_ALLOC_CONF`. For example:

    PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

In this example the garbage collector will be activated once 90% of VRAM is full and the largest fragment size will be no larger than 512 MB.

The second option is to use the *--lowvram* option which shifts some computation to CPU, therefore expect greatly increased processing times, but at least in theory you won't have the \`HIP out of memory\` messages.

### PyTorch cross attention

Using PyTorch's internal cross attention (the *--use-pytorch-cross-attention* option) seems to occupy additional uncounted VRAM which may result in the \`HIP out of memory\` messages. The solution is to use *--use-split-cross-attention* or *--use-quad-cross-attention* (default).
