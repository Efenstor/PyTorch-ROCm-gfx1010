#!/bin/sh

cd ComfyUI
git pull
grep -vEi "torch|torchvision|torchaudio" requirements.txt | ../bin/pip install -U -r /dev/stdin
