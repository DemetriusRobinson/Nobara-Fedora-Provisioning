#!/bin/bash

set -e

SOFTWARE_DIR="/opt/ApacheSoftware"
FISH_CONFIG="$HOME/.config/fish/config.fish"

echo "📁 Creating $SOFTWARE_DIR if it doesn't exist..."
sudo mkdir -p "$SOFTWARE_DIR"
sudo chown "$USER:$USER" "$SOFTWARE_DIR"

cd /tmp



### 🔽 Fetching Apache Maven Latest
echo "🌐 Fetching Apache Maven..."
MAVEN_URL=$(curl -s https://maven.apache.org/download.cgi | grep -Eo 'https://dlcdn.apache.org/maven/maven-3/[0-9.]*/binaries/apache-maven-[0-9.]*-bin.tar.gz' | head -n 1)
MAVEN_ARCHIVE=$(basename "$MAVEN_URL")

curl -LO "$MAVEN_URL"

# Detect actual folder inside the tar
MAVEN_DIR=$(tar -tf "$MAVEN_ARCHIVE" | head -n 1 | cut -d/ -f1)

tar -xzf "$MAVEN_ARCHIVE" -C "$SOFTWARE_DIR"

# Use $MAVEN_DIR for environment path
if ! grep -q "Apache Maven" "$FISH_CONFIG"; then
  echo -e "\n# Apache Maven" >> "$FISH_CONFIG"
  echo "set -x MAVEN_HOME $SOFTWARE_DIR/$MAVEN_DIR" >> "$FISH_CONFIG"
  echo "set -x PATH \"\$MAVEN_HOME/bin\" \$PATH" >> "$FISH_CONFIG"
  echo "✅ Maven config added."
else
  echo "ℹ️ Maven environment already set in config.fish"
fi

### 🔽 Fetching Apache Kafka Latest (Scala 2.13)
echo "🌐 Fetching Apache Kafka..."
KAFKA_URL=$(curl -s https://kafka.apache.org/downloads | grep -Eo 'https://downloads.apache.org/kafka/[0-9.]*/kafka_2.13-[0-9.]*.tgz' | head -n 1)
KAFKA_ARCHIVE=$(basename "$KAFKA_URL")
KAFKA_DIR=$(echo "$KAFKA_ARCHIVE" | sed 's/.tgz//')

curl -LO "$KAFKA_URL"
tar -xzf "$KAFKA_ARCHIVE" -C "$SOFTWARE_DIR"

### 🐟 Set Fish Environment Variables (idempotent)
echo "🐟 Updating Fish environment for Maven and Kafka..."

if ! grep -q "Apache Maven" "$FISH_CONFIG"; then
  echo -e "\n# Apache Maven" >> "$FISH_CONFIG"
  echo "set -x MAVEN_HOME $SOFTWARE_DIR/$MAVEN_DIR" >> "$FISH_CONFIG"
  echo "set -x PATH \$MAVEN_HOME/bin \$PATH" >> "$FISH_CONFIG"
  echo "✅ Maven config added."
else
  echo "ℹ️ Maven environment already set in config.fish"
fi

if ! grep -q "Apache Kafka" "$FISH_CONFIG"; then
  echo -e "\n# Apache Kafka" >> "$FISH_CONFIG"
  echo "set -x KAFKA_HOME $SOFTWARE_DIR/$KAFKA_DIR" >> "$FISH_CONFIG"
  echo "set -x PATH \$KAFKA_HOME/bin \$PATH" >> "$FISH_CONFIG"
  echo "✅ Kafka config added."
else
  echo "ℹ️ Kafka environment already set in config.fish"
fi

sed -i -e '$a\' "$FISH_CONFIG"

echo "✅ Apache Maven and Kafka installed under $SOFTWARE_DIR"
echo "🔁 Run: source ~/.config/fish/config.fish to activate changes"
echo "     source ~/.config/fish/config.fish"
