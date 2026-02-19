package dao;

import model.Rapport;
import jakarta.persistence.EntityManager;
import java.util.Date;
import java.util.List;
import java.util.ArrayList;

/**
 * DAO pour les rapports (documents déposés par l'enseignant par module).
 */
public class RapportDAO {

    public void save(Rapport r) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(r);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }

    public void update(Rapport r) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.merge(r);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }

    public Rapport findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Rapport.class, id);
        } finally {
            em.close();
        }
    }

    /** Charge le rapport avec module et enseignant (pour contrôle d'accès téléchargement). */
    public Rapport findByIdWithModule(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Rapport> list = em.createQuery(
                "SELECT r FROM Rapport r LEFT JOIN FETCH r.module m LEFT JOIN FETCH m.enseignant WHERE r.id = :id",
                Rapport.class
            ).setParameter("id", id).setMaxResults(1).getResultList();
            return list.isEmpty() ? null : list.get(0);
        } finally {
            em.close();
        }
    }

    /** Un rapport pour un module (le plus récent, pour compatibilité). */
    public Rapport findByModule(Long moduleId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Rapport> list = em.createQuery(
                "SELECT r FROM Rapport r WHERE r.module.id = :id ORDER BY r.dateCreation DESC",
                Rapport.class
            ).setParameter("id", moduleId).setMaxResults(1).getResultList();
            return list.isEmpty() ? null : list.get(0);
        } finally {
            em.close();
        }
    }

    /** Tous les rapports d'un module (du plus récent au plus ancien). */
    public List<Rapport> findAllByModule(Long moduleId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT r FROM Rapport r WHERE r.module.id = :id ORDER BY r.dateCreation DESC",
                Rapport.class
            ).setParameter("id", moduleId).getResultList();
        } finally {
            em.close();
        }
    }

    /** Date limite maximale parmi tous les rapports du module (pour autoriser modification TP). */
    public Date getMaxDateLimiteForModule(Long moduleId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Date> list = em.createQuery(
                "SELECT MAX(r.dateLimite) FROM Rapport r WHERE r.module.id = :id AND r.dateLimite IS NOT NULL",
                Date.class
            ).setParameter("id", moduleId).getResultList();
            return (list.isEmpty() || list.get(0) == null) ? null : list.get(0);
        } finally {
            em.close();
        }
    }

    /** Tous les rapports des modules d'un enseignant. */
    public List<Rapport> findByEnseignant(Long enseignantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT r FROM Rapport r JOIN r.module m WHERE m.enseignant.id = :id ORDER BY r.dateCreation DESC",
                Rapport.class
            ).setParameter("id", enseignantId).getResultList();
        } finally {
            em.close();
        }
    }

    /** Rapports d'un enseignant avec module chargé (pour affichage feed). */
    public List<Rapport> findByEnseignantWithModule(Long enseignantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT r FROM Rapport r LEFT JOIN FETCH r.module m WHERE m.enseignant.id = :id ORDER BY r.dateCreation DESC",
                Rapport.class
            ).setParameter("id", enseignantId).getResultList();
        } finally {
            em.close();
        }
    }

    /** Rapports pour les modules dont les id sont dans la liste (pour affichage côté étudiant). */
    public List<Rapport> findByModuleIds(List<Long> moduleIds) {
        if (moduleIds == null || moduleIds.isEmpty()) return new ArrayList<>();
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT r FROM Rapport r LEFT JOIN FETCH r.module WHERE r.module.id IN :ids",
                Rapport.class
            ).setParameter("ids", moduleIds).getResultList();
        } finally {
            em.close();
        }
    }

    public void delete(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Rapport r = em.find(Rapport.class, id);
            if (r != null) em.remove(r);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }
}
