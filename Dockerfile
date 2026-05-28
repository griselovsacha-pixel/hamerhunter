FROM kalilinux/kali-rolling

# Установка всех инструментов
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git curl wget unzip ca-certificates \
    subfinder httpx nuclei \
    sqlmap dalfox testssl.sh \
    && rm -rf /var/lib/apt/lists/*

# Установка commix (инъекции команд)
RUN git clone https://github.com/commixproject/commix.git /opt/commix \
    && ln -s /opt/commix/commix.py /usr/local/bin/commix

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
