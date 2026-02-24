# Security Policy — SkyCAIR OS

## Supported Versions

| Version | Supported |
|---------|-----------|
| v2.6.x (skycair-2.6-cosmic) | ✅ Active |
| v2.5 and earlier | ❌ End of Life |

## Reporting a Vulnerability

**Please do NOT open a public GitHub issue for security vulnerabilities.**

Report security issues directly to the SkyCAIR security team:

- **Email**: SkyCAIR@123Tech.net
- **Subject**: `[SECURITY] <brief description>`
- **Phone**: (608) 454-6660 (business hours, Central Time)

### What to Include

1. Description of the vulnerability and affected component
2. Steps to reproduce
3. Potential impact assessment
4. Any suggested mitigations (optional)

### Response Timeline

| Stage | Target Time |
|-------|-------------|
| Acknowledgment | Within 48 hours |
| Initial assessment | Within 5 business days |
| Patch/mitigation | Within 30 days for critical, 90 days for others |
| Public disclosure | Coordinated with reporter |

## Scope

This policy covers:
- SkyCAIR OS build scripts and configuration files in this repository
- SkyCAIR module entitlement system (skymod-agent)
- SkyCAIR boot process and dracut hooks
- SkyCAIR App Store

Out of scope:
- Upstream PorteuX vulnerabilities (report to https://github.com/porteux/porteux)
- Slackware package vulnerabilities (report to Slackware security)
- Third-party applications available via the App Store

## Security Features

SkyCAIR OS includes the following security measures:
- **Module signing**: All .xzm modules are signed with ed25519 via `openssl pkeyutl`
- **UUID entitlement**: Device authentication via skyapi.123tech.net every 60 seconds
- **Offline grace mode**: Signed manifest cache valid 30 days
- **Secret scanning**: GitHub secret scanning enabled on this repository

## Commercial Security Support

Enterprise customers (SkyGRID-E2L, SkySTACK-E2L tiers) receive priority security
response and dedicated support. Contact SkyCAIR@123Tech.net for details.
