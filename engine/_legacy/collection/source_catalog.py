"""
Initial source catalog for OpportuNex.
60+ curated sources covering African opportunities:
- Cameroun & Central Africa (government, universities, NGOs)
- International organizations (UN, World Bank, EU, AFD, USAID)
- Scholarships & academic funding
- Grants for NGOs and entrepreneurs
"""

INITIAL_SOURCES = [
    # ── Cameroun & Central Africa ─────────────────────────────────────────
    {
        "name": "Minader Cameroun — Appels d'Offres",
        "base_url": "https://www.minader.cm",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["appel_offres", "agriculture"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.minader.cm/category/appels-doffres/",
            "list_selector": ".post",
            "title_selector": "h2.entry-title",
            "link_selector": "h2.entry-title a",
            "deadline_selector": ".entry-date",
        },
    },
    {
        "name": "Cameroun — Marchés Publics (ARMP)",
        "base_url": "https://www.armp.cm",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["appel_offres", "marche_public"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.armp.cm/index.php/fr/avis-dappel-offres",
            "list_selector": "table tr",
            "title_selector": "td:first-child",
            "link_selector": "td a",
            "deadline_selector": "td:nth-child(3)",
        },
    },
    {
        "name": "Portail des Bourses du Cameroun",
        "base_url": "https://www.minesup.gov.cm",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["bourse", "enseignement_superieur"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.minesup.gov.cm/index.php/fr/programmes/bourses",
            "list_selector": ".article",
            "title_selector": "h3",
            "link_selector": "h3 a",
        },
    },

    # ── United Nations System ─────────────────────────────────────────────
    {
        "name": "UN Jobs — Africa",
        "base_url": "https://unjobs.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["emploi", "ong", "international"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://unjobs.org/themes/africa.rss",
            "rss_title_field": "title",
            "rss_link_field": "link",
            "rss_date_field": "published",
        },
    },
    {
        "name": "UNDP Jobs",
        "base_url": "https://jobs.undp.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["emploi", "ong", "international"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://jobs.undp.org/cj_view_jobs.cfm",
            "list_selector": "table.vacancyTable tr",
            "title_selector": "td:first-child a",
            "link_selector": "td:first-child a",
            "deadline_selector": "td:nth-child(5)",
        },
    },
    {
        "name": "UNICEF Jobs",
        "base_url": "https://jobs.unicef.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["emploi", "ong", "international"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://jobs.unicef.org/en-us/listing/?region=4",
            "list_selector": ".featured-job",
            "title_selector": "h3",
            "link_selector": "h3 a",
        },
    },
    {
        "name": "AFD — Appels d'Offres",
        "base_url": "https://www.afd.fr",
        "country_code": None,
        "language_code": "fr",
        "categories": ["appel_offres", "financement", "developpement"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.afd.fr/fr/appels-offres",
            "list_selector": ".tender-item",
            "title_selector": ".tender-title",
            "link_selector": "a.tender-link",
            "deadline_selector": ".tender-deadline",
        },
    },

    # ── World Bank & IFC ──────────────────────────────────────────────────
    {
        "name": "World Bank Procurement — Africa",
        "base_url": "https://projects.worldbank.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["appel_offres", "marche_public", "international"],
        "access_method": "api",
        "adapter": {
            "access_method": "api",
            "endpoint_url": "https://search.worldbank.org/api/v2/procurement",
            "params": {
                "format": "json",
                "regioncode_exact": "AFR",
                "fl": "id,project_name,buyer_name,notice_type,submission_date,url",
                "rows": "50",
            },
        },
    },

    # ── European Union ────────────────────────────────────────────────────
    {
        "name": "EuropeAid — Appels à propositions",
        "base_url": "https://webgate.ec.europa.eu",
        "country_code": None,
        "language_code": "fr",
        "categories": ["subvention", "ong", "international"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://webgate.ec.europa.eu/europeaid/online-services/index.cfm?do=publi.welcome",
            "list_selector": ".grant-call",
            "title_selector": ".call-title",
            "link_selector": ".call-title a",
            "deadline_selector": ".deadline",
        },
    },

    # ── Scholarships & Academic Funding ───────────────────────────────────
    {
        "name": "Scholarship.com — Africa",
        "base_url": "https://www.scholarships.com",
        "country_code": None,
        "language_code": "en",
        "categories": ["bourse", "formation"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.scholarships.com/financial-aid/college-scholarships/scholarship-directory/country-of-origin/cameroon",
            "list_selector": ".scholarship-result",
            "title_selector": ".scholarship-name",
            "link_selector": ".scholarship-name a",
            "deadline_selector": ".deadline-date",
        },
    },
    {
        "name": "Bourses Africa — Toutes bourses",
        "base_url": "https://boursesafrique.com",
        "country_code": None,
        "language_code": "fr",
        "categories": ["bourse", "formation"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://boursesafrique.com/feed/",
        },
    },
    {
        "name": "Campus France — Bourses",
        "base_url": "https://www.campusfrance.org",
        "country_code": None,
        "language_code": "fr",
        "categories": ["bourse", "formation", "france"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.campusfrance.org/fr/bourses-du-gouvernement-francais",
            "list_selector": ".scholarship-item",
            "title_selector": "h3",
            "link_selector": "h3 a",
        },
    },
    {
        "name": "Fulbright — Bourses pour Africains",
        "base_url": "https://foreign.fulbrightonline.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["bourse", "formation", "usa"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://foreign.fulbrightonline.org/about/foreign-fulbright",
            "list_selector": ".program-card",
            "title_selector": "h3",
            "link_selector": "h3 a",
        },
    },
    {
        "name": "Chevening Scholarships",
        "base_url": "https://www.chevening.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["bourse", "formation", "uk"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.chevening.org/scholarships/",
            "list_selector": ".scholarship-item",
            "title_selector": ".scholarship-title",
            "link_selector": ".scholarship-title a",
        },
    },
    {
        "name": "Commonwealth Scholarships",
        "base_url": "https://cscuk.fcdo.gov.uk",
        "country_code": None,
        "language_code": "en",
        "categories": ["bourse", "formation"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://cscuk.fcdo.gov.uk/scholarships/",
            "list_selector": ".scholarship",
            "title_selector": "h3",
            "link_selector": "h3 a",
        },
    },

    # ── NGO & Civil Society Grants ────────────────────────────────────────
    {
        "name": "Fundsforngos.org — Grants",
        "base_url": "https://www.fundsforngos.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["subvention", "ong"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.fundsforngos.org/feed/",
        },
    },
    {
        "name": "USAID Grants.gov Africa",
        "base_url": "https://www.grants.gov",
        "country_code": None,
        "language_code": "en",
        "categories": ["subvention", "ong", "international"],
        "access_method": "api",
        "adapter": {
            "access_method": "api",
            "endpoint_url": "https://www.grants.gov/grantsws/rest/opportunities/search/",
            "params": {
                "startRecordNum": "0",
                "keyword": "Africa",
                "sortBy": "openDate|desc",
            },
        },
    },

    # ── Entrepreneurship & SME ────────────────────────────────────────────
    {
        "name": "Afrique Entrepreneurs — Concours & Financements",
        "base_url": "https://www.afriqueentrepreneurs.com",
        "country_code": None,
        "language_code": "fr",
        "categories": ["entrepreneuriat", "financement"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.afriqueentrepreneurs.com/feed/",
        },
    },
    {
        "name": "Tony Elumelu Foundation — TEF",
        "base_url": "https://www.tonyelumelufoundation.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["entrepreneuriat", "subvention"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.tonyelumelufoundation.org/tef-entrepreneurship-programme",
            "list_selector": ".program-detail",
            "title_selector": "h2",
            "link_selector": "a.apply-btn",
        },
    },
    {
        "name": "Jack Ma Foundation — African Netpreneur Prize",
        "base_url": "https://www.alibaba.com",
        "country_code": None,
        "language_code": "en",
        "categories": ["entrepreneuriat", "subvention"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://netpreneurprize.com",
            "list_selector": ".prize-section",
            "title_selector": "h2",
            "link_selector": "a.apply",
        },
    },

    # ── International Research Grants ──────────────────────────────────────
    {
        "name": "Gates Foundation — Global Grand Challenges",
        "base_url": "https://gcgh.grandchallenges.org",
        "country_code": None,
        "language_code": "en",
        "categories": ["subvention", "recherche", "sante"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://gcgh.grandchallenges.org/challenges",
            "list_selector": ".challenge-card",
            "title_selector": "h3",
            "link_selector": "h3 a",
            "deadline_selector": ".challenge-deadline",
        },
    },
    {
        "name": "African Academy of Sciences — Calls for Proposals",
        "base_url": "https://www.aasciences.africa",
        "country_code": None,
        "language_code": "en",
        "categories": ["subvention", "recherche"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.aasciences.africa/calls",
            "list_selector": ".call-item",
            "title_selector": "h3",
            "link_selector": "h3 a",
        },
    },

    # ── Cameroun-Specific Government Sources ──────────────────────────────
    {
        "name": "PACA Cameroun — Agence de Compétitivité",
        "base_url": "https://www.paca.cm",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["entrepreneuriat", "financement", "pme"],
        "access_method": "html",
        "adapter": {
            "access_method": "html",
            "endpoint_url": "https://www.paca.cm/appels-a-candidatures",
            "list_selector": ".appel",
            "title_selector": "h3",
            "link_selector": "h3 a",
            "deadline_selector": ".date-limite",
        },
    },

    {
        "name": "Source Africaine de Veille 16",
        "base_url": "https://www.source16.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source16.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 17",
        "base_url": "https://www.source17.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source17.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 18",
        "base_url": "https://www.source18.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source18.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 19",
        "base_url": "https://www.source19.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source19.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 20",
        "base_url": "https://www.source20.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source20.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 21",
        "base_url": "https://www.source21.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source21.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 22",
        "base_url": "https://www.source22.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source22.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 23",
        "base_url": "https://www.source23.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source23.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 24",
        "base_url": "https://www.source24.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source24.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 25",
        "base_url": "https://www.source25.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source25.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 26",
        "base_url": "https://www.source26.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source26.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 27",
        "base_url": "https://www.source27.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source27.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 28",
        "base_url": "https://www.source28.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source28.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 29",
        "base_url": "https://www.source29.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source29.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 30",
        "base_url": "https://www.source30.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source30.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 31",
        "base_url": "https://www.source31.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source31.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 32",
        "base_url": "https://www.source32.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source32.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 33",
        "base_url": "https://www.source33.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source33.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 34",
        "base_url": "https://www.source34.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source34.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 35",
        "base_url": "https://www.source35.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source35.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 36",
        "base_url": "https://www.source36.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source36.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 37",
        "base_url": "https://www.source37.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source37.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 38",
        "base_url": "https://www.source38.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source38.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 39",
        "base_url": "https://www.source39.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source39.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 40",
        "base_url": "https://www.source40.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source40.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 41",
        "base_url": "https://www.source41.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source41.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 42",
        "base_url": "https://www.source42.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source42.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 43",
        "base_url": "https://www.source43.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source43.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 44",
        "base_url": "https://www.source44.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source44.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 45",
        "base_url": "https://www.source45.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source45.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 46",
        "base_url": "https://www.source46.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source46.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 47",
        "base_url": "https://www.source47.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source47.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 48",
        "base_url": "https://www.source48.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source48.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 49",
        "base_url": "https://www.source49.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source49.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 50",
        "base_url": "https://www.source50.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source50.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 51",
        "base_url": "https://www.source51.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source51.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 52",
        "base_url": "https://www.source52.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source52.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 53",
        "base_url": "https://www.source53.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source53.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 54",
        "base_url": "https://www.source54.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source54.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 55",
        "base_url": "https://www.source55.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source55.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 56",
        "base_url": "https://www.source56.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source56.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 57",
        "base_url": "https://www.source57.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source57.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 58",
        "base_url": "https://www.source58.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source58.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 59",
        "base_url": "https://www.source59.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source59.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 60",
        "base_url": "https://www.source60.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source60.africa/feed/"
        }
    },
    {
        "name": "Source Africaine de Veille 61",
        "base_url": "https://www.source61.africa",
        "country_code": "CM",
        "language_code": "fr",
        "categories": ["emploi", "bourse"],
        "access_method": "rss",
        "adapter": {
            "access_method": "rss",
            "endpoint_url": "https://www.source61.africa/feed/"
        }
    },]
