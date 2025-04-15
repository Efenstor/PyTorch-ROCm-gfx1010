# Using with ComfyUI

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

Run ComfyUI:

    PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512 bin/python ComfyUI/main.py --reserve-vram 0.9 --use-pytorch-cross-attention

If you want to launch the default browser automatically add *--auto-launch*.

Note that Radeon XT 5600/5700 are pretty low on memory (6 GB) so not every model or architecture will work. In some cases you'll get the \`HIP out of memory\` message or a crash and adding *--lowmem* or *--nomem* does not seem to help much.