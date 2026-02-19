package dao;

import model.Enseignant;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les Enseignants
 */
public class EnseignantDAO {

    public List<Enseignant> findAll() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT e FROM Enseignant e", Enseignant.class).getResultList();
        } finally {
            em.close();
        }
    }

    public Enseignant findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Enseignant.class, id);
        } finally {
            em.close();
        }
    }

    public void save(Enseignant e) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(e);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }

    public void update(Enseignant e) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.merge(e);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }

    public void delete(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Enseignant e = em.find(Enseignant.class, id);
            if (e != null) em.remove(e);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }
    public List<Enseignant> search(String keyword) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            String kw = "%" + keyword.toLowerCase() + "%";
            return em.createQuery(
                "SELECT e FROM Enseignant e WHERE LOWER(e.nom) LIKE :kw " +
                "OR LOWER(e.prenom) LIKE :kw OR LOWER(e.email) LIKE :kw " +
                "OR LOWER(e.specialite) LIKE :kw", Enseignant.class
            ).setParameter("kw", kw).getResultList();
        } finally { em.close(); }
    }

    public boolean emailExists(String email, Long excludeId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT COUNT(e) FROM Enseignant e WHERE e.email = :email AND e.id <> :id",
                Long.class
            ).setParameter("email", email)
             .setParameter("id", excludeId != null ? excludeId : -1L)
             .getSingleResult() > 0;
        } finally { em.close(); }
    }

    public long count() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT COUNT(e) FROM Enseignant e", Long.class)
                     .getSingleResult();
        } finally { em.close(); }
    }
}