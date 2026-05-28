FROM python:3.11-slim

# Системные зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip git ca-certificates curl perl \
    && rm -rf /var/lib/apt/lists/*

# ------------------ Установка готовых бинарников ------------------
# Subfinder
RUN wget -qO /tmp/subfinder.zip https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder_linux_amd64.zip \
    && unzip /tmp/subfinder.zip -d /usr/local/bin/ \
    && rm /tmp/subfinder.zip

# Httpx
RUN wget -qO /tmp/httpx.zip https://github.com/projectdiscovery/httpx/releases/latest/download/httpx_linux_amd64.zip \
    && unzip /tmp/httpx.zip -d /usr/local/bin/ \
    && rm /tmp/httpx.zip

# Nuclei
RUN wget -qO /tmp/nuclei.zip https://github.com/projectdiscovery/nuclei/releases/latest/download/nuclei_linux_amd64.zip \
    && unzip /tmp/nuclei.zip -d /usr/local/bin/ \
    && rm /tmp/nuclei.zip

# Dalfox
RUN wget -qO /usr/local/bin/dalfox https://github.com/hahwul/dalfox/releases/latest/download/dalfox_linux_amd64 \
    && chmod +x /usr/local/bin/dalfox

# Testssl.sh
RUN git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl \
    && ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl

# Sqlmap (через pip)
RUN pip install --no-cache-dir sqlmap

# Commix
RUN git clone --depth 1 https://github.com/commixproject/commix.git /opt/commix \
    && ln -s /opt/commix/commix.py /usr/local/bin/commix

# ------------------ Приложение ------------------
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
