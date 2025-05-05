# "iDoom Bookstore: La Lecture Numérique Simplifiée"
## Une Application Flutter & Django

---

## Diapositive 1: Introduction
**Titre: "Des Livres Numériques à Portée de Main"**

- Aperçu de l'application mobile iDoom Bookstore
- Problème: Accès limité aux livres numériques avec expérience personnalisée en Algérie
- Solution: Une plateforme intégrée pour découvrir et lire des livres numériques
- Stack technique: Flutter (frontend) + Django REST Framework (backend)
- Contexte du projet: Développé pour Algérie Télécom pour moderniser les services numériques

---

## Diapositive 2: Contexte du Projet
**Titre: "Répondre à une Demande Croissante"**

- Croissance du marché du livre numérique en Algérie
- Besoin d'Algérie Télécom d'une plateforme de lecture moderne
- Public cible: Grand public et employés/clients d'Algérie Télécom
- Objectifs clés: Modernisation des services numériques, amélioration de l'accès au contenu culturel
- Défi principal: Créer une expérience de lecture sécurisée et fluide

---

## Diapositive 3: Vue d'Ensemble de l'Architecture
**Titre: "Comment Tout Fonctionne Ensemble"**

- Architecture client-serveur avec communication API REST
- Backend Django avec base de données SQLite
- Frontend Flutter pour une expérience mobile multiplateforme
- Système de stockage de fichiers pour les livres (PDF, EPUB) et les images de couverture
- Flux d'authentification avec sécurité basée sur les tokens
- Compatibilité multiplateforme (Android, iOS, navigateurs web)

---

## Diapositive 4: Authentification Utilisateur
**Titre: "Accès Sécurisé & Simple"**

- Système d'authentification basé sur les tokens
- Vérification par email avec tokens courts
- Fonctionnalité de réinitialisation de mot de passe
- Stockage sécurisé avec FlutterSecureStorage
- Démonstration du flux d'inscription et de vérification

---

## Diapositive 5: Système de Sélection de Genres
**Titre: "Expérience de Lecture Personnalisée"**

- Modèle de genre avec catégories prédéfinies
- Intégration utilisateur avec sélection de genres
- Relation ManyToMany entre utilisateurs et genres
- API backend pour récupérer et mettre à jour les préférences
- Démonstration de l'écran de sélection de genres

---

## Diapositive 6: Découverte de Livres
**Titre: "Trouver des Livres Que Vous Aimerez"**

- Navigation des livres par genre
- Recommandations personnalisées "Pour Vous" basées sur les genres de l'utilisateur
- Section des nouvelles sorties
- Vue détaillée du livre avec métadonnées
- Implémentation du point d'API get_all_books

---

## Diapositive 7: Gestion des Livres
**Titre: "Votre Bibliothèque Numérique"**

- Collection de livres favoris de l'utilisateur
- Suivi de la progression de lecture
- Accès aux fichiers de livres (PDF/EPUB)
- Système de notation des livres
- Implémentation du modèle UserBookInteraction

---

## Diapositive 8: Stockage & Accès aux Fichiers
**Titre: "Livraison de Contenu Organisée"**

- Structure d'organisation des fichiers pour les livres
- Chemins de téléchargement personnalisés pour différents types de fichiers
- Validation des fichiers pour PDFs, EPUBs et images
- Accès sécurisé aux fichiers via des points d'API authentifiés
- Implémentation de la fonction book_file_path

---

## Diapositive 9: Gestion du Profil Utilisateur
**Titre: "Expérience Utilisateur Personnalisable"**

- Gestion des informations de profil
- Fonctionnalité de mise à jour du mot de passe
- Gestion des images de profil
- Mises à jour des préférences de genre
- Implémentation du point d'API updateProfile

---

## Diapositive 10: Système de Notation des Livres
**Titre: "Qualité Guidée par la Communauté"**

- Implémentation de soumission de notation
- Calcul de la notation moyenne
- Affichage des notations dans l'UI
- Validation backend des valeurs de notation
- Implémentation du point d'API submit_rating

---

## Diapositive 11: Fonctionnalité de Livres Favoris
**Titre: "Gardez Vos Favoris à Portée de Main"**

- Fonctionnalité de basculement des favoris
- Affichage des livres favoris
- Implémentation backend avec UserBookInteraction
- Intégration UI avec icônes de cœur
- Implémentation du point d'API toggle_favorite

---

## Diapositive 12: Suivi de la Progression de Lecture
**Titre: "Ne Perdez Jamais Votre Place"**

- Suivi du pourcentage de progression
- Stockage backend de la position de lecture
- Intégration UI avec indicateurs de progression
- Implémentation du point d'API update_progress
- Synchronisation multi-appareils

---

## Diapositive 13: Capacité de Lecture Hors Ligne
**Titre: "Lisez N'importe Où, N'importe Quand"**

- Implémentation de DownloadService pour le stockage local
- Visualisation PDF avec le widget PDFView
- Boîtes Hive pour stocker les données des livres
- Synchronisation de la progression entre les modes en ligne et hors ligne
- Démonstration de l'expérience de lecture hors ligne

---

## Diapositive 14: Intégration de Paiement
**Titre: "Achat de Livres Simplifié"**

- Implémentation du système de panier avec CartProvider
- Processus de paiement avec intégration Chargily
- Implémentation de WebView pour le paiement
- Suivi et historique des commandes
- Démonstration du flux d'achat

---

## Diapositive 15: Fonctionnalités Sociales
**Titre: "Se Connecter Par la Lecture"**

- Implémentation du système de commentaires
- Composants CommentWidget et CommentsSheet
- Images de profil utilisateur dans les commentaires
- Fonctionnalité de réponse
- Démonstration du système de commentaires

---

## Diapositive 16: Stratégie de Population de Données
**Titre: "Construire un Riche Catalogue de Livres"**

- Script de génération de données fictives
- Création aléatoire de livres avec métadonnées variées
- Attribution de genres aux livres
- Simulation d'interaction utilisateur
- Implémentation de dummy_data_script.py

---

## Diapositive 17: Défis Techniques & Solutions
**Titre: "Surmonter les Obstacles de Développement"**

- Défi: Gestion du stockage de fichiers pour différents formats de livres
  - Solution: Chemins de fichiers personnalisés et validateurs
- Défi: Suivi des préférences utilisateur
  - Solution: Relations ManyToMany avec le modèle Genre
- Défi: Système de notation des livres
  - Solution: Calculs agrégés pour les notations moyennes

---

## Diapositive 18: Optimisation des Performances
**Titre: "Vitesse et Efficacité"**

- Optimisation de la reconstruction des widgets
- Implémentation de la pagination pour les appels API
- Stratégies de mise en cache des données
- Utilisation de RepaintBoundary pour UI complexe
- Détails d'implémentation de optimizing_tips.txt

---

## Diapositive 19: Contraintes du Projet
**Titre: "Considérations de Développement"**

- Exigences de sécurité pour la protection des données utilisateur
- Défis de compatibilité multiplateforme
- Considérations de maintenance et d'évolutivité
- Optimisation des performances pour les appareils mobiles
- Implémentation d'un traitement de paiement sécurisé

---

## Diapositive 20: Conclusion
**Titre: "Une Solution Complète de Lecture Numérique"**

- Résumé des fonctionnalités clés implémentées
- Alignement avec les objectifs d'Algérie Télécom
- Avantages pour le marché algérien du livre numérique
- Réalisations techniques
- Leçons apprises pendant le développement
- Invitation aux questions-réponses

---

## Conseils de Présentation:

1. **Pour chaque démonstration de fonctionnalité:**
   - Montrer le code réel de la base de code
   - Démontrer la fonctionnalité sur un appareil réel
   - Expliquer les composants frontend et backend

2. **Supports visuels:**
   - Inclure des captures d'écran des écrans clés
   - Montrer des diagrammes de relation de modèles
   - Mettre en évidence des extraits de code importants de la base de code réelle

3. **Points d'intérêt technique:**
   - Relations de modèles Django (Livre-Genre, Utilisateur-Genre)
   - Implémentation de la gestion des fichiers
   - Flux d'authentification
   - Approche de gestion d'état Flutter

4. **Accent sur la valeur commerciale:**
   - Comment l'application modernise les services numériques d'Algérie Télécom
   - Améliorations de l'expérience utilisateur pour les lecteurs algériens
   - Avantages d'accès culturel et éducatif
   - Potentiel d'expansion future