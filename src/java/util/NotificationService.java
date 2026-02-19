package util;

import dao.NotificationDAO;
import model.Notification;
import model.Utilisateur;

/**
 * Service centralisé pour créer des notifications.
 * Appelé depuis les Servlets après chaque action importante.
 */
public class NotificationService {

    private static final NotificationDAO notifDAO = new NotificationDAO();

    /**
     * Crée et enregistre une notification pour un utilisateur
     */
    public static void envoyer(Utilisateur destinataire, String message) {
        if (destinataire == null || message == null) return;
        Notification n = new Notification();
        n.setDestinataire(destinataire);
        n.setMessage(message);
        notifDAO.save(n);
    }

    /**
     * Envoie un message (commentaire) d'un utilisateur à un autre (admin→enseignant/etudiant, enseignant→etudiant, etudiant→enseignant).
     */
    public static void envoyerMessage(Utilisateur expediteur, Utilisateur destinataire, String message) {
        if (expediteur == null || destinataire == null || message == null || message.isBlank()) return;
        Notification n = new Notification();
        n.setExpediteur(expediteur);
        n.setDestinataire(destinataire);
        n.setMessage(message.trim());
        notifDAO.save(n);
    }

    // Raccourcis sémantiques
    public static void tpDepose(Utilisateur enseignant, String nomEtudiant, String nomModule) {
        envoyer(enseignant,
            "📄 " + nomEtudiant + " a déposé un TP pour le module " + nomModule + ".");
    }

    public static void tpCorrige(Utilisateur etudiant, String nomModule, Double note) {
        String msg = note != null
            ? "✅ Votre TP (" + nomModule + ") a été corrigé. Note : " + note + "/20"
            : "✅ Votre TP (" + nomModule + ") a été corrigé. Consultez le feedback.";
        envoyer(etudiant, msg);
    }

    public static void nouveauCommentaire(Utilisateur destinataire, String auteur, String nomModule) {
        envoyer(destinataire,
            "💬 " + auteur + " a ajouté un commentaire sur le TP " + nomModule + ".");
    }

    public static void tpEnRetard(Utilisateur etudiant, String nomModule) {
        envoyer(etudiant,
            "⚠️ La date limite pour le TP " + nomModule + " est dépassée !");
    }
}