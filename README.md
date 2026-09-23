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

Or run it directly without installing:

```bash
nix run github:axioncs/twintaillauncher-flake
```

Or build it locally:

```bash
nix build github:axioncs/twintaillauncher-flake
./result/bin/twintaillauncher
```

## Supported systems

- `x86_64-linux`
- `aarch64-linux`

## License

Packaging code in this repo is MIT — see `LICENSE`. TwintailLauncher itself is GPL-3.0 — see [upstream](https://github.com/TwintailTeam/TwintailLauncher).
