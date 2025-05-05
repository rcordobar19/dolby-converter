FROM ubuntu:24.04

# Install dependencies from default Ubuntu repos
RUN apt-get update && \
    apt-get install -y wget mediainfo mkvtoolnix ffmpeg && \
    wget https://github.com/quietvoid/dovi_tool/releases/download/2.1.3/dovi_tool-2.1.3-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf dovi_tool-2.1.3-x86_64-unknown-linux-musl.tar.gz && \
    mv dovi_tool /usr/local/bin/ && \
    rm dovi_tool-2.1.3-x86_64-unknown-linux-musl.tar.gz && \
    chmod +x /usr/local/bin/dovi_tool && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy script
COPY convert_dv7_to_dv8.sh /usr/local/bin/convert_dv7_to_dv8.sh

# Set permissions
RUN chmod +x /usr/local/bin/convert_dv7_to_dv8.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/convert_dv7_to_dv8.sh"]
