# Journal du binôme

## TP01
- PR fusionnées : #1 (`POST /reset`), #2 (en-tête `X-Visites-Version`), #5 (titre du README),
  #3 (titre concurrent de #5 : conflit résolu par `git rebase origin/main`), #4 (CONTRIBUTING.md),
  #6 (pre-commit).

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
