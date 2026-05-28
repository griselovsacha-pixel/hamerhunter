FROM python:3.11-slim

# Системные зависимости + Go
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget git ca-certificates curl perl \
    && rm -rf /var/lib/apt/lists/*

# Установка Go (необходим для сборки subfinder, httpx, nuclei, dalfox)
ENV GOVERSION=1.21.5
RUN wget -q https://go.dev/dl/go${GOVERSION}.linux-amd64.tar.gz -O go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Установка инструментов через go install (всегда актуальные версии)
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest \
    && go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest \
    && go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest \
    && go install -v github.com/hahwul/dalfox/v2@latest \
    && mv /root/go/bin/* /usr/local/bin/

# Testssl.sh
RUN git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl \
    && ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl

# Sqlmap (через pip, т.к. он написан на Python)
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
