# Using with chaiNNer

If you have a new installation then run chaiNNer, let it download all the basic components but don't install any dependencies.

Then execute:

    cd <your_chaiNNer_directory>/python/python/bin
    ./chainner_pip install <torch.whl> <torchvision.whl> onnxruntime-gpu onnxoptimizer

Replace <torch.whl\> and <torchvision.whl\> with paths to the wheels you built.

After that run chaiNNer and install all the rest of the dependencies for PyTorch and NCNN.

Do not install the missing dependencies for ONNX, ONNX Runtime should remain marked as missing: unfortunately chaiNNer expects the *onnxruntime* package to be installed and not *onnxruntime-gpu*. Select the CUDA execution provider in the ONNX settings.

If you already ran chaiNNer before and installed all dependencies then before installing the wheels execute:

    ./chainner_pip uninstall torch torchvision onnxruntime

