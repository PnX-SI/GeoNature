"""Couleurs et icônes des sorties. Actives seulement sur un terminal : pas de caractère de contrôle ni d'emoji
dans les journaux, les redirections ni les CI (`Style(False)` donne le texte brut)."""

import sys

# Une icône par étape (seulement sur un terminal : un journal de CI reste en texte simple)
STEP_ICONS = {
    "apt": "📦",
    "nvm": "🟢",
    "backend": "🐍",
    "systemd": "⚙️ ",
    "database": "🗄️ ",
    "modules": "🧩",
    "frontend": "🎨",
    "apache": "🌐",
    "services": "🚀",
}

CODES = {
    "bold": "1",
    "gray": "90",
    "red": "31",
    "green": "32",
    "yellow": "33",
    "cyan": "36",
}


class Style:
    def __init__(self, enabled):
        self.enabled = enabled

    @classmethod
    def for_stream(cls, stream=None):
        stream = stream or sys.stdout
        try:
            return cls(stream.isatty())
        except (AttributeError, ValueError):
            return cls(False)

    def paint(self, name, text):
        return f"\033[{CODES[name]}m{text}\033[0m" if self.enabled else str(text)

    def bold(self, text):
        return self.paint("bold", text)

    def gray(self, text):
        return self.paint("gray", text)

    def red(self, text):
        return self.paint("red", text)

    def green(self, text):
        return self.paint("green", text)

    def yellow(self, text):
        return self.paint("yellow", text)

    def cyan(self, text):
        return self.paint("cyan", text)

    def icon(self, step):
        """Icône de l'étape suivie d'une espace, ou chaîne vide hors terminal."""
        return STEP_ICONS.get(step, "") + " " if self.enabled and step in STEP_ICONS else ""


PLAIN = Style(False)
