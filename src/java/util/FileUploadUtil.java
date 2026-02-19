package util;

import jakarta.servlet.http.Part;
import java.io.*;
import java.nio.file.*;
import java.util.UUID;

/**
 * Utilitaire pour la gestion des fichiers uploadés (TPs)
 */
public class FileUploadUtil {

    // Dossier de stockage – adaptez selon votre serveur WildFly
    public static final String UPLOAD_DIR = System.getProperty("user.home") + "/tp_uploads";

    // Extensions autorisées
    private static final String[] ALLOWED_EXT = {
        ".pdf", ".doc", ".docx", ".zip", ".rar",
        ".java", ".py", ".txt", ".png", ".jpg"
    };

    static {
        // Créer le dossier si inexistant
        new File(UPLOAD_DIR).mkdirs();
    }

    /**
     * Enregistre un fichier uploadé et retourne son chemin relatif unique
     */
    public static String sauvegarder(Part part, Long etudiantId) throws IOException {
        String nomOriginal = extraireNomFichier(part);
        if (nomOriginal == null || nomOriginal.isEmpty()) return null;

        // Vérifier l'extension
        String ext = obtenirExtension(nomOriginal).toLowerCase();
        boolean autorise = false;
        for (String a : ALLOWED_EXT) {
            if (a.equals(ext)) { autorise = true; break; }
        }
        if (!autorise) throw new IOException("Extension non autorisée : " + ext);

        // Générer un nom unique : etudiantId_UUID.ext
        String nomFichier = "etu" + etudiantId + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;

        // Créer sous-dossier par étudiant
        Path dossier = Paths.get(UPLOAD_DIR, "etudiant_" + etudiantId);
        Files.createDirectories(dossier);

        Path destination = dossier.resolve(nomFichier);
        try (InputStream input = part.getInputStream()) {
            Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
        }
        // Retourner le chemin relatif stocké en BD
        return "etudiant_" + etudiantId + "/" + nomFichier;
    }

    /** Supprime un fichier du disque */
    public static void supprimer(String cheminRelatif) {
        if (cheminRelatif == null) return;
        try {
            Files.deleteIfExists(Paths.get(UPLOAD_DIR, cheminRelatif));
        } catch (IOException ignored) {}
    }

    public static String extraireNomFichier(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return null;
        for (String token : header.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return null;
    }

    public static String obtenirExtension(String nom) {
        int i = nom.lastIndexOf('.');
        return i >= 0 ? nom.substring(i) : "";
    }

    public static long getTailleMax() { return 10 * 1024 * 1024; } // 10 Mo
}