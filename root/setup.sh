#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3 python3-pip curl git rsync

# 1. Install Telethon
pip3 install telethon --break-system-packages

# 2. Save your credentials
mkdir -p /root/tools/bin
cat << 'EOF' >> /root/.bashrc
export TG_API_ID="37489215"
export TG_API_HASH="7457b8821be256f357e6d61451c5a693"
export TG_SESSION="1BJWap1wBu5hTDKPKysogw_xzYw-RNsG8GSuppGAf2CG4KWXF5MX7P0Yi3nYGjf7rm58kdTfgog0o0n230o3ja7stZYH5zfj1O0ioVTP3my1bGgfHxRhEm8VjPAayN2t8Fr9bmvADXR7lENG3hT5stD9vxcx3uAu8hCJWHlua4-pi3Fq9FEztP2J0AiNsV8Qf2HM-MvMT8G_0DNAnOW_FZW-Wu4885ca84-IfUI2lDbQGPVCd8Z3CvzYSpOACA7oUKmf5EC4WXBWXd_xjjBNGsX1LsJZesf5u_s-puxpS6eeehL3KvI6DVDXWCu_QY1Pe4o7dKnAEFLfOk4wPBw4WLah0o9VObDE="
export PATH="/root/tools/bin:$PATH"
EOF

# 3. Create the Python Script
cat << 'EOF' > /root/tg_drive.py
import os
import sys
from telethon.sync import TelegramClient
from telethon.sessions import StringSession
from telethon.tl.types import DocumentAttributeFilename

API_ID = int(os.environ.get("TG_API_ID"))
API_HASH = os.environ.get("TG_API_HASH")
SESSION = os.environ.get("TG_SESSION")

def upload(file_path):
    filename = os.path.basename(file_path)
    with TelegramClient(StringSession(SESSION), API_ID, API_HASH) as client:
        print(f"☁️ Uploading {filename} to Telegram...")
        client.send_file('me', file_path, force_document=True)
        print("✅ Upload complete!")

def download(filename):
    cache_dir = "/tmp/tg-cache"
    os.makedirs(cache_dir, exist_ok=True)
    out_path = os.path.join(cache_dir, filename)
    
    if os.path.exists(out_path):
        print(f"⚡ Found in RAM cache: {out_path}")
        return out_path

    with TelegramClient(StringSession(SESSION), API_ID, API_HASH) as client:
        print(f"☁️ Searching Telegram for {filename}...")
        for message in client.iter_messages('me'):
            if message.document:
                for attr in message.document.attributes:
                    if isinstance(attr, DocumentAttributeFilename) and attr.file_name == filename:
                        print(f"📥 Downloading {filename} to RAM...")
                        client.download_media(message, file=out_path)
                        return out_path
        print("❌ File not found in Telegram.")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 tg_drive.py upload <file> | download <file>")
        sys.exit(1)
    
    action = sys.argv[1]
    target = sys.argv[2]
    
    if action == "upload":
        upload(target)
    elif action == "download":
        download(target)
EOF

# 4. Create the Wrappers
cat << 'EOF' > /root/tools/bin/tg-keep
#!/bin/bash
source /root/.bashrc
python3 /root/tg_drive.py upload "$1"
rm -f "$1"
echo "🗑️ Local file deleted."
EOF
chmod +x /root/tools/bin/tg-keep

cat << 'EOF' > /root/tools/bin/tg-run
#!/bin/bash
source /root/.bashrc
FILE_NAME="$1"
shift
python3 /root/tg_drive.py download "$FILE_NAME"
chmod +x "/tmp/tg-cache/$FILE_NAME"
"/tmp/tg-cache/$FILE_NAME" "$@"
EOF
chmod +x /root/tools/bin/tg-run

echo "Telegram Drive Setup Complete."
