#!/bin/sh

reserve_vram=0.9
max_split_size=512

cd "$(dirname $0)"

read -p "Use --lowvram? (needed only if you get the \`HIP out of memory\` errors) y/N " a
if [ "$a" = 'y' ]; then
  lowvmem="--lowvram"
fi

PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:$reserve_vram,max_split_size_mb:$max_split_size \
  bin/python ComfyUI/main.py $lowvmem --reserve-vram $reserve_vram --preview-method auto --auto-launch

