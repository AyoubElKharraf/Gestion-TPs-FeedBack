package util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Utilitaire de hachage de mots de passe basé sur PBKDF2-like avec sel unique.
 * Plus sécurisé que SHA-256 simple car :
 * - Sel unique par mot de passe (stocké avec le hash)
 * - Itérations multiples pour ralentir les attaques
 * - Format auto-contenu : $algo$iterations$salt$hash
 * 
 * Format du hash stocké : $PBKDF2$10000$<salt_base64>$<hash_base64>
 */
public final class BCryptUtil {

    private static final String ALGORITHM = "SHA-256";
    private static final int ITERATIONS = 10000;
    private static final int SALT_LENGTH = 16;
    private static final int HASH_LENGTH = 32;
    private static final String PREFIX = "$PBKDF2$";
    
    private static final SecureRandom RANDOM = new SecureRandom();

    private BCryptUtil() {}

    /**
     * Hash un mot de passe avec un sel unique généré aléatoirement.
     * @param password Le mot de passe en clair
     * @return Le hash au format $PBKDF2$iterations$salt$hash
     */
    public static String hash(String password) {
        if (password == null || password.isEmpty()) {
            return null;
        }

        byte[] salt = new byte[SALT_LENGTH];
        RANDOM.nextBytes(salt);

        byte[] hash = pbkdf2(password, salt, ITERATIONS);
        
        String saltBase64 = Base64.getEncoder().encodeToString(salt);
        String hashBase64 = Base64.getEncoder().encodeToString(hash);
        
        return PREFIX + ITERATIONS + "$" + saltBase64 + "$" + hashBase64;
    }

    /**
     * Vérifie qu'un mot de passe correspond au hash stocké.
     * Compatible avec l'ancien format SHA-256 (pour migration progressive).
     */
    public static boolean verify(String password, String storedHash) {
        if (password == null || storedHash == null) {
            return false;
        }

        if (storedHash.startsWith(PREFIX)) {
            return verifyPbkdf2(password, storedHash);
        }
        
        if (storedHash.length() == 64 && storedHash.matches("[0-9a-fA-F]+")) {
            return PasswordUtil.verify(password, storedHash);
        }
        
        return storedHash.equals(password);
    }

    /**
     * Vérifie si un hash est au nouveau format PBKDF2.
     */
    public static boolean isNewFormat(String storedHash) {
        return storedHash != null && storedHash.startsWith(PREFIX);
    }

    /**
     * Indique si un mot de passe doit être mis à jour vers le nouveau format.
     */
    public static boolean needsRehash(String storedHash) {
        if (storedHash == null) return true;
        if (!storedHash.startsWith(PREFIX)) return true;
        
        try {
            String[] parts = storedHash.substring(PREFIX.length()).split("\\$");
            int iterations = Integer.parseInt(parts[0]);
            return iterations < ITERATIONS;
        } catch (Exception e) {
            return true;
        }
    }

    private static boolean verifyPbkdf2(String password, String storedHash) {
        try {
            String[] parts = storedHash.substring(PREFIX.length()).split("\\$");
            if (parts.length != 3) return false;
            
            int iterations = Integer.parseInt(parts[0]);
            byte[] salt = Base64.getDecoder().decode(parts[1]);
            byte[] expectedHash = Base64.getDecoder().decode(parts[2]);
            
            byte[] actualHash = pbkdf2(password, salt, iterations);
            
            return constantTimeEquals(expectedHash, actualHash);
        } catch (Exception e) {
            AppLogger.error("BCryptUtil", "Erreur de vérification du hash", e);
            return false;
        }
    }

    /**
     * Implémentation simplifiée de PBKDF2 avec SHA-256.
     */
    private static byte[] pbkdf2(String password, byte[] salt, int iterations) {
        try {
            MessageDigest md = MessageDigest.getInstance(ALGORITHM);
            byte[] passwordBytes = password.getBytes("UTF-8");
            
            byte[] hash = new byte[HASH_LENGTH];
            byte[] block = new byte[salt.length + passwordBytes.length];
            
            System.arraycopy(salt, 0, block, 0, salt.length);
            System.arraycopy(passwordBytes, 0, block, salt.length, passwordBytes.length);
            
            hash = md.digest(block);
            
            for (int i = 1; i < iterations; i++) {
                md.reset();
                md.update(hash);
                md.update(salt);
                hash = md.digest();
            }
            
            return hash;
        } catch (NoSuchAlgorithmException | java.io.UnsupportedEncodingException e) {
            AppLogger.error("BCryptUtil", "Erreur de hachage PBKDF2", e);
            return new byte[HASH_LENGTH];
        }
    }

    /**
     * Comparaison en temps constant pour éviter les attaques timing.
     */
    private static boolean constantTimeEquals(byte[] a, byte[] b) {
        if (a.length != b.length) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < a.length; i++) {
            result |= a[i] ^ b[i];
        }
        return result == 0;
    }
}
