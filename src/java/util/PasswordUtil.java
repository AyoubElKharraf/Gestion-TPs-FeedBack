package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Utilitaire pour le hachage des mots de passe.
 * 
 * NOUVEAU : Utilise PBKDF2 (via BCryptUtil) pour les nouveaux mots de passe.
 * Maintient la compatibilité avec l'ancien format SHA-256.
 * 
 * Migration progressive : 
 * - Les nouveaux hash utilisent PBKDF2 (plus sécurisé)
 * - Les anciens hash SHA-256 restent vérifiables
 * - Lors d'une connexion réussie, le hash peut être mis à jour
 */
public final class PasswordUtil {

    private static final String SALT = "EtudAcadPro#2025";
    private static final String ALGORITHM = "SHA-256";
    
    private static final boolean USE_NEW_ALGORITHM = true;

    /**
     * Hash un mot de passe avec l'algorithme le plus sécurisé (PBKDF2).
     * @return Le hash sécurisé, ou null en cas d'erreur
     */
    public static String hash(String password) {
        if (password == null) return null;
        
        if (USE_NEW_ALGORITHM) {
            String newHash = BCryptUtil.hash(password);
            AppLogger.debug("PasswordUtil", "Nouveau hash PBKDF2 généré");
            return newHash;
        }
        
        return hashSha256(password);
    }

    /**
     * Hash avec l'ancien algorithme SHA-256 (pour compatibilité).
     */
    public static String hashSha256(String password) {
        if (password == null) return null;
        try {
            MessageDigest md = MessageDigest.getInstance(ALGORITHM);
            md.update(SALT.getBytes(StandardCharsets.UTF_8));
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(64);
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            AppLogger.error("PasswordUtil", "Erreur SHA-256", e);
            return null;
        }
    }

    /**
     * Vérifie que le mot de passe saisi correspond au hash stocké.
     * Compatible avec tous les formats :
     * - PBKDF2 (nouveau format, commence par $PBKDF2$)
     * - SHA-256 (ancien format, 64 caractères hex)
     * - Texte clair (très ancien, pour migration)
     */
    public static boolean verify(String inputPassword, String stored) {
        if (inputPassword == null || stored == null) return false;
        
        if (BCryptUtil.isNewFormat(stored)) {
            return BCryptUtil.verify(inputPassword, stored);
        }
        
        if (stored.length() == 64 && stored.matches("[0-9a-fA-F]+")) {
            return stored.equalsIgnoreCase(hashSha256(inputPassword));
        }
        
        return stored.equals(inputPassword);
    }

    /**
     * Indique si le hash stocké doit être mis à jour vers le nouveau format.
     * Utile pour la migration progressive lors des connexions.
     */
    public static boolean needsRehash(String storedHash) {
        return BCryptUtil.needsRehash(storedHash);
    }
}
