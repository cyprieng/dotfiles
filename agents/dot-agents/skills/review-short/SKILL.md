---
name: review-short
description: >-
  Short code review listing only negative findings, numbered and concise, each
  with impact and a concrete recommendation. Use when the user asks for a
  review-short, short review, code review, or mentions "review".
---
Review the code or diff. Output **only negative points** — no positives, no summary, no "LGTM".

## Before reviewing

- Read the git diff against main (or the scope the user gave)
- Explore the codebase when context is missing
- Do NOT fix code unless asked

## Before outputting

- **Revérifier chaque point** avant de le lister : relire le code/diff concerné, tracer le flux si besoin
- Ne garder que les problèmes **confirmés** — supprimer tout point spéculatif, faux positif ou déjà géré ailleurs
- Vérifier que la préco corrige bien le problème identifié

## Output rules

- Numbered list only: `1.`, `2.`, …
- One issue per item, concise (1–2 lines max)
- Each item includes **Impact** (conséquence concrète si non corrigé) and **Préco** (action concrète)
- Cite location when possible: `` `path:line` ``
- Order by severity: bugs → security → correctness → design → maintainability
- If nothing to flag: output `Rien à signaler.`

## Format

```
1. [Problème] (`fichier:ligne`)
   Impact : [conséquence concrète]
   → Préco : [action concrète]

2. [Problème] (`fichier:ligne`)
   Impact : [conséquence concrète]
   → Préco : [action concrète]
```

## Example

```
1. Race condition si deux requêtes concurrentes (`api/users.ts:84`)
   Impact : doublons en base ou état incohérent pour l'utilisateur
   → Préco : utiliser un lock DB ou une contrainte unique + retry

2. Secret en clair dans le diff (`config.ts:12`)
   Impact : fuite de credentials si le repo est exposé ou partagé
   → Préco : déplacer vers une variable d'env et rotationner la clé
```
