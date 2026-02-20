# Linux Partition Layout Guide

This guide defines a partition layout for this repo's setup flow:
- Fast, high-write data storage on `ext4` at `/data`
- System rollback/snapshots on `btrfs` for OS state
- `/home` planned so user state is recoverable and storage-heavy data stays on `/data`

The playbooks default to `app_data_path: "/data"`, so `/data` should exist before running Ansible.

## Target layout

Use GPT + UEFI boot.

| Mount | Filesystem | Suggested size | Purpose |
|---|---|---:|---|
| `/boot/efi` | FAT32 | 1 GiB | UEFI boot files |
| `/boot` | ext4 | 5 GiB | Kernel/initramfs files plus local recovery ISO storage |
| `/` (Btrfs volume) | btrfs | 250-500 GiB | Ubuntu system + snapshots |
| `/home` | btrfs subvolume (`@home`) | Inside btrfs `/` volume | User config and repos with snapshot support |
| `/data` | ext4 | Remainder (multi-TB) | High-write app/media/data storage |
| swap (optional) | swap | 8-64 GiB | Optional, based on RAM/hibernation needs |

## Btrfs subvolume plan

Inside the btrfs system volume, create subvolumes:
- `@` mounted at `/`
- `@home` mounted at `/home`
- `@snapshots` mounted at `/.snapshots`

This gives you:
- OS rollback capability (`@` snapshots)
- User state rollback capability (`@home` snapshots)
- Separation from large write-heavy datasets in `/data` (`ext4`)

You do not need a separate `/home` partition for this design. `/home` is explicitly defined as its own btrfs subvolume (`@home`) within the system btrfs volume.

## Important boot/snapshot rule

Using a separate `/boot` is acceptable for this deployment so you can keep a local recovery ISO without external USB media.

Tradeoff: btrfs root snapshots will not include files stored on `/boot`, so include `/boot` in your backup/restore checklist when doing rollback operations.

## Installer guidance (Ubuntu 24.04)

1. Choose **Custom storage layout**.
2. Create a GPT partition table on target disk.
3. Create `EFI System Partition`:
   - Size: 1 GiB
   - Type: FAT32
   - Mount: `/boot/efi`
4. Create Linux `/boot` partition:
   - Size: 5 GiB
   - Type: ext4
   - Mount: `/boot`
5. Create btrfs partition for system (`250-500 GiB` typical).
6. Create ext4 partition for `/data` using the remaining capacity.
7. If needed, create swap partition (or plan a swapfile later).
8. Ensure install target for Ubuntu root is the btrfs system partition.

If your installer UI supports btrfs subvolumes directly, define `@`, `@home`, and `@snapshots` during install. Otherwise, install first and then configure subvolumes/snapshot tooling immediately after first boot.

## Post-install verification

Run these checks before running playbooks:

```bash
findmnt -no TARGET,FSTYPE / /home /data /boot/efi
```

Expected:
- `/` -> `btrfs`
- `/home` -> `btrfs`
- `/data` -> `ext4`
- `/boot/efi` -> `vfat`

If you created separate `/boot`, verify it too:

```bash
findmnt -no TARGET,FSTYPE /boot
```

Confirm btrfs subvolumes:

```bash
sudo btrfs subvolume list /
```

Confirm `/data` write settings:

```bash
findmnt -no TARGET,OPTIONS /data
```

Recommended mount options for `/data` in `/etc/fstab`: `defaults,noatime`.

## Factory snapshot and restore scope

Yes, with this layout you can restore system state to a known-good "factory" snapshot while keeping `/data` intact.

What gets restored when you roll back btrfs snapshots:
- `/` (`@`) system state
- `/home` (`@home`) user-level state, configs, repos

What does not get restored by btrfs root/home snapshots:
- `/data` (separate ext4 partition, intentionally persistent)
- `/boot` (separate ext4 partition; not part of btrfs snapshots)

Practical recommendation:
1. After first clean build, create a named baseline snapshot for both `@` and `@home` (for example `factory-YYYYMMDD`).
2. Keep `/boot` backup notes/files as part of recovery docs.
3. Use `snapper` + `grub-btrfs` to boot/select snapshot rollback entries (see `/Users/finnmainstone/code/automated_setup_2025/Setup-post-reboot.md` section `1c` for setup commands).

## `/home` strategy for this project

Use `/home` on btrfs (`@home`) for rollback safety, but keep large/high-churn data on `/data`:
- Repos, configs, scripts: under `/home`
- Camera/media/high-write outputs: under `/data`

If needed, place user data directories on `/data` (bind mounts or symlinks) to reduce snapshot churn and preserve btrfs snapshot performance.

## Snapshot tooling suggestion

For automated snapshot + rollback workflow on Ubuntu:
- `snapper` for snapshot management
- `grub-btrfs` for boot menu entries to snapshots
- `btrfs-assistant` (optional GUI)

After installing tooling, test once:
1. Create snapshot
2. Make a reversible system change
3. Boot/select snapshot
4. Confirm restore path works before production use
