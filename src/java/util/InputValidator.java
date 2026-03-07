package util;

import java.util.regex.Pattern;

/**
 * Utilitaire de validation des entrées utilisateur.
 * Fournit des méthodes pour valider et nettoyer les données saisies.
 */
public class InputValidator {

    // Patterns de validation
    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    
    private static final Pattern ALPHANUMERIC_PATTERN = 
        Pattern.compile("^[a-zA-Z0-9àâäéèêëïîôùûüçÀÂÄÉÈÊËÏÎÔÙÛÜÇ\\s'-]+$");
    
    private static final Pattern NUMERIC_PATTERN = 
        Pattern.compile("^[0-9]+$");

    /**
     * Valide une adresse email.
     */
    public static boolean isValidEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return false;
        }
        return EMAIL_PATTERN.matcher(email.trim()).matches();
    }

    /**
     * Valide un nom (lettres, espaces, tirets, apostrophes uniquement).
     */
    public static boolean isValidName(String name) {
        if (name == null || name.trim().isEmpty()) {
            return false;
        }
        return ALPHANUMERIC_PATTERN.matcher(name.trim()).matches();
    }

    /**
     * Valide une chaîne numérique (entier positif).
     */
    public static boolean isNumeric(String str) {
        if (str == null || str.trim().isEmpty()) {
            return false;
        }
        return NUMERIC_PATTERN.matcher(str.trim()).matches();
    }

    /**
     * Valide un identifiant Long.
     */
    public static Long parseId(String idStr) {
        if (idStr == null || idStr.trim().isEmpty()) {
            return null;
        }
        try {
            return Long.parseLong(idStr.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Nettoie une chaîne de caractères (supprime espaces superflus).
     */
    public static String sanitize(String input) {
        if (input == null) {
            return "";
        }
        return input.trim().replaceAll("\\s+", " ");
    }

    /**
     * Vérifie si une chaîne n'est pas vide après nettoyage.
     */
    public static boolean isNotEmpty(String input) {
        return input != null && !input.trim().isEmpty();
    }

    /**
     * Vérifie si une chaîne respecte une longueur maximale.
     */
    public static boolean isWithinLength(String input, int maxLength) {
        if (input == null) {
            return true;
        }
        return input.length() <= maxLength;
    }

    /**
     * Valide un mot de passe (minimum 6 caractères).
     */
    public static boolean isValidPassword(String password) {
        return password != null && password.length() >= 6;
    }

    /**
     * Valide un numéro de téléphone (format français simplifié).
     */
    public static boolean isValidPhone(String phone) {
        if (phone == null || phone.trim().isEmpty()) {
            return true; // Le téléphone est optionnel
        }
        String cleaned = phone.replaceAll("[\\s.-]", "");
        return cleaned.matches("^(0|\\+33)[0-9]{9}$");
    }
}
