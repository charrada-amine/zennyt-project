# ADR-001 — Monolithe modulaire DDD déployé sur Azure App Service

- Statut : Accepté
- Date : 2026-06
- Décideurs : Tech Lead, équipe Zennyt

## Contexte

Nous démarrons le développement de Zennyt avec une équipe de 9 personnes
(6 back-end, 3 Flutter). Une architecture microservices avait été envisagée, mais
son coût d'infrastructure et sa complexité opérationnelle sont disproportionnés
pour une équipe de cette taille et un produit à ses débuts.

## Décision

1. **Architecture applicative** : monolithe modulaire suivant le Domain-Driven
   Design, organisé en 4 bounded contexts (identity, recruitment, engagement,
   analytics). Les contextes communiquent uniquement par Domain Events sur un
   event bus interne, jamais par appel direct.

2. **Plateforme de déploiement** : Azure App Service (conteneur Linux), et non
   Azure Container Apps. Pour un déployable unique, App Service offre un modèle
   plus simple : deployment slots pour le blue/green, autoscaling intégré,
   warm-up natif, et une courbe d'apprentissage minimale. Les capacités
   multi-services et le scaling event-driven d'ACA seraient sous-utilisés.

## Conséquences

Positives :
- Un seul déployable, une seule CI/CD, transactions ACID natives entre contextes.
- Blue/green trivial via slot swap, rollback par swap inverse en < 30s.
- Vélocité d'équipe maximale, pas d'expertise Kubernetes requise.

Négatives / points de vigilance :
- App Service ne propose pas de scale-to-zero sur les plans standard.
- Une migration future vers les microservices impliquera de revoir la couche
  de déploiement (bascule vers ACA ou AKS) — accepté comme coût futur.

## Signaux déclenchant une réévaluation (vers microservices)

- Contention de déploiement entre squads.
- Besoin de scaler un contexte indépendamment des autres.
- Violation répétée de l'isolation des bounded contexts en revue de code.

Tant que la règle « communication par Domain Events » est respectée, l'extraction
d'un bounded context en service séparé restera peu coûteuse.
