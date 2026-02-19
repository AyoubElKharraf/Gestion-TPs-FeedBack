package dao;

import model.Module;
import model.Enseignant;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * DAO pour les Modules
 */
public class ModuleDAO {

    public List<Module> findAll() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT m FROM Module m LEFT JOIN FETCH m.enseignant", Module.class
            ).getResultList();
        } finally {
            em.close();
        }
    }

    public List<Module> findByFiliere(String filiere) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT m FROM Module m WHERE m.filiere = :filiere", Module.class
            ).setParameter("filiere", filiere).getResultList();
        } finally {
            em.close();
        }
    }

    public Module findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Module.class, id);
        } finally {
            em.close();
        }
    }

    public void save(Module m) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(m);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        } finally {
            em.close();
        }
    }

    public void update(Module m) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.merge(m);
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
            Module m = em.find(Module.class, id);
            if (m != null) em.remove(m);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        } finally {
            em.close();
        }
    }
    public List<Module> findByEnseignant(Long enseignantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT m FROM Module m WHERE m.enseignant.id = :id", Module.class
            ).setParameter("id", enseignantId).getResultList();
        } finally { em.close(); }
    }
}