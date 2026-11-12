# Contribuer à visites

## Flux de travail

1. Partir de `main` à jour :
   ```bash
   git switch main && git pull
   ```
2. Créer une branche courte, nommée selon son type : `feat/...`, `fix/...`, `docs/...`, `chore/...`
   ```bash
   git switch -c feat/ma-fonctionnalite
   ```
3. Faire des petits commits (un changement = un commit), signés.
4. Pousser la branche et ouvrir une pull request :
   ```bash
   git push -u origin feat/ma-fonctionnalite
   gh pr create --fill --base main
   ```
   Dans la description : **quoi**, **pourquoi**, **comment tester**.
5. **Revue** : l'autre membre relit le diff, teste la branche en local (`gh pr checkout <num>`)
   et laisse ses remarques. Les corrections se font par un **nouveau commit**
   (pas de `--amend` ni de force push sur une branche déjà relue).
6. Une fois la PR approuvée, **fusion par squash** : un seul commit sur `main`,
   avec un message conventionnel, et la branche distante est supprimée.
   ```bash
   gh pr merge <num> --squash --delete-branch
   ```
7. Pour mettre sa branche à jour avec `main` : `git rebase origin/main`, puis
   `git push --force-with-lease` (jamais `--force`). Pas de commit de fusion.

Aucune PR n'est fusionnée sans la revue de l'autre membre.

## Convention de commits

On suit [Conventional Commits](https://www.conventionalcommits.org/fr/) :

```
<type>(<portée optionnelle>): <description à l'impératif>
```

| Type | Usage |
|------|-------|
| `feat` | nouvelle fonctionnalité |
| `fix` | correction de bug |
| `test` | ajout ou modification de tests |
| `docs` | documentation |
| `style` | formatage, sans changement de comportement |
| `refactor` | réécriture sans changement de comportement |
| `chore` | outillage, configuration, dépendances |

Exemples : `feat(api): ajouter POST /reset`, `test(api): vérifier l'en-tête de version`.

Tous les commits et tags sont **signés** (clé SSH, voir `git config commit.gpgsign true`).

## Lancer le projet et les tests

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
docker run -d --name redis -p 6379:6379 redis:8-alpine

pytest -q                  # tests unitaires (Redis simulé)
pytest -q -m integration   # tests avec le vrai Redis
uvicorn app.main:app --reload
```

## pre-commit

Les hooks (vérifications de base + ruff) tournent à chaque commit.

```bash
pre-commit install          # une seule fois après le clone
pre-commit run --all-files  # lancer sur tout le dépôt
```

Si un hook échoue, il corrige souvent les fichiers lui-même : relire, refaire `git add`
puis recommencer le commit. Ne pas contourner avec `--no-verify`.
