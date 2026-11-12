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
