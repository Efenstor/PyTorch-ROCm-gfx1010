# Using with ComfyUI

1. [Install](#install)
2. [Run](#run)
3. [Useful options](#useful-options)
4. [freedesktop integration](#freedesktop-integration)
5. [HIP out of memory (OOM) problems](#hip-out-of-memory-oom-problems)

## Install

Create and activate a venv:

    python3 -m venv comfyui
    cd comfyui

Clone the ComfyUI repository:

    git clone https://github.com/comfyanonymous/ComfyUI.git

Install your torch, torchvision and torchaudio:

    bin/pip install <torch.whl> <torchvision.whl> <torchaudio.whl>

Replace <torch.whl\> <torchvision.whl\> and <torchaudio.whl\> with paths to the wheels you built.

Install the ComfyUI requirements excluding torch, torchvision and torchaudio:

    grep -vEi "torch|torchvision|torchaudio" ComfyUI/requirements.txt | bin/pip install -r /dev/stdin

To simplify updating ComfyUI in the future you can use the \`comfyui_update.sh\` file from the \`comfyui_freedesktop\` directory, just copy it to the venv root directory and make it executable.

## Run

Run ComfyUI:

    PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512 bin/python ComfyUI/main.py --reserve-vram 0.9

## Useful options

1. KSampler preview while generating: *--preview-method auto*
2. Launch the default browser automatically: *--auto-launch*

For better previews download the [TAESD](https://github.com/madebyollin/taesd) encoders and decoders (taesd, taesdxl,taesd3, taef1) and put the *.pth* files into the *models/vae_approx* dir. You can also use these to decode latents.

## freedesktop integration

In the ***comfyui_freedesktop*** directory you can find the files needed for the freedesktop integration (desktop icon):

* *comfyui.svg*: copy to *~/.icons*
* *comfyui.sh*: copy to the comfyui venv root directory
* *comfyui.desktop*: copy to *~/.local/share/applications*, open and edit the Exec path (default is bin/comfyui)

If you don't need the browser auto-launch add *--no-auto-launch* to the Exec line in *comfyui.desktop*.

## HIP out of memory (OOM) problems

Radeon XT 5600/5700 cards are pretty low on memory (6 GB) yet there are options which may help:

* Turn on the HIP garbage collector, which cleans VRAM of unused fragments. It is controllable via an environment variable `PYTORCH_HIP_ALLOC_CONF`. For example: `PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512`, which means that the garbage collector will be activated once 90% of VRAM is full and the largest fragment size will be no larger than 512 MB.

* Stick to fp8 (8-bit) models (6.5 GB in size or smaller). Those are fast, more or less trouble-free and produce reasonable quality output.

* Use *VAE Decode Tiled* (tile size=128, overlap=64) instead of the normal *VAE Decode* (ComfyUI will switch to it automatically but only when VAE Decode fails and that takes time).

* Use the *--lowvram* option which shifts some computation to CPU, therefore expect greatly increased processing times. For some operations, such as conversion or combining models, you have to use the *--lowvram* option, otherwise you'll get the \`HIP out of memory\` message.

* Avoid PyTorch's internal cross attention (the *--use-pytorch-cross-attention* option), which seems to occupy additional uncounted VRAM. The solution is to use *--use-split-cross-attention* (may be faster in many cases) or *--use-quad-cross-attention* (default).

* If you are getting OOM's with *--use-split-cross-attention* try *--use-quad-cross-attention*.

