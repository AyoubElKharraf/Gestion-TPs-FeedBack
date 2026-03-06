package dao;

import model.Enseignant;
import model.Utilisateur;
import model.Utilisateur.Role;
import util.PasswordUtil;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.TypedQuery;
import java.util.List;

/**
 * DAO pour les opérations sur les Utilisateurs
 */
public class UtilisateurDAO {

    /**
     * Authentifie un utilisateur par email et mot de passe (comparaison avec hash si stocké en hash).
     */
    public Utilisateur authenticate(String email, String motDePasse) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TypedQuery<Utilisateur> q = em.createQuery(
                "SELECT u FROM Utilisateur u WHERE u.email = :email",
                Utilisateur.class
            );
            q.setParameter("email", email);
            Utilisateur u = q.getSingleResult();
            if (u != null && PasswordUtil.verify(motDePasse, u.getMotDePasse())) {
                return u;
            }
            return null;
        } catch (NoResultException e) {
            return null;
        } finally {
            em.close();
        }
    }

    public List<Utilisateur> findAll() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT u FROM Utilisateur u", Utilisateur.class).getResultList();
        } finally {
            em.close();
        }
    }

    public Utilisateur findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Utilisateur.class, id);
        } finally {
            em.close();
        }
    }

    /** Tous les utilisateurs avec le rôle ADMIN (pour notifications alerte dépassement). */
    public List<Utilisateur> findByRole(Role role) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT u FROM Utilisateur u WHERE u.role = :role",
                Utilisateur.class
            ).setParameter("role", role).getResultList();
        } finally {
            em.close();
        }
    }

    public Enseignant findEnseignantById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Enseignant.class, id);
        } finally {
            em.close();
        }
    }

    public void save(Utilisateur u) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(u);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        } finally {
            em.close();
        }
    }

    public void update(Utilisateur u) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.merge(u);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        } finally {
            em.close();
        }
    }

    public void delete(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            Utilisateur u = em.find(Utilisateur.class, id);
            if (u != null) em.remove(u);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        } finally {
            em.close();
        }
    }
}