<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Notification> notifications = (List<Notification>) request.getAttribute("notifications");
    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    String retourUrl = ctx + "/LoginServlet";
    if (userSession != null) {
        switch (userSession.getRole()) {
            case ADMIN:      retourUrl = ctx + "/admin/DashboardServlet"; break;
            case ENSEIGNANT: retourUrl = ctx + "/enseignant/CorrectionTPServlet?action=list"; break;
            case ETUDIANT:   retourUrl = ctx + "/etudiant/DepotTPServlet?action=list"; break;
        }
    }
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Notifications – EtudAcadPro</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= retourUrl %>" class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold flex-1">Toutes les notifications</span>
    <% if (notifications != null && !notifications.isEmpty()) { %>
    <a href="<%= ctx %>/NotificationServlet?action=tout-lire"
       class="text-sm border border-white px-3 py-1 rounded-lg hover:bg-white hover:text-primary transition">
        Tout marquer lu
    </a>
    <% } %>
</header>

<main class="flex-1 p-6 max-w-2xl mx-auto w-full">
    <% if (notifications == null || notifications.isEmpty()) { %>
    <div class="bg-white rounded-xl shadow p-12 text-center text-gray-400">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-14 h-14 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                  d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
        </svg>
        <p class="font-medium">Aucune notification.</p>
    </div>
    <% } else { %>
    <div class="space-y-2">
        <% for (Notification n : notifications) {
            boolean canReply = false;
            String replyUrl = null;
            if (n.getExpediteur() != null && userSession != null) {
                if (userSession.getRole() == Utilisateur.Role.ADMIN) {
                    canReply = true;
                    replyUrl = ctx + "/admin/MessageServlet?destinataireId=" + n.getExpediteur().getId();
                } else if (userSession.getRole() == Utilisateur.Role.ETUDIANT && n.getExpediteur().getRole() == Utilisateur.Role.ENSEIGNANT) {
                    canReply = true;
                    replyUrl = ctx + "/etudiant/MessageServlet?destinataireId=" + n.getExpediteur().getId();
                } else if (userSession.getRole() == Utilisateur.Role.ENSEIGNANT && (n.getExpediteur().getRole() == Utilisateur.Role.ETUDIANT || n.getExpediteur().getRole() == Utilisateur.Role.ADMIN)) {
                    canReply = true;
                    replyUrl = ctx + "/enseignant/MessageServlet?destinataireId=" + n.getExpediteur().getId();
                }
            }
        %>
        <% if (canReply && replyUrl != null) { %>
        <a href="<%= replyUrl %>" class="block bg-white rounded-xl shadow-sm border <%= n.isLu() ? "border-gray-100" : "border-blue-200 bg-blue-50" %> px-5 py-4 flex items-start gap-4 hover:border-primary transition">
        <% } else { %>
        <div class="bg-white rounded-xl shadow-sm border <%= n.isLu() ? "border-gray-100" : "border-blue-200 bg-blue-50" %> px-5 py-4 flex items-start gap-4">
        <% } %>
            <div class="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0
                        <%= n.isLu() ? "bg-gray-100 text-gray-500" : "bg-blue-100 text-blue-600" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                </svg>
            </div>
            <div class="flex-1 min-w-0">
                <% if (n.getExpediteur() != null) { %>
                <p class="text-xs text-gray-500 mb-0.5">De : <%= n.getExpediteur().getNomComplet() %></p>
                <% } %>
                <p class="text-sm <%= n.isLu() ? "text-gray-600" : "text-gray-800 font-medium" %>">
                    <%= n.getMessage() %>
                </p>
                <p class="text-xs text-gray-400 mt-1">
                    <%= sdf.format(n.getDateCreation()) %>
                </p>
                <% if (canReply && replyUrl != null) { %>
                <p class="mt-2 text-xs text-primary font-medium">Cliquez pour répondre →</p>
                <% } %>
            </div>
            <% if (!n.isLu()) { %>
            <span class="w-2.5 h-2.5 bg-blue-500 rounded-full flex-shrink-0 mt-1"></span>
            <% } %>
        <% if (canReply && replyUrl != null) { %>
        </a>
        <% } else { %>
        </div>
        <% } %>
        <% } %>
    </div>
    <% } %>
</main>
</body>
</html>