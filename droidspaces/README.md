# DroidSpaces support (SDM845 / Mi MIX 2S "polaris")

Integration of [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)
container support into this 4.9 non-GKI kernel. Droidspaces is an LXC-like
container runtime that runs full Linux distros (and Docker/Podman/LXC nested)
directly on Android. It needs the kernel to expose Linux namespaces, cgroups,
seccomp, overlayfs and container networking.

## What was changed

1. **Kernel config fragment** — `arch/arm64/configs/vendor/xiaomi/droidspaces.config`
   Enables namespaces (PID/UTS/IPC/NET), SysV IPC + POSIX MQ, the cgroup
   controllers, seccomp filter, overlayfs, tmpfs xattr/acl, firmware loader,
   and the netfilter/bridge/veth stack for NAT-mode container networking.
   It is merged on top of `mi845_defconfig` by `build_for_mix_2s.sh`, after
   `polaris.config`. Only symbols verified to exist in this 4.9 tree are listed
   (mainline-only symbols such as `NETFILTER_XT_TARGET_MASQUERADE`,
   `NF_CONNTRACK_NETLINK`, `IP_NF_TARGET_ULOG` were omitted; the 4.9 equivalents
   like `IP_NF_TARGET_MASQUERADE` are used instead).

2. **cgroup file-prefix fix** — `kernel/cgroup.c` (`cgroup_add_file`)
   Ports patch `02` below. When a hierarchy is mounted with `noprefix` (Android
   does this), it additionally creates a subsys-prefixed symlink alias
   (e.g. `cpu.stat`) so container runtimes that expect prefixed cgroup file
   names keep working. Applied inline; the original patch targeted
   `kernel/cgroup/cgroup.c` (mainline layout) and was adapted to this tree's
   `kernel/cgroup.c`.

## Patches (`kernel-patches/`)

- `02.restore_cgroup_file_prefix_handling.patch` — **applied** (adapted path).
- `01.fix_kernel_panic_in_xt_qtaguid.patch` — **not applicable**: this tree has
  no `xt_qtaguid` (no `net/netfilter/xt_qtaguid.c`), so the panic it fixes
  cannot occur here. Kept for reference/provenance only.

## Verifying on device

After flashing, install the Droidspaces app and run
**Settings → Requirements → Check Requirements**, or from a root shell:

```
su -c droidspaces check
```

All "Fatal" items (PID/MNT/UTS/IPC namespaces, cgroup device, devtmpfs) should
be green.

Upstream config reference:
https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md
