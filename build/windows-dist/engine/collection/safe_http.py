import ipaddress
from urllib.parse import urlparse
import socket
from typing import Any
try:
    import httpx
except ImportError:
    pass

class SSRFGuardError(Exception):
    pass

class SafeHTTPClient:
    def __init__(self, timeout: float = 30.0, max_size: int = 10 * 1024 * 1024):
        self.timeout = timeout
        self.max_size = max_size
        self.headers = {
            'User-Agent': 'OpportuNex/0.1 (+https://github.com/protegeqv/opportunex)'
        }
        self.client = httpx.Client(timeout=timeout, follow_redirects=False) if 'httpx' in globals() else None

    def _validate_url(self, url: str) -> None:
        parsed = urlparse(url)
        if parsed.scheme not in ('http', 'https'):
            raise SSRFGuardError(f"Invalid scheme: {parsed.scheme}")
        hostname = parsed.hostname
        if not hostname:
            raise SSRFGuardError("No hostname provided")
        try:
            ip_info = socket.gethostbyname(hostname)
            ip = ipaddress.ip_address(ip_info)
        except Exception:
            raise SSRFGuardError("DNS resolution failed")

        if ip.is_loopback or ip.is_private or ip.is_link_local or ip.is_multicast:
            raise SSRFGuardError(f"Forbidden IP range: {ip}")
        if str(ip) in ('169.254.169.254', '100.100.100.200'):
            raise SSRFGuardError(f"Forbidden cloud metadata IP: {ip}")

    def get(self, url: str, **kwargs: Any) -> Any:
        current_url = url
        redirects = 0
        while redirects < 5:
            self._validate_url(current_url)
            request_kwargs = {**kwargs, "headers": {**self.headers, **kwargs.get("headers", {})}}
            response = self.client.get(current_url, **request_kwargs)

            if response.status_code in (301, 302, 303, 307, 308):
                current_url = response.headers['Location']
                if not current_url.startswith('http'):
                    current_url = urlparse(url)._replace(path=current_url).geturl()
                redirects += 1
            else:
                return response
        raise SSRFGuardError("Too many redirects")
