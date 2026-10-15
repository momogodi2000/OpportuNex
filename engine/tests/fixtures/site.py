"""Deterministic local website used by collection and search tests (decision D-25).

Two "publishers" are simulated on the same server through the Host header:
``127.0.0.1`` (original publisher) and ``localhost`` (an aggregator reposting one item).
"""

from __future__ import annotations

import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DEADLINE_SCHOLARSHIP = "2099-11-30"

FEED = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel><title>Fixture opportunities</title><link>http://{host}/</link>
<item><title>Bourse de master en sciences des données 2099 — Université Fictive</title>
<link>http://{host}/opp/1.html?utm_source=rss</link><guid>fx-1</guid>
<pubDate>Mon, 05 Oct 2099 08:00:00 GMT</pubDate>
<description>Bourse complète pour un master en science des données au Cameroun.</description></item>
<item><title>Recrutement : Analyste de données (Python, SQL) à Douala</title>
<link>http://{host}/opp/2.html</link><guid>fx-2</guid>
<description>Poste d'analyste de données. Date limite : 15 décembre 2099.</description></item>
<item><title>Avis d'appel d'offres : fourniture de logiciels de gestion</title>
<link>http://{host}/opp/3.html</link><guid>fx-3</guid>
<description>Marché de fournitures informatiques. Budget 25 000 000 FCFA.</description></item>
</channel></rss>"""

REPOST_FEED = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel><title>Aggregator</title><link>http://localhost/</link>
<item><title>Bourse de master en sciences des données 2099 — Université Fictive</title>
<link>http://localhost/repost/fictive-master</link><guid>agg-1</guid>
<description>Repost : bourse complète pour un master en science des données. Date limite : 30 novembre 2099.</description></item>
</channel></rss>"""

DETAIL_1 = (
    """<html><head><title>Bourse de master</title>
<script type="application/ld+json">{"@context":"https://schema.org","@type":"EducationalOccupationalProgram",
"name":"Bourse de master en sciences des données 2099 — Université Fictive","provider":{"@type":"Organization","name":"Université Fictive"},
"applicationDeadline":"%s"}</script></head><body><main>
<h1>Bourse de master en sciences des données 2099</h1>
<p>L'Université Fictive offre une bourse complète de 1 200 000 FCFA par an pour un master en science des données à Yaoundé, Cameroun.</p>
<h2>Conditions d'éligibilité</h2>
<p>Les candidats doivent être titulaires d'une licence en mathématiques, statistique ou informatique.</p>
<p>Être ressortissant d'un pays de la CEMAC et âgé de moins de 30 ans.</p>
<p>Maîtrise de l'anglais exigée (niveau B2 minimum).</p>
<p>Compétences souhaitées : Python, SQL, statistiques.</p>
<h2>Pièces à fournir</h2><p>CV, lettre de motivation, relevés de notes et deux lettres de recommandation.</p>
<p>Date limite de candidature : 30 novembre 2099.</p>
<script>alert('never executed')</script>
</main></body></html>"""
    % DEADLINE_SCHOLARSHIP
)

DETAIL_2 = """<html><body><article><h1>Analyste de données</h1>
<p>Nous recrutons un analyste de données basé à Douala, Cameroun, en mode hybride.</p>
<p>Profil recherché : master en statistique, 3 ans d'expérience minimum, maîtrise de Python et SQL, Power BI.</p>
<p>Salaire : 600 000 FCFA par mois.</p><p>Date limite : 15 décembre 2099.</p></article></body></html>"""

DETAIL_3 = """<html><body><article><h1>Avis d'appel d'offres</h1>
<p>Le ministère lance un appel d'offres pour la fourniture de logiciels de gestion informatique.</p>
<p>Budget estimatif : 25 000 000 FCFA. Date de clôture : 01/12/2099.</p></article></body></html>"""

INDEX = """<html><head><link rel="alternate" type="application/rss+xml" href="/feed.xml"></head>
<body><h1>Fixture publisher</h1></body></html>"""


class _Handler(BaseHTTPRequestHandler):
    def log_message(self, *args: object) -> None:  # silence test output
        pass

    def _send(self, body: str, ctype: str = "text/html; charset=utf-8", status: int = 200) -> None:
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:
        host = (self.headers.get("Host") or "127.0.0.1").split(":")[0]
        path = self.path.split("?")[0]
        if path == "/robots.txt":
            self._send("User-agent: *\nDisallow: /private/\n", "text/plain")
        elif path == "/" and host == "127.0.0.1":
            self._send(INDEX)
        elif path == "/feed.xml":
            self._send(FEED.replace("{host}", self.headers.get("Host") or "127.0.0.1"), "application/rss+xml")
        elif path == "/aggregator.xml":
            self._send(REPOST_FEED.replace("localhost", self.headers.get("Host") or "localhost"), "application/rss+xml")
        elif path == "/opp/1.html":
            self._send(DETAIL_1)
        elif path == "/opp/2.html":
            self._send(DETAIL_2)
        elif path == "/opp/3.html":
            self._send(DETAIL_3)
        elif path.startswith("/repost/"):
            self._send("<html><body><p>Repost of a scholarship. Date limite : 30 novembre 2099.</p></body></html>")
        elif path.startswith("/private/"):
            self._send("secret", "text/plain")
        else:
            self._send("not found", "text/plain", 404)


class FixtureSite:
    def __init__(self) -> None:
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), _Handler)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def __enter__(self) -> FixtureSite:
        self.thread.start()
        return self

    def __exit__(self, *exc: object) -> None:
        self.server.shutdown()
        self.server.server_close()

    def url(self, path: str, host: str = "127.0.0.1") -> str:
        return f"http://{host}:{self.port}{path}"
