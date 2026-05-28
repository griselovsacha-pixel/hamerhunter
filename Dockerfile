FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip git ca-certificates curl perl \
    && rm -rf /var/lib/apt/lists/*

# Версии инструментов (можно менять при выходе новых)
ENV SUBFINDER_VERSION=2.6.6
ENV HTTPX_VERSION=1.6.9
ENV NUCLEI_VERSION=3.3.0
ENV DALFOX_VERSION=2.9.2

# Subfinder
RUN wget -qO /tmp/subfinder.zip "https://github.com/projectdiscovery/subfinder/releases/download/v${SUBFINDER_VERSION}/subfinder_${SUBFINDER_VERSION}_linux_amd64.zip" \
    && unzip /tmp/subfinder.zip -d /usr/local/bin/ \
    && rm /tmp/subfinder.zip

# Httpx
RUN wget -qO /tmp/httpx.zip "https://github.com/projectdiscovery/httpx/releases/download/v${HTTPX_VERSION}/httpx_${HTTPX_VERSION}_linux_amd64.zip" \
    && unzip /tmp/httpx.zip -d /usr/local/bin/ \
    && rm /tmp/httpx.zip

# Nuclei
RUN wget -qO /tmp/nuclei.zip "https://github.com/projectdiscovery/nuclei/releases/download/v${NUCLEI_VERSION}/nuclei_${NUCLEI_VERSION}_linux_amd64.zip" \
    && unzip /tmp/nuclei.zip -d /usr/local/bin/ \
    && rm /tmp/nuclei.zip

# Dalfox
RUN wget -qO /usr/local/bin/dalfox "https://github.com/hahwul/dalfox/releases/download/v${DALFOX_VERSION}/dalfox_${DALFOX_VERSION}_linux_amd64" \
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
