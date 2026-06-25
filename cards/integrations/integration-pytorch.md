---
id: integration-pytorch
title: Using uv with PyTorch
category: integrations
tags: [integration, index, dependency, config, installation]
source: https://docs.astral.sh/uv/guides/integration/pytorch/
related: [config-package-indexes, dep-sources, dep-optional, dep-platform-environments, pip-install]
---

## Summary

PyTorch uses dedicated package indexes and local version specifiers (e.g., `2.11.0+cu130`) to
distinguish CPU-only, CUDA, ROCm, and Intel GPU builds. uv supports full control over which
index is used per platform and per accelerator via `tool.uv.index`, `tool.uv.sources`, and the
`--torch-backend` flag on the pip interface.

## Syntax / Usage

```toml
# Declare the PyTorch index (explicit = true keeps it scoped to torch packages)
[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"
explicit = true

# Point torch and torchvision at that index
[tool.uv.sources]
torch = [{ index = "pytorch-cpu" }]
torchvision = [{ index = "pytorch-cpu" }]
```

```shell
# pip interface with --index-url
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

# pip interface with automatic accelerator detection
uv pip install torch --torch-backend=auto
```

## Details

**Why a dedicated index?**

PyTorch publishes most of its wheels to its own index rather than PyPI. Accelerator variants are
encoded as local version specifiers:

| Variant | Local version | Index URL |
|---------|--------------|-----------|
| CPU-only | `+cpu` | `https://download.pytorch.org/whl/cpu` |
| CUDA 11.8 | `+cu118` | `https://download.pytorch.org/whl/cu118` |
| CUDA 12.6 | `+cu126` | `https://download.pytorch.org/whl/cu126` |
| CUDA 12.8 | `+cu128` | `https://download.pytorch.org/whl/cu128` |
| CUDA 13.0 | `+cu130` | `https://download.pytorch.org/whl/cu130` |
| ROCm 7.2 | `+rocm7.2` | `https://download.pytorch.org/whl/rocm7.2` |
| Intel XPU | `+xpu` | `https://download.pytorch.org/whl/xpu` |

**`explicit = true` on the index**

Always set `explicit = true` on PyTorch indexes so uv only uses them for packages explicitly
pointed there via `tool.uv.sources`. Without it, uv may attempt to resolve generic packages
(e.g., `jinja2`) against the PyTorch index.

**Platform markers in `tool.uv.sources`**

PyTorch does not publish CUDA, ROCm, or XPU builds for macOS. Use `sys_platform` markers to
restrict those indexes to Linux (and Windows where applicable), letting uv fall back to PyPI on
macOS:

```toml
[tool.uv.sources]
torch = [
  { index = "pytorch-cu130", marker = "sys_platform == 'linux' or sys_platform == 'win32'" },
]
```

You can also combine multiple source entries to pin different indexes per platform:

```toml
[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", marker = "sys_platform != 'linux'" },
  { index = "pytorch-cu130", marker = "sys_platform == 'linux'" },
]
```

**Optional-dependency extras for accelerator selection**

To let users toggle the accelerator at install time (e.g., `uv sync --extra cpu` vs.
`uv sync --extra cu130`), declare each variant as an optional dependency and mark them as
conflicting so they cannot be installed simultaneously:

```toml
[tool.uv]
conflicts = [
  [{ extra = "cpu" }, { extra = "cu130" }],
]

[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", extra = "cpu" },
  { index = "pytorch-cu130", extra = "cu130" },
]
```

**`--torch-backend` / `UV_TORCH_BACKEND` (pip interface only)**

Available in the `uv pip` interface. With `--torch-backend=auto` uv detects the installed CUDA
driver, AMD GPU, or Intel GPU and selects the most compatible PyTorch index automatically. With
a specific value (e.g., `--torch-backend=cu130`) it targets that exact backend. This flag is not
available in the project interface (`uv sync`, `uv lock`).

**Default behavior without explicit index**

Running `uv add torch` without any index configuration installs from PyPI: CPU-only wheels on
Windows and macOS, and CUDA-accelerated wheels on Linux (targeting the latest CUDA, CUDA 13.0 as
of PyTorch 2.11.0).

## Examples

**CPU-only on all platforms:**

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.14.0"
dependencies = ["torch>=2.11.0", "torchvision>=0.26.0"]

[tool.uv.sources]
torch = [{ index = "pytorch-cpu" }]
torchvision = [{ index = "pytorch-cpu" }]

[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"
explicit = true
```

**CUDA on Linux, CPU on macOS/Windows:**

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.14.0"
dependencies = ["torch>=2.11.0", "torchvision>=0.26.0"]

[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", marker = "sys_platform != 'linux'" },
  { index = "pytorch-cu130", marker = "sys_platform == 'linux'" },
]
torchvision = [
  { index = "pytorch-cpu", marker = "sys_platform != 'linux'" },
  { index = "pytorch-cu130", marker = "sys_platform == 'linux'" },
]

[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"
explicit = true

[[tool.uv.index]]
name = "pytorch-cu130"
url = "https://download.pytorch.org/whl/cu130"
explicit = true
```

**Accelerator via extras (user-selectable):**

```toml
[project.optional-dependencies]
cpu  = ["torch>=2.11.0", "torchvision>=0.26.0"]
cu130 = ["torch>=2.11.0", "torchvision>=0.26.0"]

[tool.uv]
conflicts = [[{ extra = "cpu" }, { extra = "cu130" }]]

[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", extra = "cpu" },
  { index = "pytorch-cu130", extra = "cu130" },
]
torchvision = [
  { index = "pytorch-cpu", extra = "cpu" },
  { index = "pytorch-cu130", extra = "cu130" },
]

[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"
explicit = true

[[tool.uv.index]]
name = "pytorch-cu130"
url = "https://download.pytorch.org/whl/cu130"
explicit = true
```

```shell
uv sync --extra cpu      # install CPU-only torch
uv sync --extra cu130    # install CUDA 13.0 torch
```

**pip interface:**

```shell
# Explicit index
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Automatic accelerator detection
uv pip install torch --torch-backend=auto

# Specific backend via env var
UV_TORCH_BACKEND=cu130 uv pip install torch torchvision
```

**ROCm (Linux only, requires triton packages):**

```toml
dependencies = [
  "torch>=2.11.0",
  "torchvision>=0.26.0",
  "pytorch-triton-rocm>=3.5.1 ; sys_platform == 'linux'",
  "triton-rocm>=3.6.0 ; sys_platform == 'linux'",
]

[tool.uv.sources]
torch                = [{ index = "pytorch-rocm", marker = "sys_platform == 'linux'" }]
torchvision          = [{ index = "pytorch-rocm", marker = "sys_platform == 'linux'" }]
pytorch-triton-rocm  = [{ index = "pytorch-rocm", marker = "sys_platform == 'linux'" }]
triton-rocm          = [{ index = "pytorch-rocm", marker = "sys_platform == 'linux'" }]

[[tool.uv.index]]
name = "pytorch-rocm"
url  = "https://download.pytorch.org/whl/rocm7.2"
explicit = true
```

## Caveats / Common Mistakes

- Omitting `explicit = true` on a PyTorch index causes uv to use it as a general-purpose
  index, which can resolve unrelated packages from it unexpectedly.
- CUDA and ROCm builds are not published for macOS. Enabling a CUDA extra (e.g., `--extra cu130`)
  on macOS will fail; use platform markers or separate extras to guard against this.
- ROCm support requires `pytorch-triton-rocm` and `triton-rocm` from the same PyTorch ROCm
  index. Forgetting these will result in an incomplete or broken ROCm installation.
- Intel XPU builds require `triton-xpu` from the XPU index.
- `--torch-backend` is only available on the `uv pip` interface. It has no effect in
  `uv sync` or `uv lock`.
- Some features (e.g., `--torch-backend`) require uv 0.5.3 or later. Upgrade uv before
  configuring PyTorch.

## See Also

- config-package-indexes
- dep-sources
- dep-optional
- dep-platform-environments
- pip-install
