package util;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Logger centralisé pour l'application EtudAcadPro.
 * Écrit les logs dans un fichier et dans la console.
 * 
 * Niveaux de log : DEBUG, INFO, WARN, ERROR
 * 
 * Utilisation :
 *   AppLogger.info("MonServlet", "Action effectuée");
 *   AppLogger.error("MonDAO", "Erreur de connexion", exception);
 */
public final class AppLogger {

    public enum Level { DEBUG, INFO, WARN, ERROR }

    private static final DateTimeFormatter TIMESTAMP_FORMAT = 
        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");
    
    private static final String LOG_DIR = System.getProperty("user.home") + "/etudacadpro_logs";
    private static final String LOG_FILE = LOG_DIR + "/application.log";
    
    private static Level minLevel = Level.INFO;
    private static boolean consoleOutput = true;
    private static boolean fileOutput = true;

    static {
        try {
            File dir = new File(LOG_DIR);
            if (!dir.exists()) {
                dir.mkdirs();
            }
        } catch (Exception e) {
            System.err.println("Impossible de créer le répertoire de logs: " + e.getMessage());
            fileOutput = false;
        }
    }

    private AppLogger() {}

    public static void setMinLevel(Level level) {
        minLevel = level;
    }

    public static void setConsoleOutput(boolean enabled) {
        consoleOutput = enabled;
    }

    public static void setFileOutput(boolean enabled) {
        fileOutput = enabled;
    }

    public static void debug(String source, String message) {
        log(Level.DEBUG, source, message, null);
    }

    public static void info(String source, String message) {
        log(Level.INFO, source, message, null);
    }

    public static void warn(String source, String message) {
        log(Level.WARN, source, message, null);
    }

    public static void warn(String source, String message, Throwable throwable) {
        log(Level.WARN, source, message, throwable);
    }

    public static void error(String source, String message) {
        log(Level.ERROR, source, message, null);
    }

    public static void error(String source, String message, Throwable throwable) {
        log(Level.ERROR, source, message, throwable);
    }

    private static void log(Level level, String source, String message, Throwable throwable) {
        if (level.ordinal() < minLevel.ordinal()) {
            return;
        }

        String timestamp = LocalDateTime.now().format(TIMESTAMP_FORMAT);
        String threadName = Thread.currentThread().getName();
        String formattedMessage = String.format("[%s] [%s] [%s] [%s] %s",
            timestamp, level.name(), threadName, source, message);

        if (consoleOutput) {
            if (level == Level.ERROR) {
                System.err.println(formattedMessage);
                if (throwable != null) {
                    throwable.printStackTrace(System.err);
                }
            } else {
                System.out.println(formattedMessage);
                if (throwable != null) {
                    throwable.printStackTrace(System.out);
                }
            }
        }

        if (fileOutput) {
            writeToFile(formattedMessage, throwable);
        }
    }

    private static synchronized void writeToFile(String message, Throwable throwable) {
        try (PrintWriter writer = new PrintWriter(new FileWriter(LOG_FILE, true))) {
            writer.println(message);
            if (throwable != null) {
                throwable.printStackTrace(writer);
            }
        } catch (IOException e) {
            System.err.println("Erreur d'écriture dans le fichier de log: " + e.getMessage());
        }
    }

    /**
     * Log une requête HTTP (pour le débogage).
     */
    public static void logRequest(String servlet, String method, String path, String user) {
        if (minLevel.ordinal() <= Level.DEBUG.ordinal()) {
            debug(servlet, String.format("%s %s [user=%s]", method, path, user != null ? user : "anonymous"));
        }
    }

    /**
     * Log une exception avec stack trace complète.
     */
    public static void logException(String source, String action, Throwable e) {
        error(source, action + " - " + e.getClass().getSimpleName() + ": " + e.getMessage(), e);
    }

    /**
     * Log une opération de base de données.
     */
    public static void logDbOperation(String dao, String operation, Object id) {
        debug(dao, String.format("DB %s [id=%s]", operation, id != null ? id.toString() : "null"));
    }

    /**
     * Log un événement de sécurité.
     */
    public static void logSecurity(String event, String details) {
        warn("SECURITY", event + " - " + details);
    }
}
