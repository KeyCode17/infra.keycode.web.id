# Encrypted DNS (Cloudflare)

## Why

Biznet transparently intercepts UDP port 53 and answers Kominfo-blocked domains
with its own block page at `202.169.44.80`. The interception is on the
*transport*, not the resolver, so pointing the system at a different public
resolver changes nothing:

```
dig +short duckduckgo.com @1.1.1.1   ->  202.169.44.80   (hijacked)
dig +short duckduckgo.com @8.8.8.8   ->  202.169.44.80   (hijacked)
dig +short duckduckgo.com @9.9.9.9   ->  202.169.44.80   (hijacked)

dig +short +tcp duckduckgo.com @1.1.1.1  ->  20.43.161.105   (real)
curl https://1.1.1.1/dns-query...        ->  20.43.161.105   (real)
```

Only UDP:53 is touched. TCP:53, DoT (853) and DoH (443) all pass through clean.

The block is DNS-only — there is no SNI filtering and no route block. Connecting
straight to the real address works:

```
curl --resolve duckduckgo.com:443:20.43.161.105 https://duckduckgo.com/
-> http=200 in 0.21s
```

So tunnelling DNS over HTTPS is a complete fix, not a partial one.

Affected domains are a selective list, not everything: `duckduckgo.com` and
`vimeo.com` are hijacked; `reddit.com`, `tumblr.com` and `example.com` resolve
normally.

## macOS (declarative)

Handled by `modules/darwin/network/default.nix`. `dnscrypt-proxy` listens on
`127.0.0.1:53`, forwards every query to Cloudflare over DoH, and
`networking.dns` points the system at it.

```sh
sudo darwin-rebuild switch --flake .
```

Two details worth knowing before editing that module:

- **The daemon is forced to run as root.** Port 53 is privileged and the
  upstream nix-darwin module runs it as the unprivileged `_dnscrypt-proxy`
  user, which cannot bind it on macOS.
- **colima also holds TCP `*:53`** (lima hostagent port-forward). This does not
  conflict — dnscrypt-proxy sets `SO_REUSEADDR` and binds alongside it. Verified
  with both listeners live.

### Verifying

```sh
sudo launchctl print system/org.nixos.dnscrypt-proxy | head -20
sudo tail -20 /var/lib/dnscrypt-proxy/dnscrypt-proxy.log

dig +short duckduckgo.com @127.0.0.1    # expect 20.43.161.105, not 202.169.44.80
dig +short dnssec-failed.org @127.0.0.1 # expect empty -> DNSSEC validating
curl -sS -o /dev/null -w '%{http_code}\n' https://duckduckgo.com/
```

### If DNS breaks entirely

`networking.dns` lists `1.1.1.1` after `127.0.0.1` on purpose: macOS queries
resolvers in listed order and only falls through on timeout, so a dead
dnscrypt-proxy degrades to censored-but-working rather than to no resolution at
all. Confirmed non-leaking — 20/20 lookups of a hijacked domain returned the
real address while both entries were configured.

To recover by hand:

```sh
sudo networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1
sudo dscacheutil -flushcache
```

### Tailscale

Tailscale is currently stopped but has `accept-dns: enabled`. When it comes up
it installs its own resolver (`100.100.100.100`) and forwards non-tailnet
queries to the previously configured system resolvers, so `127.0.0.1` should
still be used. This has **not** been verified against a live tailnet. Test it
after next login:

```sh
tailscale up
dig +short duckduckgo.com    # still expect 20.43.161.105
```

If Tailscale shadows it, either set a global nameserver of `127.0.0.1` in the
tailnet DNS settings, or `tailscale set --accept-dns=false` (which gives up
MagicDNS).

### Browsers

Chromium-based browsers (Helium included) use the system resolver by default, so
they are covered once the above is in place. Per-browser DoH is a useful
stopgap before a rebuild, and a second line of defence after one:

> Settings -> Privacy and security -> Use secure DNS -> With: Cloudflare (1.1.1.1)

## Fedora (manual — not declarative)

**This cannot be managed by this flake.** The Fedora host is a standalone
home-manager configuration (`homeConfigurations.<user>` in `flake.nix`), not
NixOS. home-manager writes into `$HOME` only, so it cannot touch
`/etc/systemd/resolved.conf.d/` or `/etc/NetworkManager/conf.d/`, and the
NixOS `networking.*` options do not exist in that module set. The steps below
are run once, as root, outside Nix.

Fedora ships systemd-resolved, which speaks DoT natively — no extra daemon.
Port 853 was verified reachable on this network (`nc -vz 1.1.1.1 853` succeeds),
so DoT is a valid transport here.

```sh
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/cloudflare-dot.conf >/dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
DNSOverTLS=yes
DNSSEC=allow-downgrade
Domains=~.
EOF
sudo systemctl restart systemd-resolved
```

`Domains=~.` makes this the route for *all* names, which is what stops
NetworkManager's per-link DHCP resolver from being preferred. Also stop
NetworkManager handing out the ISP resolver in the first place:

```sh
nmcli -g NAME connection show --active
sudo nmcli connection modify "<connection-name>" ipv4.ignore-auto-dns yes
sudo nmcli connection modify "<connection-name>" ipv6.ignore-auto-dns yes
sudo nmcli connection up "<connection-name>"
```

### Verifying

```sh
resolvectl status | grep -A4 'Global'      # expect +DNSOverTLS
resolvectl query duckduckgo.com            # expect 20.43.161.105
```

### Reverting

```sh
sudo rm /etc/systemd/resolved.conf.d/cloudflare-dot.conf
sudo systemctl restart systemd-resolved
```
