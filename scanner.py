import subprocess, json, re, requests, tempfile, os, time
from urllib.parse import urlparse, parse_qs, urljoin, urlencode, urlunparse

class ScannerEngine:
    def full_scan(self, url: str) -> list:
        findings = []
        domain = urlparse(url).netloc

        # Разведка
        subs = self._subdomain_enum(domain)
        live = self._live_hosts(subs)
        findings += self._nuclei_scan(live)
        findings += self._sqlmap_scan(url)
        findings += self._dalfox_xss(url)
        findings += self._command_injection(url)
        findings += self._header_analysis(url)
        findings += self._tls_analysis(domain)
        findings += self._js_secrets(url)
        findings += self._injection_fuzzing(url)
        return findings

    def _subdomain_enum(self, domain):
        try:
            out = subprocess.check_output(
                ["subfinder", "-d", domain, "-silent"], text=True, timeout=60
            )
            return list(set(out.splitlines()))
        except:
            return []

    def _live_hosts(self, subs):
        if not subs:
            return []
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
            f.write("\n".join(subs))
            f.flush()
            out = subprocess.check_output(
                ["httpx", "-l", f.name, "-silent", "-probe"], text=True, timeout=30
            )
        os.unlink(f.name)
        return [line.split()[0] for line in out.splitlines() if line]

    def _nuclei_scan(self, hosts):
        if not hosts:
            return []
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
            f.write("\n".join(hosts))
            f.flush()
            out = subprocess.check_output(
                ["nuclei", "-l", f.name, "-json", "-severity", "low,medium,high,critical", "-rate-limit", "30"],
                text=True, timeout=300
            )
        os.unlink(f.name)
        findings = []
        for line in out.splitlines():
            try:
                data = json.loads(line)
                findings.append({
                    "type": data.get("template-id", "nuclei-finding"),
                    "severity": data.get("info", {}).get("severity", "info"),
                    "url": data.get("matched-at", ""),
                    "description": data.get("info", {}).get("description", "")
                })
            except:
                pass
        return findings

    def _sqlmap_scan(self, url):
        try:
            out = subprocess.check_output(
                ["sqlmap", "-u", url, "--batch", "--level=1", "--risk=1", "--forms", "--random-agent"],
                text=True, timeout=120
            )
            if "is vulnerable" in out:
                return [{"type": "SQL Injection", "severity": "critical", "url": url, "description": "Обнаружена SQL-инъекция"}]
        except:
            pass
        return []

    def _dalfox_xss(self, url):
        try:
            out = subprocess.check_output(
                ["dalfox", "url", url, "--silence", "--format", "json"], text=True, timeout=60
            )
            data = json.loads(out)
            if data:
                return [{"type": "XSS", "severity": "high", "url": url, "description": "Обнаружен Cross-Site Scripting"}]
        except:
            pass
        return []

    def _command_injection(self, url):
        try:
            out = subprocess.check_output(
                ["commix", "--url", url, "--batch"], text=True, timeout=60
            )
            if "vulnerable" in out.lower():
                return [{"type": "Command Injection", "severity": "critical", "url": url}]
        except:
            pass
        return []

    def _header_analysis(self, url):
        findings = []
        try:
            r = requests.get(url, timeout=5)
            h = r.headers
            if 'X-Frame-Options' not in h:
                findings.append({"type": "Missing X-Frame-Options", "severity": "medium", "url": url, "description": "Страница может быть вставлена в iframe"})
            if 'Content-Security-Policy' not in h:
                findings.append({"type": "Missing CSP", "severity": "medium", "url": url})
            if 'Strict-Transport-Security' not in h:
                findings.append({"type": "Missing HSTS", "severity": "low", "url": url})
        except:
            pass
        return findings

    def _tls_analysis(self, domain):
        try:
            out = subprocess.check_output(
                ["testssl", "--json-pretty", f"https://{domain}"], text=True, timeout=30
            )
            data = json.loads(out)
            if any("LOW" in str(f) for f in data.get("scanResult", [])):
                return [{"type": "Weak TLS Ciphers", "severity": "medium", "url": domain, "description": "Обнаружены слабые шифры TLS"}]
        except:
            pass
        return []

    def _js_secrets(self, url):
        findings = []
        try:
            r = requests.get(url, timeout=5)
            js_files = re.findall(r'<script[^>]+src=["\'](.*?)["\']', r.text)
            for js in js_files[:5]:  # ограничиваем, чтобы не перегружать
                full_url = urljoin(url, js)
                try:
                    js_resp = requests.get(full_url, timeout=3)
                    if re.search(r'(api_key|secret|token|password)\s*[:=]\s*["\'][\w\-]+["\']', js_resp.text, re.I):
                        findings.append({"type": "Secret in JS", "severity": "high", "url": full_url, "description": "Найдены возможные ключи/токены"})
                except:
                    pass
        except:
            pass
        return findings

    def _injection_fuzzing(self, url):
        payloads = {
            "SQLi": ["' OR '1'='1", "\" OR 1=1--"],
            "SSTI": ["{{7*7}}"],
            "LFI": ["../../../../etc/passwd"],
            "XXE": ['<?xml version="1.0"?><!DOCTYPE root [<!ENTITY test SYSTEM "file:///etc/passwd">]><root>&test;</root>'],
        }
        findings = []
        parsed = urlparse(url)
        params = parse_qs(parsed.query)
        for param in params:
            for vuln, plist in payloads.items():
                for payload in plist:
                    qs = {k: v[0] for k, v in params.items()}
                    qs[param] = payload
                    new_query = urlencode(qs, doseq=True)
                    test_url = urlunparse(parsed._replace(query=new_query))
                    try:
                        resp = requests.get(test_url, timeout=5, allow_redirects=False)
                        if self._is_vulnerable(resp, vuln):
                            findings.append({
                                "type": f"{vuln} Injection",
                                "severity": "high",
                                "url": test_url,
                                "param": param,
                                "payload": payload
                            })
                    except:
                        pass
        return findings

    def _is_vulnerable(self, resp, vuln):
        text = resp.text.lower()
        if vuln == "SQLi":
            if any(e in text for e in ["sql syntax", "mysql_fetch", "unclosed quotation"]):
                return True
            if resp.elapsed.total_seconds() > 4:
                return True
        elif vuln == "SSTI" and "49" in text:
            return True
        elif vuln == "LFI" and "root:" in text:
            return True
        elif vuln == "XXE" and "root:" in text:
            return True
        return False
