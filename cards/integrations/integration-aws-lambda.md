---
id: integration-aws-lambda
title: Using uv with AWS Lambda
category: integrations
tags: [integration, docker, pip, installation, performance, ci]
source: https://docs.astral.sh/uv/guides/integration/aws-lambda/
related: [integration-docker, cmd-export, pip-install, project-workspaces, integration-fastapi]
---

## Summary

uv manages Python dependencies for AWS Lambda via two deployment paths: Docker container images
(multi-stage build with `uv export` + `uv pip install --target`) and zip archives (`uv pip install`
with `--python-platform` for cross-compilation). Both paths install dependencies into a flat
directory that Lambda can load directly.

## Syntax / Usage

```console
# Docker path — export requirements, install into LAMBDA_TASK_ROOT
uv export --frozen --no-emit-workspace --no-dev --no-editable -o requirements.txt
uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Zip path — cross-compile for Lambda's Linux runtime
uv pip install \
  --no-installer-metadata \
  --no-compile-bytecode \
  --python-platform x86_64-manylinux2014 \
  --python 3.13 \
  --target packages \
  -r requirements.txt

# Lambda layer path — use --prefix instead of --target
uv pip install \
  --no-installer-metadata \
  --no-compile-bytecode \
  --python-platform x86_64-manylinux2014 \
  --python 3.13 \
  --prefix packages \
  -r requirements.txt
```

## Details

### Docker container images

Use a multi-stage Dockerfile with `public.ecr.aws/lambda/python:<version>` as the base. The
pattern mirrors the Docker guide, but targets `LAMBDA_TASK_ROOT` (typically `/var/task`) rather
than a virtualenv.

Key environment variables in the builder stage:

- `UV_COMPILE_BYTECODE=1` — precompile `.pyc` files to improve cold-start performance.
- `UV_NO_INSTALLER_METADATA=1` — omit installer metadata for a deterministic layer.
- `UV_LINK_MODE=copy` — required when the uv cache is on a different filesystem (bind mount).

The `uv export --no-emit-workspace` flag excludes local workspace packages from the exported
requirements. This keeps the dependency install layer cache-stable: it only invalidates when
`pyproject.toml` or `uv.lock` change, not when application source changes.

For workspace projects with local packages, run a second `uv export` (without
`--no-emit-workspace`) in a separate `RUN` step to install the workspace members. Separating
the two steps preserves caching for third-party dependencies.

For ARM-based Lambda runtimes, replace `public.ecr.aws/lambda/python:3.13` with
`public.ecr.aws/lambda/python:3.13-arm64`.

### Zip archives

Zip archives are limited to 250 MB but are simpler to deploy. Because the build machine may not
run the same Linux variant as Lambda, pass `--python-platform x86_64-manylinux2014` (or
`aarch64-manylinux2014` for ARM) to download Linux-compatible wheels regardless of the host OS.
Also pass `--python <version>` to target the correct Python ABI.

Use `--target packages` to install into a flat directory, then zip it and add the application
code to the same archive.

### Lambda layers (zip)

Lambda layers separate dependencies from application code, allowing dependency layers to be
reused across application deployments. Use `--prefix packages` instead of `--target packages`
when building layer content. After install, the layer zip must follow the layout Lambda expects:

```console
python/
  lib/
    python3.13/
      site-packages/
        <packages>
```

Copy `packages/lib` into a `python/` directory and zip that. Attach the published layer ARN to
the function via `aws lambda update-function-configuration --layers`.

## Examples

### Docker image (single package, no workspace)

```dockerfile
FROM ghcr.io/astral-sh/uv:0.11.24 AS uv

FROM public.ecr.aws/lambda/python:3.13 AS builder

ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_INSTALLER_METADATA=1
ENV UV_LINK_MODE=copy

RUN --mount=from=uv,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv export --frozen --no-emit-workspace --no-dev --no-editable -o requirements.txt && \
    uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

FROM public.ecr.aws/lambda/python:3.13

COPY --from=builder ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}
COPY ./app ${LAMBDA_TASK_ROOT}/app

CMD ["app.main.handler"]
```

### Docker image (workspace with local library)

```dockerfile
FROM ghcr.io/astral-sh/uv:0.11.24 AS uv

FROM public.ecr.aws/lambda/python:3.13 AS builder

ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_INSTALLER_METADATA=1
ENV UV_LINK_MODE=copy

# Install third-party dependencies (cache-stable layer)
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv export --frozen --no-emit-workspace --no-dev --no-editable -o requirements.txt && \
    uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Install workspace members (separate layer, invalidates on library changes)
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=library,target=library \
    uv export --frozen --no-dev --no-editable -o requirements.txt && \
    uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

FROM public.ecr.aws/lambda/python:3.13

COPY --from=builder ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}
COPY ./app ${LAMBDA_TASK_ROOT}/app

CMD ["app.main.handler"]
```

### Zip archive (cross-compiled for x86_64 Lambda)

```console
$ uv export --frozen --no-dev --no-editable -o requirements.txt
$ uv pip install \
   --no-installer-metadata \
   --no-compile-bytecode \
   --python-platform x86_64-manylinux2014 \
   --python 3.13 \
   --target packages \
   -r requirements.txt
$ cd packages && zip -r ../package.zip . && cd ..
$ zip -r package.zip app
$ aws lambda create-function \
   --function-name myFunction \
   --runtime python3.13 \
   --zip-file fileb://package.zip \
   --handler app.main.handler \
   --role arn:aws:iam::111122223333:role/service-role/my-lambda-role
```

### Lambda layer (zip, x86_64)

```console
$ uv export --frozen --no-dev --no-editable -o requirements.txt
$ uv pip install \
   --no-installer-metadata \
   --no-compile-bytecode \
   --python-platform x86_64-manylinux2014 \
   --python 3.13 \
   --prefix packages \
   -r requirements.txt
$ mkdir python && cp -r packages/lib python/
$ zip -r layer_content.zip python
$ aws lambda publish-layer-version --layer-name dependencies-layer \
   --zip-file fileb://layer_content.zip \
   --compatible-runtimes python3.13 \
   --compatible-architectures "x86_64"
$ aws lambda update-function-configuration --function-name myFunction \
   --layers "arn:aws:lambda:region:111122223333:layer:dependencies-layer:1"
```

## Caveats / Common Mistakes

- **Omit `--no-emit-workspace` when workspace members are needed.** The flag excludes local
  packages from the exported requirements. For projects with workspace dependencies, run a
  separate export step without the flag to include them.
- **Use `--prefix` not `--target` for Lambda layers.** `--target` flattens packages into the
  directory root; `--prefix` preserves the `lib/pythonX.Y/site-packages/` structure that Lambda
  layers require.
- **Cross-compile for the correct architecture.** Building on macOS or a different Linux variant
  without `--python-platform manylinux2014` will produce wheels that may not run on Lambda.
  For ARM Lambda, use `aarch64-manylinux2014`.
- **Zip archive size limit.** Zip archives are capped at 250 MB (unzipped). Use Docker container
  images for larger dependency sets.
- **Default Lambda handler.** The AWS Management Console defaults to `lambda_function.lambda_handler`.
  If the entrypoint differs (e.g., `app.main.handler`), it must be set explicitly on function
  creation or updated afterward.

## See Also

- integration-docker
- cmd-export
- pip-install
- project-workspaces
- integration-fastapi
