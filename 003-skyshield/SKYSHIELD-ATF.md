# SkySHIELD-ATF — Attack Threat Foundation
## SkyCAIR OS Security Module — Internal Reference
### 2XR, LLC | Evolve2Linux | 123Tech.net | CONFIDENTIAL

> "Attack Threat Foundation" — closed-loop security layer for every SkySTACK deployment.
> FIPS 140-2 / CIS Benchmark / HIPAA §164.312 / DISA STIG aligned by default.

---

## Software Stack

| Component | Version | Purpose | Standard |
|-----------|---------|---------|---------|
| **nftables** | kernel netfilter | Stateful packet firewall | CIS 3.x / NIST |
| **dnscrypt-proxy** | 2.1.5+ | Encrypted DNS (DoH + DNSCrypt) | HIPAA §164.312(e) |
| **OpenSSH** | system | Remote access (hardened config) | CIS 5.2.x / NIST SP 800-123 |
| **sysctl hardening** | kernel | Network + memory protection | CIS 1.x / DISA STIG |
| **auditd** (future) | 3.x | Syscall audit trail | HIPAA §164.312(b) |
| **fail2ban** (future) | 1.x | Brute-force IP blocking | CIS 5.2.7 |
| **ClamAV** (future) | 1.x | Malware scanning | HIPAA §164.312(a)(2)(ii) |
| **Suricata** (future) | 7.x | IDS/IPS network monitoring | NIST SP 800-94 |
| **WireGuard** (future) | kernel | VPN mesh (peer-to-peer) | FIPS 140-2 tunnel |
| **Greenbone** (future) | 22.x | Vulnerability assessment | NIST RMF |

---

## Firewall Policy (nftables — Closed-Loop)

```
INPUT:   DROP (default)
  └── ACCEPT loopback
  └── ACCEPT established/related
  └── ACCEPT all RFC1918 (10/8, 172.16/12, 192.168/16)  ← All SkySTACK LAN
  └── ACCEPT ICMPv4/v6 operational types (unreachable, TTL, ND)
  └── DROP  ICMP echo-request from external (anti-ping-flood)
  └── LOG + DROP everything else

OUTPUT:  ACCEPT (SkyAPI, SkyRepo, NTP, ACME, AI model downloads)

FORWARD: DROP (enable for router/VPN mode)
```

### SkySTACK Ports (LAN-only via RFC1918 accept rule)

| Port | Service | Module |
|------|---------|--------|
| 22 | SSH | base |
| 80/443 | HTTP/HTTPS | SkyRepo, SkyAPI |
| 8080 | Open WebUI | 003-skyomegai |
| 8088 | SkyRepo mirror | SkySTACK |
| 8443 | SkyAPI | SkyAPI |
| 9090 | Cockpit | SkyVAULT |
| 11434 | Ollama API | 003-skyomegai |
| 22000/8384 | Syncthing | SkyVAULT |
| 445/139 | Samba/SMB | SkyVAULT |

---

## DNS Encryption

- **Protocol**: DoH (DNS-over-HTTPS) + DNSCrypt via dnscrypt-proxy 2.x
- **Resolvers**: Cloudflare 1.1.1.1 (no-log) + Quad9 9.9.9.9 (malware filter) + Mullvad
- **Blocked**: Google DNS (8.8.8.8/8.8.4.4) — privacy + HIPAA compliance
- **Internal leak prevention**: `block_unqualified=true` (no .local/.internal leakage)
- **NetworkManager**: `dns=none` — NM never overwrites /etc/resolv.conf

---

## SSH Hardening

- `PermitRootLogin no` — CIS 5.2.8
- `MaxAuthTries 3` — brute-force limit
- `ClientAliveInterval 300` — 15-min idle disconnect
- **KexAlgorithms**: curve25519-sha256, ECDH P-521/P-384, DH Group 16/18
- **Ciphers**: ChaCha20-Poly1305, AES-256-GCM, AES-256-CTR only
- **MACs**: ETM SHA-2 only (HMAC-SHA2-512, HMAC-SHA2-256)
- **LogLevel VERBOSE** — full auth audit trail (HIPAA §164.312(b))

---

## Security Sysctl Optimizations

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `net.ipv4.ip_forward` | 0 | Closed-loop: no routing |
| `net.ipv4.conf.all.rp_filter` | 1 | Anti-spoofing |
| `net.ipv4.tcp_syncookies` | 1 | SYN flood protection |
| `kernel.randomize_va_space` | 2 | Full ASLR |
| `kernel.kptr_restrict` | 2 | Hide kernel pointers |
| `kernel.dmesg_restrict` | 1 | Root-only dmesg |
| `kernel.unprivileged_bpf_disabled` | 1 | No eBPF from userspace |
| `net.core.bpf_jit_harden` | 2 | BPF JIT hardening |
| `fs.protected_hardlinks` | 1 | Hardlink race prevention |
| `fs.protected_symlinks` | 1 | Symlink TOCTOU prevention |
| `kernel.sched_autogroup_enabled` | 1 | Foreground UX protection |

---

## Compliance Mapping

| Framework | Controls Addressed |
|-----------|-------------------|
| **CIS Benchmark** | 1.6 (ASLR), 3.1-3.2 (network), 5.2 (SSH), 6.2 (firewall) |
| **NIST SP 800-53** | AC-3, AC-17, SC-7, SC-28, AU-2, AU-3 |
| **HIPAA §164.312** | (a)(1) access, (b) audit, (d) auth, (e) transmission |
| **DISA STIG** | Network hardening, SSH, kernel params |
| **FIPS 140-2** | SSH cipher suite (AES-256, SHA-2, P-521) |

---

## Future ATF Components (Roadmap)

- **fail2ban**: auto-ban brute-force IPs after 3 failures (integrates with nftables sets)
- **Suricata IDS/IPS**: real-time network threat detection; Emerging Threats rules
- **ClamAV**: on-access malware scanning for uploads/downloads
- **WireGuard mesh**: site-to-site VPN for multi-SkySTACK deployments
- **Greenbone/OpenVAS**: scheduled vulnerability scans with CVSS scoring
- **SkySHIELD dashboard**: real-time threat map in Cockpit (port 9090)
- **SIEM integration**: export logs to Elasticsearch / Loki for SkySTACK SIEM tier

---

*CONFIDENTIAL — Internal use by 2XR, LLC | Evolve2Linux | 123Tech.net*
*This document describes proprietary security architecture. Do not distribute.*
