# Journal du binôme

## TP01
- PR fusionnées : #1 (`POST /reset`), #2 (en-tête `X-Visites-Version`), #5 (titre du README),
  #3 (titre concurrent de #5 : conflit résolu par `git rebase origin/main`), #4 (CONTRIBUTING.md),
  #6 (pre-commit).
- Version : tag annoté et signé (SSH) `v0.1.0` sur `599b4ca`, poussé par @CSliveR.

### Questions d'observation
- Q1. Délai de changement : premier commit `21aab8b` (« feat(api): ajouter POST /reset… »)
  le 09/11/2026 à 11 h 44, fusion de la PR #1 sur `main` à 15 h 28 : **3 h 44 min**.
  L'essentiel du délai est de l'attente de relecture, pas du travail sur le code. À comparer
  avec la mesure faite à la restitution.
- Q2. Indépendant de GitHub (marche tel quel sur GitLab, Gitea, Forgejo) : Git lui-même
  (branches, commits conventionnels, `rebase`, résolution de conflit, `push --force-with-lease`),
  la signature SSH des commits et du tag `v0.1.0`, pre-commit et ruff, `CONTRIBUTING.md`.
  Ce qui change : les commandes `gh` (`gh pr create`, `gh pr merge --squash`) deviennent `glab`,
  `tea` ou l'interface web ; la « pull request » s'appelle « merge request » sur GitLab ;
  les règles de protection de branche, la revue obligatoire et le badge « Verified »
  se reconfigurent dans chaque forge.
- Q3. La forge vérifie qui *pousse* (authentification du compte), pas qui a *écrit* : l'auteur
  d'un commit est une chaîne libre (`git config user.name/user.email`), n'importe qui peut
  écrire un commit au nom d'un autre. Si un collègue pousse un clone contenant mes commits, ou
  si le dépôt est migré vers une autre forge, l'information « qui a poussé » est perdue.
  La signature, elle, voyage avec le commit et se vérifie partout avec la clé publique.

## TP02 — Protéger le dépôt
- Scan de l'historique : `gitleaks git --verbose --redact --log-opts="--all" .` (gitleaks 8.30.1),
  toutes les branches : **aucun secret trouvé**. `.gitleaksignore` est créé vide (commentaires).
- Si un secret apparaît : le révoquer immédiatement (GitHub → Settings → Developer settings →
  Personal access tokens), en recréer un avec le moindre privilège, le ranger dans un secret de
  dépôt. On ne réécrit pas l'historique d'un dépôt déjà partagé : le secret est déjà exposé, seule la
  rotation protège. On ajoute alors son empreinte à `.gitleaksignore`.
- Prévention locale : hook `gitleaks` ajouté à `.pre-commit-config.yaml`.
- `CODEOWNERS` : revue automatique demandée au propriétaire du dossier touché.
- `dependabot.yml` : mises à jour hebdomadaires pip, GitHub Actions, Docker (`fastapi==0.120.0`
  est volontairement en retard pour voir arriver une PR Dependabot).
- Côté GitHub (administrateur du dépôt : @CSliveR) : ruleset sur `main` (PR obligatoire,
  1 approbation, revue des code owners, pas de force-push ni de suppression, historique linéaire),
  Secret scanning + Push protection, alertes Dependabot.
- Q1. Règles qui auraient bloqué un secret : revue obligatoire (humaine) ; gitleaks en pre-commit,
  gitleaks en CI comme contrôle requis, push protection GitHub (automatiques). La plus fiable :
  le contrôle côté serveur (CI requise, push protection), qui ne dépend pas du poste.
- Q2. Non : pre-commit est local et contournable (`--no-verify`, hook non installé). Il faut
  `pre-commit run --all-files` (ou `gitleaks git`) dans le pipeline, et ce check requis par le ruleset.
- Q3. Quelques secondes à quelques minutes. GitHub Secret Scanning révoque automatiquement
  certains jetons partenaires (PAT GitHub, AWS, Azure, Slack, Stripe…) et prévient l'émetteur.

## TP03 — Premier pipeline d'intégration continue
- Étapes 1–2 (PR #9, #10) : `ci.yml` sur `push` (main) et `pull_request`, `permissions: contents: read`,
  ruff, `pre-commit run --all-files` (gitleaks compris), pytest avec couverture XML + HTML,
  `htmlcov/` publié en artefact (7 jours).
- Pourquoi le workflow tourne sur la PR alors que `main` n'a pas encore `ci.yml` : pour l'événement
  `pull_request`, GitHub lit les workflows dans le commit de fusion de la PR (`refs/pull/<n>/merge`),
  qui contient déjà le fichier ajouté par la branche.
- Couverture : 100 % sur les trois fichiers (`app/__init__.py` 0 instruction, `app/config.py` 6,
  `app/main.py` 40) ; aucun fichier n'est moins couvert que les autres.
- Seuil de couverture : oui, faire échouer sous un seuil (`--cov-fail-under=80` par exemple) pour
  empêcher la couverture de baisser sans qu'on le voie. Pas 100 % : les dernières lignes (erreurs
  rares, code défensif) coûtent cher à tester, poussent à écrire des tests artificiels, et une ligne
  exécutée n'est pas une ligne vérifiée.

### Matrice et cache (étape 3, PR #11)
| Exécution | test (py3.12) | test (py3.13) |
|---|---|---|
| Avant matrice (un seul job, run 43247075988) | — | 49 s (pip 9 s, pre-commit 33 s, pytest 1 s) |
| Matrice, 1re exécution, cache miss (run 43251228913) | 70 s | 61 s |
| Même run relancé (`gh run rerun`), cache hit | 20 s | 23 s |

- `cache: pip` de setup-python : la clé est un hash de `cache-dependency-path` (ici `pyproject.toml`,
  pas de `requirements.txt`) + OS + version de Python. Le journal indique « Cache restored successfully ».
- Ajout d'un `actions/cache` sur `~/.cache/pre-commit` (clé : `.pre-commit-config.yaml`) : c'est lui
  qui fait le gros du gain (pre-commit 33–42 s → moins d'1 s) ; pip ne gagne que 2–3 s (11 s → 8–9 s).
- Avec la matrice, deux checks apparaissent sur la PR : `test (py3.12)` et `test (py3.13)`.
  Il faut exiger les **deux** dans le ruleset (c'est le nom du job, pas celui du workflow).

### Contrôle obligatoire (étape 4)
- Checks requis dans le ruleset `main` (actif) : `test (py3.12)`, `test (py3.13)`. Un push direct
  sur `main` est refusé : « Changes must be made through a pull request », « 2 of 2 required status
  checks are expected », « Commits must have verified signatures ».
- PR de test cassé : PR #13 (@CSliveR) bloquée par l'échec du test sur l'en-tête
  `X-Visites-Version` (« Required statuses must pass »), puis débloquée et fusionnée
  après un commit correctif rétablissant la valeur attendue.
- Bypass : un administrateur qui coche « bypass » fusionne malgré un check rouge. Ce droit doit être
  réservé à très peu de personnes (admin du dépôt, rôle d'urgence), jamais à tout le monde ;
  chaque contournement est tracé dans l'historique de la PR (« bypassed rule ») et dans
  Settings → Rules → Insights / le journal d'audit.

### act en local (étape 5)
- Poste macOS Apple Silicon (@jahid611) : act 0.2.97 (Homebrew) ; `act -l` liste le job `test`. Commande utilisée :
  `act pull_request --matrix python:3.13 --env SKIP=gitleaks --pull=false` → 46 s.
- `~/.actrc` : `-P ubuntu-latest=catthehacker/ubuntu:act-latest` et
  `--container-architecture linux/arm64`. Sur Mac Apple Silicon, `linux/amd64` (émulation) fait échouer
  setup-python : `tar: Cannot mkdir: Function not implemented`.
- Poste Linux x86_64 (@CSliveR) : `~/.actrc` configuré avec
  `-P ubuntu-latest=catthehacker/ubuntu:act-latest` et `--container-architecture linux/amd64` ;
  `act pull_request --matrix python:3.13` exécute tout le job `test` en local (~2 min 30 dont
  1 min 15 pour `pre-commit` incluant `gitleaks`), jusqu'à l'échec attendu de `upload-artifact`
  (`Unable to get the ACTIONS_RUNTIME_TOKEN env variable`).
- Identique à GitHub : checkout, setup-python (Python 3.13.18 téléchargé), `pip install`, ruff,
  hooks pre-commit, pytest (6 passed) : mêmes commandes, mêmes résultats.
- Ce qui diffère ou échoue en local :
  - `upload-artifact` : `Unable to get the ACTIONS_RUNTIME_TOKEN env variable`. Le stockage des
    artefacts est un service de GitHub, absent en local (sauf `--artifact-server-path`).
  - cache : « Cache not found » / « pip cache is not found ». Le cache GitHub n'existe pas dans le
    conteneur, chaque exécution act repart de zéro.
  - gitleaks sauté (`SKIP=gitleaks`) : le hook compile gitleaks en Go dans le conteneur, ce qui a
    saturé le disque de la machine (erreurs `input/output error`, `no space left on device`).
- act ne remplace pas GitHub Actions pour valider une PR : il ne fait ni checks requis, ni ruleset,
  ni artefacts, ni secrets du dépôt, et son image n'est pas exactement celle de GitHub. Il est
  indispensable pour mettre au point un workflow sans pousser à chaque essai, et pour reproduire
  hors ligne un job qui échoue.

### Questions d'observation
- Q1. Avec cache, le pipeline dure ~20–23 s par job (49–70 s sans). Le plus long sans cache :
  l'installation des environnements pre-commit (33–42 s), puis `pip install` (9–11 s) ; le démarrage
  de l'exécuteur est négligeable (1–2 s). Effet mesuré du cache : environ −65 %.
- Q2. Ce qui empêche de contourner le pipeline : le ruleset (PR obligatoire + checks requis + pas de
  bypass). Sans ruleset actif, une PR rouge reste fusionnable : le pipeline n'est qu'un avis.
- Q3. Gitea / Forgejo Actions : presque rien, déplacer le fichier dans `.gitea/workflows/` (même
  syntaxe, mêmes actions). GitLab CI : réécrire tout le fichier en `.gitlab-ci.yml` (`image: python:3.13`,
  `parallel: matrix`, `cache: key: files: [pyproject.toml]`, `artifacts: paths: [htmlcov/]`,
  `rules` au lieu de `on:`), mais les concepts sont les mêmes.
