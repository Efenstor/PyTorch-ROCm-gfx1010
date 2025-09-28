#!/bin/sh
# copyleft 2025 Efenstor

# Run with -h or -? to display help

# Defaults
# (use anything for True or nothing for False)
reserve_vram=0.5
gc_threshold=0.9
max_split_size=512
preview_method=auto
auto_launch=1
garbage_collector=1
attention=0
profile_path="/sys/class/drm/card0/device/pp_power_profile_mode"
profile_compute=5  # cat /sys/class/drm/card0/device/pp_power_profile_mode
profile_default=0
cache_classic=
interactive=
lowvram=
dsm=
custom=

get_current_profile() {
  echo $(cat "$1" | sed -n "s/ *\([0-9]*\).*\*.*/\1/p")
}

get_current_profile_name() {
  echo $(cat "$1" | sed -n "s/.* \(.*\)\*.*/\1/p")
}

uninitialize() {
  if [ "$new_profile" ]; then
    echo "Restoring the old amdgpu profile: $prev_profile ($prev_profile_name)"
    echo $prev_profile > "$profile_path"
  fi
}

catchbreak() {
  uninitialize
  exit 1
}

cd "$(dirname $0)"

# Parse the named parameters
optstr="?hildagr:t:s:p:q:voc:"
while getopts $optstr opt
do
  case "$opt" in
    h|\?) help=1 ;;
    i) interactive=1 ;;
    l) lowvram="--lowvram" ;;
    d) dsm="--disable-smart-memory" ;;
    a) auto_launch= ;;
    g) garbage_collector= ;;
    r) reserve_vram="$OPTARG" ;;
    t) gc_threshold="$OPTARG" ;;
    s) max_split_size="$OPTARG" ;;
    p) preview_method="$OPTARG" ;;
    q) attention="$OPTARG" ;;
    v) cache_classic="--cache-classic" ;;
    o) switch_profile=1 ;;
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
  echo "-l: use --lowvram (makes everything very slow but fights OOM errors)"
  echo "-d: disable smart memory (same as -l but different strategy)"
  echo "-a: don't auto-launch browser"
  echo "-g: don't use garbage collector"
  echo "-r: reserve_vram size (GB, default=$reserve_vram)"
  echo "-t: garbage collector threshold (0..1 VRAM, default=$gc_threshold)"
  echo "-s: garbage collector max_split_size size (MB, default=$max_split_size)"
  echo "-p: preview method (default=$preview_method)"
  echo "-q: specify attention method:"
  echo "    0 = split-cross-attention (default)"
  echo "    1 = quad-cross-attention"
  echo "    2 = sage-attention"
  echo "    3 = pytorch-cross-attention"
  echo "    4 = flash-attention"
  echo "-v: use classic (aggressive) caching"
  echo "-o: switch the amdgpu profile to COMPUTE, see NOTE 1 below (default=$profile_compute)"
  echo "-c: custom parameters to be added to the ComfyUI command line"
  echo "
NOTE 1: For this option to work the profile file must be user-writable.
  You can acheive this by making a startup script with the following command:
  chmod a+w $profile_path"
  echo
  exit
fi

# Replace bool with actual parameters
if [ "$garbage_collector" ]; then
  garbage_collector="PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:$gc_threshold,max_split_size_mb:$max_split_size,expandable_segments:True"
fi
if [ "$auto_launch" ]; then
  auto_launch="--auto-launch"
fi

# Replace attention number with the actual parameter
case "$attention" in
  0) attention="--use-split-cross-attention" ;;
  1) attention="--use-quad-cross-attention" ;;
  2) attention="--use-sage-attention" ;;
  3) attention="--use-pytorch-cross-attention" ;;
  4) attention="--use-flash-attention" ;;
esac

# Interactive questions
if [ "$interactive" ]; then
  read -p "Use --lowvram? (very slow but helps against OOM errors) y/N " a
  if [ "$a" = 'y' ]; then
    lowvram="--lowvram"
  else
    lowvram=
  fi
fi

# Try to get the current profile
if [ "$switch_profile" ]; then
  echo "Using amdgpu profile path: $profile_path"
  prev_profile=$(get_current_profile "$profile_path")
  if [ "$prev_profile" ]; then
    prev_profile_name=$(get_current_profile_name "$profile_path")
    echo "Current amdgpu profile: $prev_profile ($prev_profile_name)"
    echo "Setting amdgpu profile: $profile_compute (COMPUTE)"
    echo $profile_compute > "$profile_path"
    new_profile=$(get_current_profile "$profile_path")
    if [ $new_profile -eq $profile_compute ]; then
      echo "COMPUTE profile was set successfully"
    else
      echo "COMPUTE profile cannot be set"
      new_profile=
    fi
  fi
fi

# Execute
trap "catchbreak" INT
env $garbage_collector \
  bin/python ComfyUI/main.py \
  $lowvram \
  $dsm \
  --reserve-vram $reserve_vram \
  --preview-method $preview_method \
  --fast \
  --disable-xformers \
  $cache_classic \
  $attention \
  $custom \
  $auto_launch
uninitialize
