# 🛠️ Essential Command-Line Tools Guide

> 💡 **Note:** This living document is updated periodically with powerful, widely available utilities. New tools will be appended below.

______________________________________________________________________

## 🌐 1. [cURL](https://curl.se/)

**Description:** A tool to transfer data via network protocols (HTTP/HTTPS, FTP). Ideal for API testing and scripting.

**Basic Usage:**

```bash
# Fetch a page or API response
curl https://example.com

# Download a file (saves with the original filename)
curl -O https://example.com/file.zip
```

- ✅ **Best Practice:** Use `-s` (silent) in scripts to suppress progress bars. Use `-I` to fetch only HTTP headers.
- ⚠️ **Avoid:** Hardcoding sensitive API keys directly in the command, as they get saved in your plaintext shell history.

______________________________________________________________________

## ⬇️ 2. [Wget](https://www.gnu.org/software/wget/)

**Description:** A robust network downloader for files and directories, particularly effective for handling unstable connections.

**Basic Usage:**

```bash
# Download a file
wget https://example.com/file.iso

# Mirror an entire website
wget --mirror https://example.com
```

- ✅ **Best Practice:** Always use the `-c` flag to resume large, interrupted downloads rather than starting over.
- ⚠️ **Avoid:** Mirroring sites without rate limits. Use `--wait=1` to pause between requests and prevent overloading the target server.

______________________________________________________________________

## 💿 3. [dd (Dataset Definition)](https://www.gnu.org/software/coreutils/manual/html_node/dd-invocation.html)

**Description:** A utility for byte-level raw data copying. Primarily used for flashing bootable USBs and low-level disk cloning.

**Basic Usage:**

```bash
# Flash an ISO to a USB drive
sudo dd if=os-image.iso of=/dev/sdX bs=4M status=progress
```

- ✅ **Best Practice:** Double-check your target drive (`of=`) using `lsblk` before execution. Append `status=progress` to monitor speed.
- ⚠️ **Avoid:** Reversing `if` (input file) and `of` (output file). Doing this can permanently overwrite and destroy your primary drive.

______________________________________________________________________

## 🔄 4. [rsync](https://rsync.samba.org/)

**Description:** A remarkably fast file synchronization tool that minimizes network usage by transferring only the delta (differences) between files.

**Basic Usage:**

```bash
# Sync local directories with human-readable output
rsync -avh /source/ /dest/

# Sync files to a remote server over SSH
rsync -avz /local/ user@remote:/remote/
```

- ✅ **Best Practice:** Always run with `--dry-run` (or `-n`) first when using the `--delete` flag to preview what will be removed.
- ⚠️ **Avoid:** Ignoring the trailing slash on the source directory. `/source` copies the folder itself; `/source/` copies the _contents_ of the folder.

______________________________________________________________________

## 🔧 5. [jq](https://jqlang.github.io/jq/)

**Description:** A lightweight, highly flexible command-line JSON processor used for slicing, filtering, and formatting.

**Basic Usage:**

```bash
# Pretty-print a messy JSON response
curl -s api.example.com | jq

# Extract a specific value from a JSON file
cat data.json | jq '.user.name'
```

- ✅ **Best Practice:** Pipe `curl` responses directly into `jq` for instantly readable API data in your terminal.
- ⚠️ **Avoid:** Trying to parse JSON with text tools like `grep` or `awk`. Use `jq` to ensure your scripts don't break when JSON formatting changes.
