package dao;

import model.Commentaire;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les Commentaires / Feedback sur les TPs
 */
public class CommentaireDAO {

    public List<Commentaire> findByTravail(Long travailId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT c FROM Commentaire c " +
                "LEFT JOIN FETCH c.auteur " +
                "WHERE c.travail.id = :id ORDER BY c.dateCreation ASC",
                Commentaire.class
            ).setParameter("id", travailId).getResultList();
        } finally { em.close(); }
    }

    public void save(Commentaire c) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(c);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    public void delete(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Commentaire c = em.find(Commentaire.class, id);
            if (c != null) em.remove(c);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }
}