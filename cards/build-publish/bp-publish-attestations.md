---
id: bp-publish-attestations
title: PEP 740 publish attestations
category: build-publish
tags: [publish, build, authentication, index]
source: https://docs.astral.sh/uv/guides/package/#uploading-attestations-with-your-package
related: [bp-build-publish, bp-trusted-publishing, integration-github-actions, bp-publish-custom-index, config-index-auth]
---

## Summary

`uv publish` automatically discovers and uploads PEP 740 attestations alongside distributions,
enabling consumers to verify that packages were produced from a known source. Attestations must
be generated separately before publishing; uv only handles uploading them.

## Syntax / Usage

```bash
uv publish                       # uploads distributions + any matching attestations
uv publish --no-attestations     # skip attestation upload
UV_PUBLISH_NO_ATTESTATIONS=1 uv publish   # same, via env var
```

## Details

[PEP 740](https://peps.python.org/pep-0740/) defines a standard for package publish attestations —
cryptographic statements that bind a distribution file to the build environment that produced it.
PyPI and other indexes that implement PEP 740 can expose this provenance metadata to package consumers.

When `uv publish` collects files to upload (defaulting to the `dist/` directory), it selects
wheels, source distributions, and their paired attestation files. The naming convention for an
attestation file is the distribution filename with `.publish.attestation` appended:

```
dist/hello_world-1.0.0-py3-none-any.whl
dist/hello_world-1.0.0-py3-none-any.whl.publish.attestation
dist/hello_world-1.0.0.tar.gz
dist/hello_world-1.0.0.tar.gz.publish.attestation
```

uv matches each attestation to its distribution by filename and uploads the pair together.
If no `.publish.attestation` file is present for a distribution, that distribution is uploaded
without an attestation — the flag is only needed to suppress uploading attestations that are
present.

Attestation generation is out of scope for `uv publish`. In practice, attestations are produced
by CI tooling (e.g. the GitHub Actions `attest-build-provenance` action) and written into `dist/`
before the publish step runs.

## Examples

Typical GitHub Actions publish job with attestation generation:

```yaml
- name: Build
  run: uv build

- name: Attest
  uses: actions/attest-build-provenance@v2
  with:
    subject-path: dist/*

- name: Publish
  run: uv publish
```

Disable attestation upload when the target index does not support PEP 740:

```bash
uv publish --no-attestations
```

Or via environment variable (useful in CI config):

```bash
UV_PUBLISH_NO_ATTESTATIONS=1 uv publish
```

## Caveats / Common Mistakes

- `uv publish` does not generate attestations. Attestations must be created before the publish
  step (e.g. using `actions/attest-build-provenance` in GitHub Actions).
- Third-party package indexes may not support PEP 740 and may actively reject uploads that
  include attestations rather than silently ignoring them. Use `--no-attestations` or
  `UV_PUBLISH_NO_ATTESTATIONS` when targeting such indexes.
- Attestation auto-discovery was added in uv 0.9.12. Earlier versions do not upload attestations.

## See Also

- bp-build-publish
- bp-trusted-publishing
- integration-github-actions
- bp-publish-custom-index
- config-index-auth
