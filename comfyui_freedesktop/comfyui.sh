#!/bin/sh
# copyleft 2025 Efenstor

# Run with -h or -? to display help

# Defaults
# (use anything for True or nothing for False)
reserve_vram=0.9
max_split_size=512
preview_method=auto
auto_launch=1
garbage_collector=1
attention="--use-split-cross-attention"
interactive=
lowvram=
custom=

cd "$(dirname $0)"

# Parse the named parameters
optstr="?hilagr:s:p:qc:"
while getopts $optstr opt
do
  case "$opt" in
    h|\?) help=1 ;;
    i) interactive=1 ;;
    l) lowvram="--lowvram" ;;
    a) auto_launch= ;;
    g) garbage_collector= ;;
    r) reserve_vram="$OPTARG" ;;
    s) max_split_size="$OPTARG" ;;
    p) preview_method="$OPTARG" ;;
    q) attention="--use-quad-cross-attention" ;;
    c) custom="$OPTARG" ;;
    :) echo "Missing argument for -$OPTARG" >&2
       exit 1 ;;
  esac
done
shift $(expr $OPTIND - 1)

# Help
if [ "$help" ]; then
  echo
  echo "Usage: $0 [arguments]"
  echo
  echo "Arguments:"
  echo "-h or -?: show this help"
  echo "-i: interactive mode"
  echo "-l: use --lowvram (needed only if you get the \`HIP out of memory\` errors)"
  echo "-a: don't auto-launch browser"
  echo "-g: don't use garbage collector"
  echo "-r: garbage collector reserve_vram size (default=$reserve_vram)"
  echo "-s: garbage collector max_split_size size (default=$max_split_size)"
  echo "-p: preview method (default=$preview_method)"
  echo "-q: use sub-quadratic cross attention (may be slower)"
  echo "-c: custom parameters to be added to the ComfyUI command line"
  echo
  exit
fi

# Replace bool with actual parameters
if [ "$garbage_collector" ]; then
  garbage_collector="PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:$reserve_vram,max_split_size_mb:$max_split_size,expandable_segments:True"
fi
if [ "$auto_launch" ]; then
  auto_launch="--auto-launch"
fi

# Interactive questions
if [ "$interactive" ]; then
  read -p "Use --lowvram? (needed only if you get the \`HIP out of memory\` errors) y/N " a
  if [ "$a" = 'y' ]; then
    lowvram="--lowvram"
  else
    lowvram=
  fi
fi

# Execute
env $garbage_collector bin/python ComfyUI/main.py \
  $lowvram \
  --reserve-vram $reserve_vram \
  --preview-method $preview_method \
  --fp8_e4m3fn-unet --fp8_e4m3fn-text-enc --bf16-vae \
  --fast cublas_ops \
  $attention \
  $custom \
  $auto_launch

