# Deploiement production: Keycloak + provider custom GeoNature

Cette note documente la configuration recommandee pour utiliser Keycloak avec le provider custom `KeycloakOrganismProvider` dans GeoNature.

## 1) Architecture cible

- Authentification utilisateurs via le client Keycloak `geonature` (OIDC).
- Lecture technique des groupes/attributs via le client Keycloak `geonature-sync` (service account).
- Mapping des groupes:
  - Organismes: `/organismes/<slug>`
  - Reserves: `/reserves/<id>`
- Mapping des attributs vers GeoNature:
  - `t_roles.uuid_role` <= claim utilisateur Keycloak `sub`
  - `t_roles.id_organisme` <= organisme resolu depuis le groupe `/organismes/...`
  - `bib_organismes` alimente via `id_organisme`, `uuid_organisme`, `nom_organisme`

## 2) Configuration Keycloak

### 2.1 Client `geonature` (connexion utilisateurs)

- Type: OpenID Connect (confidential)
- Standard flow: ON
- Service account: OFF
- Redirect URI: `https://<api>/auth/authorize/keycloak`
- Web origins: `https://<frontend>`
- Scopes OIDC usuels: `openid profile email`

Mapper indispensable:
- `Group Membership`
  - Claim name: `groups`
  - Full group path: ON
  - Add to userinfo: ON
  - (optionnel) Add to ID/access token: ON

### 2.2 Client `geonature-sync` (service account)

- Type: OpenID Connect (confidential)
- Service account: ON
- Standard flow: OFF
- Redirect URI/Web origins: non requis

Roles du service account (client roles `realm-management`):
- minimum: `query-groups`
- selon la politique realm, ajouter les droits de lecture necessaires si `group-by-path`/`groups?search` est bloque

### 2.3 Groupes et attributs

Structure recommandee:
- `/organismes/<slug>`
- `/reserves/<id>`

Attributs sur chaque groupe organisme:
- `id_organisme` (entier)
- `uuid_organisme` (UUID)
- `nom_organisme` (optionnel)

## 3) Configuration GeoNature

Dans `config/geonature_config.toml`:

```toml
[AUTHENTICATION]
DEFAULT_RECONCILIATION_GROUP_ID = 1

[[AUTHENTICATION.PROVIDERS]]
module = "pypnusershub.auth.providers.default.LocalProvider"
id_provider = "local_provider"

[[AUTHENTICATION.PROVIDERS]]
module = "geonature.keycloak_provider.KeycloakOrganismProvider"
id_provider = "keycloak"

ISSUER = "https://<keycloak>/realms/<realm>"
CLIENT_ID = "geonature"
CLIENT_SECRET = "<secret_client_geonature>"

group_claim_name = "groups"
IDENTIFIER_FIELD = "preferred_username"
RECONCILIATE_ATTR = "email"
CODE_CHALLENGE_METHOD = "S256"

ORGANISM_GROUP_PREFIX = "/organismes/"
ORGANISM_UUID_CLAIM = "uuid_organisme"
ORGANISM_NAME_CLAIM = "organisme"
USER_UUID_CLAIM = "sub"

KEYCLOAK_ADMIN_CLIENT_ID = "geonature-sync"
KEYCLOAK_ADMIN_CLIENT_SECRET = "<secret_client_geonature_sync>"
KEYCLOAK_ADMIN_TIMEOUT = 5
```

## 4) Comportement du provider custom

Le provider `backend/geonature/keycloak_provider.py`:

1. Authentifie l'utilisateur via OIDC (`geonature`).
2. Lit `userinfo.groups`.
3. Selectionne le premier groupe commencant par `/organismes/`.
4. Interroge l'API admin Keycloak via `geonature-sync`:
   - tentative `group-by-path`
   - fallback `groups?search` + match exact sur `path`
5. Lit les attributs de groupe:
   - `id_organisme`
   - `uuid_organisme`
   - `nom_organisme` (fallback `group.name`)
6. Alimente `utilisateurs.bib_organismes` avec priorite:
   - `id_organisme` -> `uuid_organisme` -> `nom_organisme`
7. Alimente `utilisateurs.t_roles`:
   - `id_organisme`
   - `uuid_role` depuis claim utilisateur `sub`

## 5) Verification post-deploiement

### 5.1 Verification fonctionnelle

- Connexion d'un utilisateur de test Keycloak.
- Verifier l'absence d'erreur dans les logs backend.

### 5.2 Verification base de donnees

```sql
SELECT id_role, identifiant, uuid_role, id_organisme
FROM utilisateurs.t_roles
WHERE identifiant = '<login_test>';
```

```sql
SELECT id_organisme, uuid_organisme, nom_organisme
FROM utilisateurs.bib_organismes
WHERE id_organisme = <id_attendu>;
```

### 5.3 Verification sequence (si `id_organisme` force)

Si des IDs explicites sont injectes depuis Keycloak, resynchroniser la sequence:

```sql
SELECT setval(
  pg_get_serial_sequence('utilisateurs.bib_organismes', 'id_organisme'),
  (SELECT COALESCE(MAX(id_organisme), 1) FROM utilisateurs.bib_organismes),
  true
);
```

## 6) Securite production

- Rotation immediate des secrets utilises en phase de debug.
- TLS bout-en-bout (Keycloak, API, frontend).
- Ne jamais logger les tokens OIDC en production.
- Droits minimaux pour `geonature-sync` (lecture uniquement).
- Monitorer les warnings d'incoherence (`id_organisme`/`uuid_organisme`).
- Sauvegarde BDD avant mise en service.

## 7) Depannage rapide

- `uuid_role` non renseigne:
  - verifier claim `sub` dans `userinfo`
  - verifier `USER_UUID_CLAIM = "sub"`
- Organisme cree mais mauvais UUID:
  - verifier attribut `uuid_organisme` sur le groupe `/organismes/...`
- Erreur `group path does not exist`:
  - verifier path exact dans `userinfo.groups`
  - verifier fallback `groups?search` et droits admin du service account
- Erreur SQL sur UUID:
  - verifier que les UUID sont des chaines valides (format canonique)
