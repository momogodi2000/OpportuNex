"""Transactional e-mail over SMTP (verification, password reset, invitations).

Without SMTP settings the message is written to the server log instead: acceptable for a personal
self-hosted instance or tests, never for a public instance (README).
"""

from __future__ import annotations

import logging
import smtplib
import ssl
from dataclasses import dataclass
from email.message import EmailMessage

from opx_sync.config import Settings

log = logging.getLogger("opx_sync.mail")


@dataclass
class Sent:
    to: str
    subject: str
    body: str


class Mailer:
    def __init__(self, settings: Settings) -> None:
        self.s = settings
        self.sent: list[Sent] = []  # kept for tests and the log fallback

    def send(self, to: str, subject: str, body: str) -> None:
        self.sent.append(Sent(to, subject, body))
        if not self.s.smtp_host:
            log.warning("smtp_not_configured to=%s subject=%s body=%s", to, subject, body)
            return
        msg = EmailMessage()
        msg["From"] = self.s.smtp_from
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        with smtplib.SMTP(self.s.smtp_host, self.s.smtp_port, timeout=20) as smtp:
            if self.s.smtp_starttls:
                smtp.starttls(context=ssl.create_default_context())
            if self.s.smtp_user:
                smtp.login(self.s.smtp_user, self.s.smtp_password or "")
            smtp.send_message(msg)
