package dao;

import model.Notification;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les Notifications
 */
public class NotificationDAO {

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

    /** Marquer une notification comme lue */
    public void marquerLue(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Notification n = em.find(Notification.class, id);
            if (n != null) n.setLu(true);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
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