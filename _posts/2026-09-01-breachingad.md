---
title: "Breaching Active Directory"
date: 2026-09-01 08:00:00 +0100
categories: [Writeups, TryHackMe]
tags: [active-directory, ntlm, ldap, mdt, pxe-boot, responder, ntlmv2, hashcat, mcafee, red-team, blue-team]
image:
  path: /assets/img/posts/breachingad/cover.png
---

## Introduction

This one's a network, not a single box: a small Active Directory estate with a domain controller, an IIS server, a printer, a PXE-boot deployment server, and a jump host, all wired together so five different ways of getting that first set of AD credentials can be practiced hands-on instead of just read about. Unlike a puzzle-style room, this network teaches each technique directly, showing the exact commands and explaining why each one works, and the job is working through all five yourself against the live network rather than discovering them cold. That's also why this post has no screenshots, everything below is a terminal-based technique I ran myself following the network's own steps, not something with a UI worth capturing.

The five techniques covered: NTLM password spraying against an internet-facing app, an LDAP pass-back attack against a printer's web interface, capturing and cracking an NTLMv2 challenge with Responder, pulling credentials out of a PXE boot image via Microsoft Deployment Toolkit, and recovering a service account password out of a McAfee agent's local database. Real AD credentials and hashes get redacted below the same as flags anywhere else on this blog.

## Theory

Active Directory runs an estimated 90% of Fortune 1000 companies, which is the reason it's worth this much attention in the first place: if an organization runs Windows, AD is almost certainly the thing managing identity and access for the entire estate. Getting that first set of valid credentials doesn't require a privileged account, any account that can authenticate is enough to start enumerating AD further, privilege comes later. Two authentication mechanisms show up repeatedly across all five techniques: **NTLM** (specifically NetNTLM, a challenge-response scheme where an application forwards authentication material to a domain controller on the user's behalf, rather than storing credentials itself) and **LDAP** (where, unlike NTLM, the application holds its own set of AD credentials to query and verify against LDAP directly, which is why LDAP-authenticated apps leak a *service account*, not just a user's session).

## Walkthrough

### NTLM password spraying

An OSINT exercise (not practiced hands-on here, just named as a source) turned up a list of employee usernames plus the organization's default onboarding password. Since real account lockout policies rule out a full brute-force, the actual technique is a password spray: one password, tried against every username, instead of many passwords against one account. A small Python script did the spraying against an internet-facing app that supports Windows Authentication:

```bash
python3 ntlm_passwordspray.py -u usernames.txt -f za.tryhackme.com -p Changeme123 -a http://ntlmauth.za.tryhackme.com/
```

The script reads the HTTP status code per attempt, a 401 means the pair failed, a 200 means it worked, and it worked for a handful of accounts still sitting on the default password months after onboarding.

### LDAP pass-back via a printer

A network printer's web admin interface needed no login at all, and its settings page showed the LDAP bind username used to authenticate the printer to AD, but not the password, that field only accepts input, it never displays what's already stored. Pressing "Test Settings" makes the printer connect out to the configured LDAP server to verify the credentials work, which is the actual opening: point that server field at your own IP instead, and the printer authenticates to you.

A plain `nc -lvp 389` catches the connection, but only gets as far as an LDAP capability negotiation, the printer and the real LDAP server would normally agree on the strongest mutually supported auth method, and a strong one never sends the password in the clear at all. The fix is standing up a rogue OpenLDAP server and deliberately downgrading what it advertises:

```
# olcSaslSecProps.ldif
dn: cn=config
replace: olcSaslSecProps
olcSaslSecProps: noanonymous,minssf=0,passcred
```

```bash
sudo ldapmodify -Y EXTERNAL -H ldapi:// -f ./olcSaslSecProps.ldif && sudo service slapd restart
```

With only PLAIN and LOGIN advertised, minimum security strength forced to zero, the printer's next "Test Settings" click authenticates in cleartext. A `tcpdump -SX -i breachad tcp port 389` running at the same time catches the bind attempt on the wire, and the LDAP bind DN plus password for the `svcLDAP` account show up directly in the packet bytes: `[redacted]`.

### Capturing and cracking with Responder

SMB's own NetNTLM authentication is the target here, but from the network's perspective rather than a single app's login form. `Responder` listens for LLMNR, NBT-NS, and WPAD broadcast traffic, the local-network name-resolution protocols hosts fall back to before hitting real DNS, and answers them with "that host is me" whenever a lookup comes through it wouldn't otherwise see.

<details style="border: 1px solid rgba(128,128,128,0.35); border-radius: 6px; padding: 0.75em 1em; margin: 1em 0;">
<summary style="cursor: pointer; font-weight: 600;">What Responder actually is</summary>
<div markdown="1" style="margin-top: 0.75em; padding-top: 0.75em; border-top: 1px solid rgba(128,128,128,0.25);">

Responder is an open-source Python tool built specifically to abuse the fallback name-resolution protocols Windows hosts use. When a normal DNS lookup fails, a Windows machine doesn't just give up, it asks the local network directly via LLMNR or NBT-NS, "does anyone know this hostname?" On a network with a lot of hosts, mistyped hostnames and stale DNS records make this happen constantly. Responder sits on the network answering every one of those broadcast questions with "yes, that's me," then spins up its own fake SMB, HTTP, SQL, and other servers to actually receive the connection that follows. Whatever service the victim host was trying to reach, Responder impersonates it well enough to make the client start authenticating, and that's the point where the NetNTLM challenge and response get captured. It can't recover the plaintext password directly, NTLMv2 responses are one-way hashes, but the captured challenge-response pair can be cracked offline exactly like any other password hash.

</div>
</details>

```bash
sudo responder -I breachad
```

A simulated authentication attempt against the network (standing in for the kind of stale-DNS-record traffic that would hit a rogue device on a real LAN) lands an SMBv2 NTLMv2-SSP challenge response in Responder's output, hostname, username, and the challenge hash together. That hash goes straight into Hashcat against a provided wordlist:

```bash
hashcat -m 5600 <hash file> <password file> --force
```

Hashtype `5600` is NetNTLMv2. The password cracked out clean: `[redacted]`. The room also covers *relaying* the challenge instead of just capturing it, useful when SMB signing isn't enforced and the account has real permissions on the target, but that needs enough foothold-first enumeration to know which account is worth relaying, so it stays a "how it works" explanation rather than something practiced blind here.

### Microsoft Deployment Toolkit and PXE boot

MDT lets an organization PXE-boot new machines straight into a preconfigured OS image over the network, no USB drive, no tech physically visiting every desk. That convenience is also the attack surface: the boot image itself can carry a deployment service account's credentials, meant only to reach back to the MDT server during install, not to be extracted afterward.

Working from an SSH session on the jump host, the first pull is the BCD (Boot Configuration Data) file over TFTP, TFTP has no directory listing, so the exact filename has to be known upfront:

```
tftp -i <THMMDT IP> GET "\Tmp\x64{...}.bcd" conf.bcd
```

`PowerPXE` reads that file to find where the actual bootable image lives, then a second TFTP pull grabs the full `.wim` (Windows Imaging Format) file, several hundred megabytes, over the same protocol.

<details style="border: 1px solid rgba(128,128,128,0.35); border-radius: 6px; padding: 0.75em 1em; margin: 1em 0;">
<summary style="cursor: pointer; font-weight: 600;">What PowerPXE actually is</summary>
<div markdown="1" style="margin-top: 0.75em; padding-top: 0.75em; border-top: 1px solid rgba(128,128,128,0.25);">

PowerPXE is a PowerShell module built specifically to automate attacks against insecure PXE boot deployments like this one. On its own, a BCD file or a multi-hundred-megabyte WIM image isn't something you'd want to pick apart by hand, BCD is a binary format Windows itself uses to store boot configuration, and a WIM is a full compressed disk image. PowerPXE wraps that parsing into a couple of functions: `Get-WimFile` reads a BCD file and returns the path of the actual boot image referenced inside it, and `Get-FindCredentials` opens a WIM file and searches it specifically for `bootstrap.ini` and similar MDT configuration files, the ones that carry the deployment share's login details for an unattended install. It doesn't discover new vulnerabilities so much as automate a manual credential hunt that used to mean manually mounting a WIM and grepping through its contents by hand.

</div>
</details>

```powershell
Import-Module .\PowerPXE.ps1
$BCDFile = "conf.bcd"
Get-WimFile -bcdFile $BCDFile
tftp -i <THMMDT IP> GET "<PXE Boot Image Location>" pxeboot.wim
```

The credentials sit inside `bootstrap.ini`, the file MDT uses to configure an unattended install, packed inside the `.wim`. `PowerPXE` pulls it straight out:

```powershell
Get-FindCredentials -WimFile pxeboot.wim
```

Deploy root, domain, username, and password all come back in one shot: `[redacted]`. Of the five techniques in this room, this was the one that actually surprised me, a boot image meant to configure hundreds of new machines unattended carries a live service account inside it by design, and anyone who can reach the PXE server over the network can pull that image down and read it.

### Configuration files: McAfee's local credential store

The last avenue assumes host-level access already, and asks what's sitting in configuration files once you have it. Centrally managed security tooling is a good target here specifically because it needs its own credentials to phone home to its management server. McAfee's endpoint agent keeps exactly that in a local SQLite database:

```
C:\ProgramData\McAfee\Agent\DB\ma.db
```

Pulled off the jump host via `scp` and opened in `sqlitebrowser`, the `AGENT_REPOSITORIES` table carries a `DOMAIN`, `AUTH_USER`, and `AUTH_PASSWD` field. The password field isn't hashed, it's encrypted with a key McAfee has used long enough that public decryption scripts exist for it:

```bash
python2 mcafee_sitelist_pwd_decrypt.py <AUTH_PASSWD value>
```

Decrypted password: `[redacted]`. The lesson generalizes past McAfee specifically: any centrally deployed agent that needs standing credentials to call home is a local file away from handing them over, and the security model for that file usually rests on "nobody finds it," not on the encryption itself being strong.

## Defensive takeaways

This room's own conclusion is a mitigations list, and it's worth taking at face value rather than skimming past: user awareness training (the weakest link stays users disclosing or reusing credentials), keeping NTLM- and LDAP-authenticated apps off the open internet entirely and behind a VPN with MFA instead, Network Access Control to stop a rogue device from ever getting far enough onto the network to run a pass-back or Responder attack in the first place, enforced SMB signing (not just enabled, *enforced*, since a relay attack needs signing to be either off or merely optional to work), and least-privilege on every service account, since the realistic assumption is that an attacker eventually gets *some* set of credentials, and the actual damage ceiling is set by what that account is allowed to do next.

What sticks with me across all five techniques is how little any of them required. Not one needed a vulnerability in the traditional sense, a printer with no admin password, a deployment tool doing exactly what it was designed to do, a security agent needing its own login, an app trusting a default password nobody rotated. AD is critical infrastructure for the large majority of organizations running Windows, and every one of these paths ends the same way: one unprivileged, unremarkable account, and from there the door to the rest of the domain is open. The attack surface for that first foothold isn't a fixed list either, new services get connected to AD constantly, and each one is a new way in until someone checks it.

## Lessons Learned

The technical range across five techniques was the real teaching point here, not any single exploit. NTLM spraying is a credentials problem (a default password nobody changed), LDAP pass-back is a trust problem (a device configured to authenticate outward without verifying where "outward" points), Responder is a protocol-design problem (LLMNR/NBT-NS answering on trust with no verification), MDT/PXE is a convenience-versus-security tradeoff (unattended deployment needs a credential somewhere, and "somewhere" turned out to be extractable), and the McAfee database is a some-secret-has-to-live-somewhere problem. Five different root causes, one outcome each time: a valid AD credential. The MDT chain and the LDAP pass-back attack were the two that actually taught me something new rather than confirming something I'd half-expected, seeing a legitimate, deliberately-built deployment tool carry an extractable secret by design, and a device authenticating outward with zero verification of the far end, are both patterns I'll be watching for now, not just facts I read once.

## References

- [TryHackMe Room — Breaching Active Directory](https://tryhackme.com/room/breachingad)
- [Responder on GitHub](https://github.com/lgandx/Responder)
- [PowerPXE on GitHub](https://github.com/wavestone-cdt/powerpxe)
- [mcafee-sitelist-pwd-decryption on GitHub](https://github.com/funoverip/mcafee-sitelist-pwd-decryption)
- [Hashcat](https://hashcat.net/hashcat/)
