#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3-venv python3-pip curl git rsync

mkdir -p /root/tools/bin /root/tools/pylibs

# --- Create git-install ---
cat << 'EOF' > /root/tools/bin/git-install
#!/bin/bash
PKG="$1"
if [ -z "$PKG" ]; then echo "Usage: git-install <python-package>"; exit 1; fi
echo "📦 Installing $PKG to Git..."
pip3 install --target /root/tools/pylibs "$PKG"
tar -czf /tmp/pylibs.tar.gz -C /root/tools/pylibs .
split -b 45M /tmp/pylibs.tar.gz /tmp/chunk_part_
cd /tmp && rm -rf sync
git clone --depth 1 "https://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@github.com/dav3Xc0d13n3/ollie-snapshot.git" sync
mkdir -p sync/storage
rm -f sync/storage/chunks_pylibs.tar.gz.part_*
cp /tmp/chunk_part_* sync/storage/chunks_pylibs.tar.gz.part_
cd sync && git add -A && git commit -m "install $PKG" && git push origin main
rm -rf /tmp/sync /tmp/pylibs.tar.gz /tmp/chunk_part_* /root/tools/pylibs
echo "✅ $PKG is permanently stored in Git. Disk cleared."
EOF

# --- Create git-python ---
cat << 'EOF' > /root/tools/bin/git-python
#!/bin/bash
CACHE="/tmp/pylibs"
if [ ! -d "$CACHE" ]; then
echo "☁️ Fetching Python libs from Git..."
cd /tmp && rm -rf sync
git clone --depth 1 "https://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@github.com/dav3Xc0d13n3/ollie-snapshot.git" sync >/dev/null 2>&1
cat sync/storage/chunks_pylibs.tar.gz.part_* > /tmp/pylibs.tar.gz
mkdir -p /tmp/pylibs
tar -xzf /tmp/pylibs.tar.gz -C /tmp/pylibs
rm -rf sync /tmp/pylibs.tar.gz
fi
export PYTHONPATH="/tmp/pylibs:$PYTHONPATH"
python3 "$@"
EOF

chmod +x /root/tools/bin/git-install
chmod +x /root/tools/bin/git-python

# Add to PATH
if ! grep -q "/root/tools/bin" /root/.bashrc; then
  echo 'export PATH="/root/tools/bin:$PATH"' >> /root/.bashrc
fi
echo "Setup complete. Tools ready."
