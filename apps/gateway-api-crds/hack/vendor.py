#!/usr/bin/env python3
"""Re-vendor the Gateway API CRDs into this chart from an upstream release.

Usage: python3 apps/gateway-api-crds/hack/vendor.py v1.6.1

Downloads standard-install.yaml and experimental-install.yaml from the
kubernetes-sigs/gateway-api release and regenerates templates/:

  standard/<plural>.yaml          one file per standard-channel CRD
  experimental.yaml               the whole experimental bundle (channel: experimental)
  experimental-resources/<plural>.yaml
                                  experimental-channel variants that can be swapped in
                                  per resource while channel: standard
  safe-upgrades-policy.yaml       upstream's safe-upgrades ValidatingAdmissionPolicy,
                                  gated by .Values.safeUpgradesPolicy

and bumps Chart.yaml version/appVersion. Stdlib only.
"""
import pathlib
import re
import sys
import urllib.request

CHART = pathlib.Path(__file__).resolve().parent.parent / "helm"
TEMPLATES = CHART / "templates"
RELEASE_URL = "https://github.com/kubernetes-sigs/gateway-api/releases/download/{version}/{bundle}"

# experimental-channel CRDs that can replace (or, for x-k8s.io, add to) the
# standard bundle, keyed by plural -> values.yaml toggle under experimentalResources
EXPERIMENTAL_TOGGLES = {
    "tlsroutes": "tlsRoute",
    "tcproutes": "tcpRoute",
    "udproutes": "udpRoute",
    "xbackends": "xBackend",
    "xbackendtrafficpolicies": "xBackendTrafficPolicy",
    "xmeshes": "xMesh",
}


def fetch(version, bundle):
    with urllib.request.urlopen(RELEASE_URL.format(version=version, bundle=bundle)) as resp:
        return resp.read().decode()


def split(bundle_text):
    """Return (license_header, [docs]) where each doc keeps its source comment."""
    parts = bundle_text.split("\n---\n")
    header = parts[0].split("\n#\n# Gateway API")[0].rstrip() + "\n"
    return header, [p.strip("\n") + "\n" for p in parts[1:] if p.strip()]


def kind_and_name(doc):
    kind = re.search(r"^kind: (\S+)", doc, re.M).group(1)
    name = re.search(r"^  name: \"?([^\"\s]+)", doc, re.M).group(1)
    return kind, name


def write(path, condition, header, docs):
    path.parent.mkdir(parents=True, exist_ok=True)
    body = "---\n".join(docs)
    path.write_text(f"{{{{- if {condition} }}}}\n{header}---\n{body}{{{{- end }}}}\n")


def main(version):
    std_header, std_docs = split(fetch(version, "standard-install.yaml"))
    exp_header, exp_docs = split(fetch(version, "experimental-install.yaml"))
    for text in std_docs + exp_docs:
        if "{{" in text:
            sys.exit("upstream CRDs contain '{{' - escape before wrapping in helm templates")

    for stale in [TEMPLATES / "standard.yaml", *TEMPLATES.glob("standard/*.yaml"),
                  *TEMPLATES.glob("experimental-resources/*.yaml")]:
        stale.unlink(missing_ok=True)

    std_vap = []
    for doc in std_docs:
        kind, name = kind_and_name(doc)
        if kind.startswith("ValidatingAdmissionPolicy"):
            std_vap.append(doc)
            continue
        plural = name.split(".")[0]
        condition = 'eq .Values.channel "standard"'
        if plural in EXPERIMENTAL_TOGGLES:
            condition = f"and ({condition}) (not .Values.experimentalResources.{EXPERIMENTAL_TOGGLES[plural]})"
        write(TEMPLATES / "standard" / f"{plural}.yaml", condition, std_header, [doc])

    exp_vap, exp_crds = [], []
    for doc in exp_docs:
        kind, name = kind_and_name(doc)
        if kind.startswith("ValidatingAdmissionPolicy"):
            exp_vap.append(doc)
            continue
        exp_crds.append(doc)
        plural = name.split(".")[0]
        if plural in EXPERIMENTAL_TOGGLES:
            condition = f'and (eq .Values.channel "standard") .Values.experimentalResources.{EXPERIMENTAL_TOGGLES[plural]}'
            write(TEMPLATES / "experimental-resources" / f"{plural}.yaml", condition, exp_header, [doc])
    write(TEMPLATES / "experimental.yaml", 'eq .Values.channel "experimental"', exp_header, exp_crds)

    vap = TEMPLATES / "safe-upgrades-policy.yaml"
    vap.write_text(
        "{{- if .Values.safeUpgradesPolicy }}\n"
        "{{- if eq .Values.channel \"standard\" }}\n" + std_header + "---\n" + "---\n".join(std_vap)
        + "{{- else }}\n" + exp_header + "---\n" + "---\n".join(exp_vap)
        + "{{- end }}\n{{- end }}\n"
    )

    chart = CHART / "Chart.yaml"
    text = chart.read_text()
    text = re.sub(r"^version: .*$", f"version: {version.lstrip('v')}", text, flags=re.M)
    text = re.sub(r'^appVersion: "[^"]*"', f'appVersion: "{version}"', text, flags=re.M)
    chart.write_text(text)


if __name__ == "__main__":
    if len(sys.argv) != 2 or not sys.argv[1].startswith("v"):
        sys.exit(__doc__)
    main(sys.argv[1])
