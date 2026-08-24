{ lib, ... }:
{
  # Biznet transparently intercepts UDP:53 and answers Kominfo-blocked domains
  # with its own block page (202.169.44.80). It is the transport that is
  # hijacked, not the resolver, so 1.1.1.1, 8.8.8.8 and 9.9.9.9 all return the
  # same wrong address; the block is DNS-only, since connecting to the real IP
  # succeeds with no SNI or route filtering. dnscrypt-proxy tunnels every query
  # to Cloudflare over DoH on 443, which the interception does not touch.
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" ];

      ipv4_servers = true;
      ipv6_servers = false;
      dnscrypt_servers = false;
      doh_servers = true;
      require_dnssec = true;

      timeout = 5000;
      keepalive = 30;

      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;

      # Only ever used to resolve the upstream's own hostname. Runs over the
      # hijacked path, which is harmless: dns.cloudflare.com is not blocked.
      bootstrap_resolvers = [
        "1.1.1.1:53"
        "1.0.0.1:53"
      ];
      ignore_system_dns = true;

      # Pinned stamp rather than the public-resolvers source list: nothing to
      # download and no minisign key to rotate before the first query resolves.
      # Copied verbatim from download.dnscrypt.info/resolvers-list/v2.
      static.cloudflare.stamp = "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5";
    };
  };

  # Port 53 is privileged. The upstream module runs the daemon as the
  # unprivileged _dnscrypt-proxy user, which cannot bind it on macOS.
  # (colima's lima hostagent also holds TCP *:53, but dnscrypt-proxy sets
  # SO_REUSEADDR and binds alongside it without conflict.)
  launchd.daemons.dnscrypt-proxy.serviceConfig = {
    UserName = lib.mkForce "root";
    GroupName = lib.mkForce "wheel";
  };

  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];

    # 1.1.1.1 is a deliberate fallback, not a duplicate of the DoH upstream: if
    # dnscrypt-proxy is down, resolution degrades to censored-but-working rather
    # than failing outright. macOS queries resolvers in listed order and only
    # falls through on timeout, so this never shadows 127.0.0.1 while it is up.
    dns = [
      "127.0.0.1"
      "1.1.1.1"
    ];
  };
}
