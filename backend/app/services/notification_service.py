import smtplib
from email.message import EmailMessage
from typing import Protocol

from app.core.config import Settings


class MailClient(Protocol):
    def send(self, recipient: str, message: str) -> bool: ...


class SmtpMailClient:
    def __init__(self, settings: Settings):
        self.settings = settings

    def send(self, recipient: str, message: str) -> bool:
        settings = self.settings
        if not settings.smtp_host or not settings.smtp_from:
            return False
        email = EmailMessage()
        email["From"] = settings.smtp_from
        email["To"] = recipient
        email["Subject"] = "Pulse: temuan keamanan"
        email.set_content(message)
        try:
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
                if settings.smtp_starttls:
                    smtp.starttls()
                if settings.smtp_user:
                    smtp.login(settings.smtp_user, settings.smtp_password)
                smtp.send_message(email)
            return True
        except (OSError, smtplib.SMTPException):
            return False
