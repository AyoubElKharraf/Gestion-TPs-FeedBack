package dao;

import model.AbsenceReport;
import model.Etudiant;
import model.Enseignant;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les signalements d'absence (appelés par l'application absence via REST).
 */
public class AbsenceReportDAO {

    public void save(AbsenceReport r) {
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

    /** Nombre total de signalements pour un étudiant. */
    public long countByEtudiant(Long etudiantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT COUNT(r) FROM AbsenceReport r WHERE r.etudiant.id = :id",
                Long.class
            ).setParameter("id", etudiantId).getSingleResult();
        } finally {
            em.close();
        }
    }

    /** Nombre d'enseignants distincts ayant signalé cet étudiant (pour règle "3 enseignants → aSupprimer"). */
    public long countDistinctEnseignantsByEtudiant(Long etudiantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT COUNT(DISTINCT r.enseignant.id) FROM AbsenceReport r WHERE r.etudiant.id = :id",
                Long.class
            ).setParameter("id", etudiantId).getSingleResult();
        } finally {
            em.close();
        }
    }
}
