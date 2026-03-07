package dao;

import model.Etudiant;
import model.Enseignant;
import model.TravailPratique;
import model.TravailPratique.Statut;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les Travaux Pratiques – dépôt, correction, versions, feedback
 */
public class TravailPratiqueDAO {

    public List<TravailPratique> findAll() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "LEFT JOIN FETCH t.etudiant LEFT JOIN FETCH t.module " +
                "ORDER BY t.dateSoumission DESC", TravailPratique.class
            ).getResultList();
        } finally { em.close(); }
    }

    public List<TravailPratique> findByEtudiant(Long etudiantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "LEFT JOIN FETCH t.module " +
                "WHERE t.etudiant.id = :id ORDER BY t.dateSoumission DESC",
                TravailPratique.class
            ).setParameter("id", etudiantId).getResultList();
        } finally { em.close(); }
    }

    /** Étudiants distincts ayant déposé des TPs dans les modules de cet enseignant */
    public List<Etudiant> findEtudiantsByEnseignant(Long enseignantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT DISTINCT t.etudiant FROM TravailPratique t JOIN t.module m " +
                "WHERE m.enseignant.id = :id AND t.etudiant IS NOT NULL",
                Etudiant.class
            ).setParameter("id", enseignantId).getResultList();
        } finally { em.close(); }
    }

    /** Enseignants distincts ayant eu des TPs déposés par cet étudiant (pour notifications) */
    public List<Enseignant> findEnseignantsByEtudiant(Long etudiantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT DISTINCT e FROM TravailPratique t JOIN t.module m JOIN m.enseignant e " +
                "WHERE t.etudiant.id = :id",
                Enseignant.class
            ).setParameter("id", etudiantId).getResultList();
        } finally { em.close(); }
    }

    public List<TravailPratique> findByModule(Long moduleId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "LEFT JOIN FETCH t.etudiant " +
                "WHERE t.module.id = :id ORDER BY t.dateSoumission DESC",
                TravailPratique.class
            ).setParameter("id", moduleId).getResultList();
        } finally { em.close(); }
    }

    public List<TravailPratique> findByEnseignant(Long enseignantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "LEFT JOIN FETCH t.etudiant LEFT JOIN FETCH t.module m " +
                "WHERE m.enseignant.id = :id ORDER BY t.dateSoumission DESC",
                TravailPratique.class
            ).setParameter("id", enseignantId).getResultList();
        } finally { em.close(); }
    }

    public List<TravailPratique> findByStatut(Statut statut) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "LEFT JOIN FETCH t.etudiant LEFT JOIN FETCH t.module " +
                "WHERE t.statut = :statut ORDER BY t.dateSoumission DESC",
                TravailPratique.class
            ).setParameter("statut", statut).getResultList();
        } finally { em.close(); }
    }

    public TravailPratique findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(TravailPratique.class, id);
        } finally { em.close(); }
    }

    public void save(TravailPratique t) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(t);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    public TravailPratique update(TravailPratique t) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            TravailPratique merged = em.merge(t);
            em.getTransaction().commit();
            return merged;
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    public void delete(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            TravailPratique t = em.find(TravailPratique.class, id);
            if (t != null) em.remove(t);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback(); throw ex;
        } finally { em.close(); }
    }

    /** Supprime tous les TPs d'un étudiant (avant suppression de l'étudiant). */
    public void deleteByEtudiant(Long etudiantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<TravailPratique> list = em.createQuery(
                "SELECT t FROM TravailPratique t WHERE t.etudiant.id = :id",
                TravailPratique.class
            ).setParameter("id", etudiantId).getResultList();
            em.getTransaction().begin();
            for (TravailPratique t : list) {
                em.remove(em.contains(t) ? t : em.merge(t));
            }
            em.getTransaction().commit();
        } catch (Exception ex) {
            if (em.getTransaction().isActive()) em.getTransaction().rollback();
            throw ex;
        } finally { em.close(); }
    }

    public long countByStatut(Statut statut) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT COUNT(t) FROM TravailPratique t WHERE t.statut = :s", Long.class
            ).setParameter("s", statut).getSingleResult();
        } finally { em.close(); }
    }

    /**
     * Récupère l'historique des versions d'un TP (toutes les versions liées).
     * Remonte jusqu'à la racine puis récupère toute la chaîne descendante.
     */
    public List<TravailPratique> findVersionHistory(Long tpId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TravailPratique tp = em.find(TravailPratique.class, tpId);
            if (tp == null) return java.util.Collections.emptyList();

            // Remonter jusqu'à la version racine (version 1)
            TravailPratique root = tp;
            while (root.getParent() != null) {
                root = root.getParent();
            }

            // Récupérer toutes les versions par titre, étudiant et module
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "WHERE t.etudiant.id = :etudiantId " +
                "AND t.module.id = :moduleId " +
                "AND t.titre = :titre " +
                "ORDER BY t.version ASC",
                TravailPratique.class
            )
            .setParameter("etudiantId", root.getEtudiant().getId())
            .setParameter("moduleId", root.getModule().getId())
            .setParameter("titre", root.getTitre())
            .getResultList();
        } finally { em.close(); }
    }

    /**
     * Trouve la version racine (version 1) d'un TP.
     */
    public TravailPratique findRootVersion(Long tpId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TravailPratique tp = em.find(TravailPratique.class, tpId);
            if (tp == null) return null;
            while (tp.getParent() != null) {
                tp = tp.getParent();
            }
            return tp;
        } finally { em.close(); }
    }
}