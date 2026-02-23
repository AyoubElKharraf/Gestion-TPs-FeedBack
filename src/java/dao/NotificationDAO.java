package dao;

import model.Notification;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les Notifications
 */
public class NotificationDAO {

    /** Conversation entre deux utilisateurs : tous les messages (notifications avec expéditeur et destinataire) entre userId1 et userId2, ordre chronologique. */
    public List<Notification> findConversation(Long userId1, Long userId2) {
        if (userId1 == null || userId2 == null) return java.util.Collections.emptyList();
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT DISTINCT n FROM Notification n LEFT JOIN FETCH n.expediteur LEFT JOIN FETCH n.destinataire " +
                "WHERE n.expediteur IS NOT NULL AND (" +
                " (n.destinataire.id = :u1 AND n.expediteur.id = :u2) OR (n.destinataire.id = :u2 AND n.expediteur.id = :u1)" +
                ") ORDER BY n.dateCreation ASC",
                Notification.class
            ).setParameter("u1", userId1).setParameter("u2", userId2).getResultList();
        } finally { em.close(); }
    }

    /** Toutes les notifications d'un utilisateur, non lues en premier (avec expéditeur pour affichage) */
    public List<Notification> findByDestinataire(Long utilisateurId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT n FROM Notification n LEFT JOIN FETCH n.expediteur " +
                "WHERE n.destinataire.id = :id ORDER BY n.lu ASC, n.dateCreation DESC",
                Notification.class
            ).setParameter("id", utilisateurId).getResultList();
        } finally { em.close(); }
    }

    /** Seulement les non lues */
    public List<Notification> findNonLues(Long utilisateurId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT n FROM Notification n WHERE n.destinataire.id = :id AND n.lu = false " +
                "ORDER BY n.dateCreation DESC",
                Notification.class
            ).setParameter("id", utilisateurId).getResultList();
        } finally { em.close(); }
    }

    /** Dernière date d'un message dans la conversation entre deux utilisateurs. */
    public java.util.Date getLastMessageDate(Long userId1, Long userId2) {
        if (userId1 == null || userId2 == null) return null;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<java.util.Date> list = em.createQuery(
                "SELECT n.dateCreation FROM Notification n WHERE n.expediteur IS NOT NULL AND (" +
                " (n.destinataire.id = :u1 AND n.expediteur.id = :u2) OR (n.destinataire.id = :u2 AND n.expediteur.id = :u1)" +
                ") ORDER BY n.dateCreation DESC",
                java.util.Date.class
            ).setParameter("u1", userId1).setParameter("u2", userId2).setMaxResults(1).getResultList();
            return list.isEmpty() ? null : list.get(0);
        } finally {
            em.close();
        }
    }

    /** Nombre de messages non lus reçus par destinataireId et envoyés par expediteurId. */
    public long countUnreadFrom(Long destinataireId, Long expediteurId) {
        if (destinataireId == null || expediteurId == null) return 0;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT COUNT(n) FROM Notification n WHERE n.destinataire.id = :dest AND n.expediteur.id = :exp AND n.lu = false",
                Long.class
            ).setParameter("dest", destinataireId).setParameter("exp", expediteurId).getSingleResult();
        } finally {
            em.close();
        }
    }

    /** Nombre de notifications non lues */
    public long countNonLues(Long utilisateurId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT COUNT(n) FROM Notification n " +
                "WHERE n.destinataire.id = :id AND n.lu = false",
                Long.class
            ).setParameter("id", utilisateurId).getSingleResult();
        } finally { em.close(); }
    }

    public void save(Notification n) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(n);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    /** Marquer une notification comme lue (uniquement si elle appartient au destinataire). */
    public boolean marquerLue(Long id, Long destinataireUserId) {
        if (id == null || destinataireUserId == null) return false;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Notification n = em.find(Notification.class, id);
            boolean ok = n != null && n.getDestinataire() != null && n.getDestinataire().getId().equals(destinataireUserId);
            if (ok) n.setLu(true);
            em.getTransaction().commit();
            return ok;
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    /** Marquer comme lues les notifications reçues par destinataireUserId et envoyées par expediteurId (ex: quand on ouvre la page "répondre" à un message). */
    public void marquerLuesFromExpediteur(Long destinataireUserId, Long expediteurId) {
        if (destinataireUserId == null || expediteurId == null) return;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.createQuery(
                "UPDATE Notification n SET n.lu = true WHERE n.destinataire.id = :dest AND n.expediteur.id = :exp AND n.lu = false"
            ).setParameter("dest", destinataireUserId).setParameter("exp", expediteurId).executeUpdate();
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }

    /** Marquer toutes les notifications d'un utilisateur comme lues */
    public void marquerToutesLues(Long utilisateurId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.createQuery(
                "UPDATE Notification n SET n.lu = true " +
                "WHERE n.destinataire.id = :id AND n.lu = false"
            ).setParameter("id", utilisateurId).executeUpdate();
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    public void delete(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Notification n = em.find(Notification.class, id);
            if (n != null) em.remove(n);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }
}