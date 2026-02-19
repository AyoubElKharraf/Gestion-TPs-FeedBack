package model;

import java.util.Date;

/**
 * Élément du fil d'activité (style Classroom) : rapport publié ou TP déposé.
 */
public class FeedItem {

    public enum Type { RAPPORT, TP }

    private final Type type;
    private final Date date;
    private final String title;
    private final String subtitle;
    private final String authorName;
    private final String actionUrl;
    private final String actionLabel;
    private final Long id;

    public FeedItem(Type type, Date date, String title, String subtitle, String authorName,
                    String actionUrl, String actionLabel, Long id) {
        this.type = type;
        this.date = date;
        this.title = title;
        this.subtitle = subtitle;
        this.authorName = authorName;
        this.actionUrl = actionUrl;
        this.actionLabel = actionLabel;
        this.id = id;
    }

    public Type getType() { return type; }
    public Date getDate() { return date; }
    public String getTitle() { return title; }
    public String getSubtitle() { return subtitle; }
    public String getAuthorName() { return authorName; }
    public String getActionUrl() { return actionUrl; }
    public String getActionLabel() { return actionLabel; }
    public Long getId() { return id; }
}
