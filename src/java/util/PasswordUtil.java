package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Utilitaire pour le hachage des mots de passe (SHA-256 avec sel).
 * Permet de ne pas stocker les mots de passe en clair.
 * En production, préférer BCrypt ou PBKDF2 avec un sel par utilisateur.
 */
public final class PasswordUtil {

    private static final String SALT = "EtudAcadPro#2025";
    private static final String ALGORITHM = "SHA-256";

    /**
     * Hash un mot de passe avec SHA-256 (sel + mot de passe).
     * @return Chaîne hexadécimale de 64 caractères, ou null en cas d'erreur
     */
    public static String hash(String password) {
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
            return null;
        }
    }

    /**
     * Vérifie que le mot de passe saisi correspond au hash stocké.
     * Compatible ancien stockage en clair : si stored ne fait pas 64 caractères hex, comparaison directe.
     */
    public static boolean verify(String inputPassword, String stored) {
        if (inputPassword == null || stored == null) return false;
        if (stored.length() == 64 && stored.matches("[0-9a-fA-F]+")) {
            return stored.equalsIgnoreCase(hash(inputPassword));
        }
        return stored.equals(inputPassword);
    }
}
