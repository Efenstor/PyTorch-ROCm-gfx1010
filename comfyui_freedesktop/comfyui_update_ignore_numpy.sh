#!/bin/sh

cd ComfyUI
git pull
grep -vEi "torch|torchvision|torchaudio|numpy" requirements.txt | ../bin/pip install -U -r /dev/stdin
