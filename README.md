# twintaillauncher-flake

A Nix flake packaging [TwintailLauncher](https://github.com/TwintailTeam/TwintailLauncher) — a multi-platform launcher for anime games — from its official `.deb` releases (amd64 + arm64).

## Usage

Add as a flake input:

```nix
{
  inputs.twintaillauncher = {
    url = "github:axioncs/twintaillauncher-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then reference the package, e.g. in `home.packages`:

```nix
home.packages = [ inputs.twintaillauncher.packages.${pkgs.stdenv.hostPlatform.system}.default ];
```

Or run it directly without installing (uses your system's nixpkgs):

```bash
nix run github:axioncs/twintaillauncher-flake --override-input nixpkgs flake:nixpkgs
```

Or build it locally:

```bash
nix build github:axioncs/twintaillauncher-flake --override-input nixpkgs flake:nixpkgs
./result/bin/twintaillauncher
```

## Supported systems

- `x86_64-linux`
- `aarch64-linux`

## Known issues

### Pressing Play twice in one session can crash the launcher

The launcher copies `hkrpg_patch.dll` out of the read-only Nix store to the game's `jsproxy.dll`. The copy inherits the read-only mode, so the next copy fails with `PermissionDenied`.

This flake wraps the launcher in an entrypoint that makes every install's `jsproxy.dll` writable before and after the launcher process runs, which fixes it between sessions. A second Play within the same launcher session can still hit the panic; restart the launcher and it works.

## License

Packaging code in this repo is MIT — see `LICENSE`. TwintailLauncher itself is GPL-3.0 — see [upstream](https://github.com/TwintailTeam/TwintailLauncher).
