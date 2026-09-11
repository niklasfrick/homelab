# Hermes host service on `spark` (obelisk)

Host-level systemd **user** units for the Hermes agent that runs on the DGX Spark
host `spark` (10.96.10.160). These are *not* cluster workloads — Hermes runs on
the host, outside the `zendo` cluster, so ArgoCD/Helm do not apply here.

## Install

```bash
install -m 0755 bin/hermes-chromium ~/.local/bin/hermes-chromium
install -m 0644 systemd/hermes-chromium.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now hermes-chromium.service
```

## `hermes-chromium.service`

Hermes' browser tool does not launch a browser. Its harness looks for an
already-running Chromium-family browser whose profile directory is one it scans
(`~/.config/chromium`) and whose `SingletonLock` points at a live PID, then
attaches over the DevTools protocol. With no browser running, every
`browser_exec` call dies with:

```
fatal: chrome-not-running: no supported Chromium-family browser is running -- start Chrome, then retry
```

This unit keeps that browser running: headless, own user-data-dir, CDP on
`127.0.0.1:9222`, `Restart=always`.

`bin/hermes-chromium` resolves the newest Playwright Chromium build under
`~/.cache/ms-playwright/chromium-*/`, so a Playwright version bump does not
break the unit.

## Verify

```bash
systemctl --user is-active hermes-chromium.service      # active
curl -s http://127.0.0.1:9222/json/version | head -3    # Chrome/148...
```

Then confirm the attach path works end to end — the point is the harness
attaching, not Chrome being up:

```
browser_exec: new_tab("https://example.com") → page_info() returns a title
```
