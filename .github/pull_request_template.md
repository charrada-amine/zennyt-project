<!-- Merci de garder cette PR petite et focalisée : une user story = une PR. -->

## Contexte
<!-- Quel ticket cette PR adresse-t-elle ? Ex : Closes JOBS-12 -->
Closes #

## Ce que fait cette PR
<!-- Résumé en 2-3 phrases. Quel comportement change ? -->


## Bounded context / module concerné
- [ ] identity
- [ ] recruitment
- [ ] engagement
- [ ] analytics
- [ ] shared / core (⚠️ requiert l'approbation d'un référent)
- [ ] mobile (Flutter)
- [ ] infra / pipeline

## Definition of Done
- [ ] La CI est verte (build, tests, lint, scan de sécurité)
- [ ] Couverture de tests respectée (backend ≥ 80 %, Flutter ≥ 75 %)
- [ ] Branche rebasée sur `develop` (à jour)
- [ ] Aucun secret en clair dans le code ou la config
- [ ] Si le contrat d'API change : `contracts/*.openapi.yaml` mis à jour
- [ ] Si nouvelle communication inter-contexte : passe par un Domain Event (jamais d'appel direct)
- [ ] Documentation / ADR mise à jour si décision d'architecture

## Comment tester
<!-- Étapes pour qu'un relecteur vérifie le comportement -->
1.

## Captures / notes
<!-- Optionnel : captures d'écran mobile, logs, points d'attention pour le relecteur -->
