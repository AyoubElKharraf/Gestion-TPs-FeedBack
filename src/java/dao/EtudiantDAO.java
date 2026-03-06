package dao;

import model.Etudiant;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.TypedQuery;
import java.util.List;

/**
 * DAO pour les opérations CRUD sur les Étudiants
 */
public class EtudiantDAO {

    /** Trouve un étudiant par email (pour API alerte-depassement depuis Gestion_AbsencesAlerts). */
    public Etudiant findByEmail(String email) {
        if (email == null || email.trim().isEmpty()) return null;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TypedQuery<Etudiant> q = em.createQuery(
                "SELECT e FROM Etudiant e WHERE LOWER(e.email) = LOWER(:email)",
                Etudiant.class
            );
            q.setParameter("email", email.trim());
            return q.getSingleResult();
        } catch (NoResultException e) {
            return null;
        } finally {
            em.close();
        }
    }

    public List<Etudiant> findAll() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT e FROM Etudiant e", Etudiant.class).getResultList();
        } finally {
            em.close();
        }
    }

    public List<Etudiant> findByFiliere(String filiere) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT e FROM Etudiant e WHERE e.filiere = :filiere", Etudiant.class
            ).setParameter("filiere", filiere).getResultList();
        } finally {
            em.close();
        }
    }

    public List<Etudiant> findFlaggedForDeletion() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT e FROM Etudiant e WHERE e.aSupprimer = true",
                Etudiant.class
            ).getResultList();
        } finally {
            em.close();
        }
    }

    public List<Etudiant> search(String keyword) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            String kw = "%" + keyword.toLowerCase() + "%";
            return em.createQuery(
                "SELECT e FROM Etudiant e WHERE LOWER(e.nom) LIKE :kw " +
                "OR LOWER(e.prenom) LIKE :kw OR LOWER(e.email) LIKE :kw " +
                "OR LOWER(e.numeroEtudiant) LIKE :kw", Etudiant.class
            ).setParameter("kw", kw).getResultList();
        } finally {
            em.close();
        }
    }

    public Etudiant findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Etudiant.class, id);
        } finally {
            em.close();
        }
    }

    public boolean emailExists(String email, Long excludeId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TypedQuery<Long> q = em.createQuery(
                "SELECT COUNT(e) FROM Etudiant e WHERE e.email = :email AND e.id <> :id",
                Long.class
            );
            q.setParameter("email", email);
            q.setParameter("id", excludeId != null ? excludeId : -1L);
            return q.getSingleResult() > 0;
        } finally {
            em.close();
        }
    }

    public void save(Etudiant e) {
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

    public void update(Etudiant e) {
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

    /**
     * Met à jour nbAbsences et aSupprimer pour un étudiant (appelé par l'API alerte-depassement).
     * Utilise un UPDATE JPQL pour garantir la persistance en base et l'affichage dans la liste admin.
     */
    public int updateAbsencesAndFlag(Long etudiantId, int nbAbsences, boolean aSupprimer) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            int updated = em.createQuery(
                "UPDATE Etudiant e SET e.nbAbsences = :nb, e.aSupprimer = :as WHERE e.id = :id"
            )
                .setParameter("nb", nbAbsences)
                .setParameter("as", aSupprimer)
                .setParameter("id", etudiantId)
                .executeUpdate();
            em.getTransaction().commit();
            return updated;
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
            Etudiant e = em.find(Etudiant.class, id);
            if (e != null) em.remove(e);
            em.getTransaction().commit();
        } catch (Exception ex) {
            em.getTransaction().rollback();
            throw ex;
        } finally {
            em.close();
        }
    }

    public long count() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT COUNT(e) FROM Etudiant e", Long.class)
                     .getSingleResult();
        } finally {
            em.close();
        }
    }
}