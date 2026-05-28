FROM python:3.11-slim

# Установка системных зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget unzip ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Установка Go (для nuclei, subfinder, httpx)
ENV GOVERSION=1.21.5
RUN wget -q https://go.dev/dl/go${GOVERSION}.linux-amd64.tar.gz -O go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Установка утилит ProjectDiscovery (subfinder, httpx, nuclei)
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest \
    && go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest \
    && go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest \
    && mv /root/go/bin/* /usr/local/bin/

# Установка dalfox (XSS scanner)
RUN go install -v github.com/hahwul/dalfox/v2@latest \
    && mv /root/go/bin/dalfox /usr/local/bin/

# Установка sqlmap (через pip, т.к. он написан на Python)
RUN pip install --no-cache-dir sqlmap

# Установка commix (command injection scanner)
RUN git clone https://github.com/commixproject/commix.git /opt/commix \
    && ln -s /opt/commix/commix.py /usr/local/bin/commix

# Установка testssl.sh (скрипт)
RUN git clone https://github.com/drwetter/testssl.sh.git /opt/testssl \
    && ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl

# Установка Python-зависимостей приложения
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копируем код приложения
COPY . .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
