<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    TravailPratique tp = (TravailPratique) request.getAttribute("tp");
    List<Commentaire> commentaires = (List<Commentaire>) request.getAttribute("commentaires");
    Boolean canUpdate = (Boolean) request.getAttribute("canUpdate");
    if (canUpdate == null) canUpdate = true;
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    boolean commented = "1".equals(request.getParameter("commented"));
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Détail TP – Étudiant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold flex-1 truncate"><%= tp != null ? tp.getTitre() : "TP" %></span>
    <% if (nbNotifs != null && nbNotifs > 0) { %>
    <span class="bg-red-500 text-xs text-white px-2 py-1 rounded-full font-bold"><%= nbNotifs %></span>
    <% } %>
</header>

<div class="flex flex-1">
    <%-- Sidebar (TPs & Feedback on the side for student) --%>
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full flex-shrink-0">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list#modulesSection"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Modules
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                Mes TPs & Feedback
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/></svg>
                Déposer / Modifier un TP
            </a>
            <a href="<%= ctx %>/etudiant/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                Envoyer un message
            </a>
            <div class="flex-1"></div>
            <a href="<%= ctx %>/LogoutServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-red-500 hover:bg-red-50 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                Déconnexion
            </a>
        </nav>
    </aside>
    <main class="flex-1 p-6 max-w-3xl w-full overflow-auto">
    <% if (commented) { %>
    <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">
        💬 Commentaire ajouté.
    </div>
    <% } %>

    <% if (tp == null) { %>
    <div class="bg-red-50 text-red-600 p-4 rounded-xl">TP introuvable.</div>
    <% } else {
        String statutColor = "bg-gray-100 text-gray-700";
        String statutLabel = "Soumis";
        switch (tp.getStatut()) {
            case EN_CORRECTION: statutColor = "bg-yellow-100 text-yellow-700"; statutLabel = "En correction"; break;
            case CORRIGE:       statutColor = "bg-green-100 text-green-700";   statutLabel = "Corrigé ✅"; break;
            case RENDU:         statutColor = "bg-blue-100 text-blue-700";     statutLabel = "Rendu"; break;
        }
    %>

    <%-- Info principale --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <div class="flex items-start justify-between mb-4">
            <div>
                <h2 class="text-xl font-bold text-primary">
                    <%= tp.getTitre() %>
                    <% if (tp.getVersion() > 1) { %>
                    <span class="text-sm bg-purple-100 text-purple-600 px-2 py-0.5 rounded ml-1">
                        Version <%= tp.getVersion() %>
                    </span>
                    <% } %>
                </h2>
                <p class="text-gray-500 text-sm mt-1">
                    📚 <%= tp.getModule() != null ? tp.getModule().getNom() : "–" %>
                    <% if (tp.getModule() != null && tp.getModule().getEnseignant() != null) { %>
                    · 👨‍🏫 <%= tp.getModule().getEnseignant().getNomComplet() %>
                    <% } %>
                </p>
            </div>
            <span class="<%= statutColor %> text-sm px-3 py-1 rounded-full font-medium">
                <%= statutLabel %>
            </span>
        </div>

        <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
                <p class="text-gray-400 text-xs uppercase font-semibold">Déposé le</p>
                <p class="text-gray-700 mt-0.5"><%= sdf.format(tp.getDateSoumission()) %></p>
            </div>
            <% if (tp.getDateLimite() != null) { %>
            <div>
                <p class="text-gray-400 text-xs uppercase font-semibold">Date limite</p>
                <p class="text-gray-700 mt-0.5"><%= new SimpleDateFormat("dd/MM/yyyy").format(tp.getDateLimite()) %></p>
            </div>
            <% } %>
            <% if (tp.getNomFichier() != null) { %>
            <div>
                <p class="text-gray-400 text-xs uppercase font-semibold">Fichier</p>
                <p class="text-gray-700 mt-0.5 font-mono text-xs">📎 <%= tp.getNomFichier() %></p>
            </div>
            <% } %>
            <% if (tp.getNote() != null) { %>
            <div>
                <p class="text-gray-400 text-xs uppercase font-semibold">Note obtenue</p>
                <p class="text-2xl font-bold text-green-600 mt-0.5">
                    <%= tp.getNote() %><span class="text-sm font-normal text-gray-400">/20</span>
                </p>
            </div>
            <% } %>
        </div>

        <% if (tp.getDescription() != null && !tp.getDescription().isEmpty()) { %>
        <div class="mt-4 p-3 bg-gray-50 rounded-lg">
            <p class="text-xs text-gray-400 uppercase font-semibold mb-1">Description</p>
            <p class="text-sm text-gray-700"><%= tp.getDescription() %></p>
        </div>
        <% } %>
    </div>

    <%-- Actions (modifier / retirer) : seulement si SOUMIS et avant date limite --%>
    <% if (tp.getStatut() == TravailPratique.Statut.SOUMIS) { %>
    <div class="bg-white rounded-xl shadow p-4 mb-5 flex flex-wrap items-center gap-3">
        <% if (canUpdate) { %>
        <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&id=<%= tp.getId() %>"
           class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-blue-900 transition text-sm font-medium">
            Déposer une nouvelle version
        </a>
        <a href="<%= ctx %>/etudiant/DepotTPServlet?action=supprimer&id=<%= tp.getId() %>"
           onclick="return confirm('Supprimer ce TP ?');"
           class="px-4 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition text-sm font-medium">
            Retirer ce TP
        </a>
        <% } else { %>
        <p class="text-amber-700 text-sm">⏰ La date limite pour modifier ce TP est dépassée.</p>
        <% } %>
    </div>
    <% } %>

    <%-- Section Commentaires / Feedback --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <h3 class="font-bold text-primary mb-4 flex items-center gap-2">
            💬 Feedback & Commentaires
            <span class="text-sm font-normal text-gray-400">
                (<%= commentaires != null ? commentaires.size() : 0 %>)
            </span>
        </h3>

        <% if (commentaires == null || commentaires.isEmpty()) { %>
        <p class="text-gray-400 text-sm text-center py-4">
            Aucun commentaire pour l'instant. L'enseignant n'a pas encore répondu.
        </p>
        <% } else { %>
        <div class="space-y-3 mb-5">
            <% for (Commentaire c : commentaires) {
                boolean isEnseignant = c.getAuteur() != null &&
                    c.getAuteur().getRole() == Utilisateur.Role.ENSEIGNANT;
            %>
            <div class="flex gap-3 <%= isEnseignant ? "flex-row" : "flex-row-reverse" %>">
                <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0
                            <%= isEnseignant ? "bg-purple-100 text-purple-700" : "bg-green-100 text-green-700" %>">
                    <%= c.getAuteur() != null ? String.valueOf(c.getAuteur().getPrenom().charAt(0)).toUpperCase() : "?" %>
                </div>
                <div class="max-w-xs <%= isEnseignant ? "" : "ml-auto" %>">
                    <div class="<%= isEnseignant ? "bg-purple-50 border border-purple-100" : "bg-green-50 border border-green-100" %>
                                rounded-xl px-4 py-2">
                        <p class="text-xs font-semibold mb-1
                                  <%= isEnseignant ? "text-purple-700" : "text-green-700" %>">
                            <%= c.getAuteur() != null ? c.getAuteur().getNomComplet() : "?" %>
                            <% if (isEnseignant) { %> · Enseignant<% } %>
                        </p>
                        <p class="text-sm text-gray-700"><%= c.getContenu() %></p>
                    </div>
                    <p class="text-xs text-gray-400 mt-1 <%= isEnseignant ? "" : "text-right" %>">
                        <%= sdf.format(c.getDateCreation()) %>
                    </p>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>

        <%-- Formulaire ajout commentaire --%>
        <form action="<%= ctx %>/etudiant/DepotTPServlet" method="POST" class="mt-4">
            <input type="hidden" name="action" value="commenter"/>
            <input type="hidden" name="travailId" value="<%= tp.getId() %>"/>
            <div class="flex gap-3">
                <input type="text" name="contenu" placeholder="Ajouter un commentaire..."
                       required maxlength="500"
                       class="flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary"/>
                <button type="submit"
                        class="bg-primary text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-900 transition">
                    Envoyer
                </button>
            </div>
        </form>
    </div>

    <% } %>
</main>
</div>
</body>
</html>