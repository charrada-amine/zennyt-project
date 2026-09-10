import java.text.Normalizer;
import java.util.*;

/**
 * Combien coûte réellement une détection par mots clés sur un texte d'offre ?
 *
 * <p>Mesure le pire cas raisonnable : profil entreprise + description de poste réunis
 * (~1 900 mots, soit une offre très bavarde), balayés contre un dictionnaire de
 * 60 expressions réparties sur les 6 profils de culture du cahier des charges.
 */
public class BenchDetection {

    static final Map<String, String[]> DICTIONNAIRE = new LinkedHashMap<>();
    static {
        DICTIONNAIRE.put("Innovation", new String[]{
            "innovation", "creativite", "experimentation", "agilite", "disruption",
            "nouvelles idees", "esprit creatif", "prototypage", "veille technologique", "r&d"});
        DICTIONNAIRE.put("Rigueur", new String[]{
            "rigueur", "precision", "procedures", "conformite", "methode",
            "controle qualite", "normes", "tracabilite", "audit", "documentation"});
        DICTIONNAIRE.put("Autonomie", new String[]{
            "autonomie", "ownership", "initiative", "oriente data", "prise de risque",
            "sens des responsabilites", "force de proposition", "entrepreneurial",
            "decision rapide", "autonome"});
        DICTIONNAIRE.put("Performance", new String[]{
            "excellence operationnelle", "oriente resultats", "discipline", "delivery",
            "objectifs ambitieux", "performance", "productivite", "respect des delais",
            "kpi", "execution"});
        DICTIONNAIRE.put("Collaboration", new String[]{
            "bienveillance", "collectif", "ecoute", "diversite", "esprit d equipe",
            "entraide", "inclusion", "communication", "travail en equipe", "convivialite"});
        DICTIONNAIRE.put("Technique", new String[]{
            "expertise technique pointue", "certification exigee", "maitrise avancee",
            "niveau expert", "competences techniques", "diplome exige", "specialiste",
            "technologies avancees", "stack technique", "certifie"});
    }

    /** Profil entreprise + description de poste, en français réaliste. */
    static String corpus() {
        String profil = """
            Fondee en 2015, notre entreprise accompagne les organisations dans leur transformation
            numerique. Nous croyons profondement en la bienveillance et en l esprit d equipe : chaque
            collaborateur dispose d une reelle autonomie sur son perimetre et nous encourageons la
            force de proposition a tous les niveaux. Notre culture repose sur l innovation continue,
            l experimentation et une exigence de qualite qui ne transige jamais. Nous investissons
            chaque annee dans la formation de nos equipes et dans la veille technologique.
            L inclusion et la diversite ne sont pas des slogans chez nous mais des pratiques
            quotidiennes, mesurees et suivies. Nous privilegions un management par la confiance,
            des objectifs clairs et une communication transparente entre toutes les equipes.
            """;
        String poste = """
            Nous recherchons un profil confirme pour rejoindre notre pole produit. Vous prendrez en
            charge la conception et la mise en oeuvre des parcours utilisateurs, en lien etroit avec
            les equipes techniques et metier. Le poste demande une reelle autonomie et un sens des
            responsabilites developpe : vous serez le referent de votre domaine et vous piloterez
            vos sujets de bout en bout. Une maitrise avancee des outils de conception est attendue,
            ainsi qu une sensibilite forte aux enjeux d accessibilite. Vous travaillerez dans un
            environnement collaboratif ou le travail en equipe et l ecoute sont essentiels. Nous
            attachons de l importance au respect des delais et a une execution soignee. Le
            prototypage rapide et l experimentation font partie de votre quotidien. Une
            certification dans le domaine serait un plus apprecie mais n est pas exigee.
            """;
        // Gonflé pour approcher le pire cas : une page "A propos" tres bavarde.
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 3; i++) sb.append(profil).append(poste);
        return sb.toString();
    }

    /** Normalisation : minuscules, accents retires, ponctuation ramenee a des espaces. */
    static String normaliser(String texte) {
        String sansAccent = Normalizer.normalize(texte.toLowerCase(Locale.FRENCH), Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "");
        return " " + sansAccent.replaceAll("[^a-z0-9&]+", " ").trim() + " ";
    }

    static Map<String, Integer> detecter(String texteNormalise) {
        Map<String, Integer> parProfil = new LinkedHashMap<>();
        for (var entree : DICTIONNAIRE.entrySet()) {
            int distinctes = 0;
            for (String expression : entree.getValue()) {
                if (texteNormalise.contains(" " + expression + " ")) distinctes++;
            }
            if (distinctes > 0) parProfil.put(entree.getKey(), distinctes);
        }
        return parProfil;
    }

    public static void main(String[] args) {
        String brut = corpus();
        int mots = brut.split("\\s+").length;
        int expressions = DICTIONNAIRE.values().stream().mapToInt(a -> a.length).sum();

        // Chauffe de la JVM — sans elle on mesure le compilateur, pas l'algorithme.
        for (int i = 0; i < 20_000; i++) detecter(normaliser(brut));

        int tours = 20_000;
        long debut = System.nanoTime();
        Map<String, Integer> dernier = null;
        for (int i = 0; i < tours; i++) dernier = detecter(normaliser(brut));
        long ns = (System.nanoTime() - debut) / tours;

        System.out.println("Corpus            : " + mots + " mots (profil entreprise + offre, x3)");
        System.out.println("Dictionnaire      : " + expressions + " expressions sur "
            + DICTIONNAIRE.size() + " profils");
        System.out.println("Temps par offre   : " + String.format(Locale.FRENCH, "%.3f", ns / 1000.0)
            + " microsecondes  (" + String.format(Locale.FRENCH, "%.5f", ns / 1_000_000.0) + " ms)");
        System.out.println("Debit theorique   : " + String.format(Locale.FRENCH, "%,d", 1_000_000_000L / ns)
            + " offres par seconde sur un seul coeur");
        System.out.println("Signaux detectes  : " + dernier);

        // Le meme calcul, mais sur 10 000 offres — l'echelle d'un rattrapage complet.
        double totalMs = ns * 10_000 / 1_000_000.0;
        System.out.println("10 000 offres     : " + String.format(Locale.FRENCH, "%.1f", totalMs) + " ms au total");
    }
}
