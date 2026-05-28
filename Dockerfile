FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip git ca-certificates curl perl \
    && rm -rf /var/lib/apt/lists/*

# Subfinder
RUN wget -qO /tmp/subfinder.zip "https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_amd64.zip" \
    && unzip /tmp/subfinder.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/subfinder \
    && rm /tmp/subfinder.zip

# Httpx
RUN wget -qO /tmp/httpx.zip "https://github.com/projectdiscovery/httpx/releases/download/v1.6.9/httpx_1.6.9_linux_amd64.zip" \
    && unzip /tmp/httpx.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/httpx \
    && rm /tmp/httpx.zip

# Nuclei
RUN wget -qO /tmp/nuclei.zip "https://github.com/projectdiscovery/nuclei/releases/download/v3.3.0/nuclei_3.3.0_linux_amd64.zip" \
    && unzip /tmp/nuclei.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/nuclei \
    && rm /tmp/nuclei.zip

# Dalfox
RUN wget -qO /usr/local/bin/dalfox "https://github.com/hahwul/dalfox/releases/download/v2.9.2/dalfox_2.9.2_linux_amd64" \
    && chmod +x /usr/local/bin/dalfox

# Testssl.sh
RUN git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl \
    && ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl

# Sqlmap
RUN pip install --no-cache-dir sqlmap

# Commix
RUN git clone --depth 1 https://github.com/commixproject/commix.git /opt/commix \
    && ln -s /opt/commix/commix.py /usr/local/bin/commix

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
