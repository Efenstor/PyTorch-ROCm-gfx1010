# Using with chaiNNer

If you have a new installation then run chaiNNer, let it download all the basic components but don't install any dependencies.

Then execute:

    cd <your_chaiNNer_directory>/python/python/bin
    ./chainner_pip install <torch.whl> <torchvision.whl>

Replace <torch.whl\> and <torchvision.whl\> with paths to the wheels you built.

After that run chaiNNer and install all the rest of the dependencies, PyTorch and TorchVision should already be marked as installed.

If you already ran chaiNNer before and installed all dependencies then before installing the wheels execute:

    ./chainner_pip uninstall torch torchvision