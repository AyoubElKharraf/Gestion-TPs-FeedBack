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
    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=feedback"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold flex-1 truncate"><%= tp != null ? tp.getTitre() : "TP" %></span>
    <div class="flex items-center gap-3">
        <%-- Cloche notifications --%>
        <button id="notifBtn" type="button" onclick="toggleNotifPanel()"
                class="relative p-2 rounded-full hover:bg-blue-900 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (nbNotifs != null && nbNotifs > 0) { %>
            <span id="notifBadge"
                  class="absolute top-0 right-0 w-5 h-5 bg-red-500 rounded-full text-xs
                         flex items-center justify-center font-bold">
                <%= nbNotifs > 9 ? "9+" : nbNotifs %>
            </span>
            <% } %>
        </button>
        <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2 p-1 rounded-full hover:bg-blue-900 transition">
            <div class="w-9 h-9 bg-green-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
                <% if (userSession != null && userSession.getPrenom() != null && userSession.getNom() != null) {
                    String p = (userSession.getPrenom() != null && !userSession.getPrenom().isEmpty()) ? String.valueOf(userSession.getPrenom().charAt(0)) : "?";
                    String n = (userSession.getNom() != null && !userSession.getNom().isEmpty()) ? String.valueOf(userSession.getNom().charAt(0)) : "?";
                    out.print(p + n);
                } else { %>ET<% } %>
            </div>
        </button>
    </div>
</header>

<div id="profilePanel" class="fixed right-4 top-16 w-72 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b flex justify-between items-center">
        <span class="font-semibold text-gray-800">Profil</span>
        <button onclick="toggleProfilePanel()" class="text-gray-400 hover:text-gray-600 text-sm">✕</button>
    </div>
    <div class="px-4 py-4 text-sm text-gray-700 space-y-1">
        <p><span class="font-semibold">Nom :</span> <%= userSession != null && userSession.getNom() != null && userSession.getPrenom() != null ? userSession.getNomComplet() : "-" %></p>
        <p><span class="font-semibold">Email :</span> <%= userSession != null && userSession.getEmail() != null ? userSession.getEmail() : "-" %></p>
        <p><span class="font-semibold">Rôle :</span> <%= userSession != null && userSession.getRole() != null ? userSession.getRole().name() : "ETUDIANT" %></p>
    </div>
</div>

<%-- Panneau notifications (AJAX) --%>
<div id="notifPanel" class="fixed right-4 top-16 w-80 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b font-semibold text-primary flex justify-between items-center">
        <span>Notifications</span>
        <div class="flex gap-2">
            <a href="<%= ctx %>/NotificationServlet?action=tout-lire" class="text-xs text-blue-600 hover:underline">Tout lire</a>
            <button type="button" onclick="toggleNotifPanel()" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
    </div>
    <div id="notifList" class="divide-y max-h-72 overflow-y-auto">
        <div class="px-4 py-4 text-center text-gray-400 text-sm">Chargement...</div>
    </div>
    <div class="px-4 py-3 border-t text-center">
        <a href="<%= ctx %>/NotificationServlet" class="text-xs text-primary hover:underline">Voir toutes les notifications</a>
    </div>
</div>

<div class="flex flex-1">
    <%-- Sidebar (TPs & Feedback on the side for student) --%>
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full flex-shrink-0">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=modules"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Modules
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=devoirs"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                Mes TPs
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=feedback"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Feedback des TPs
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
            💬 Commentaires
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
                    <%= (c.getAuteur() != null && c.getAuteur().getPrenom() != null && !c.getAuteur().getPrenom().isEmpty()) ? String.valueOf(c.getAuteur().getPrenom().charAt(0)).toUpperCase() : "?" %>
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
<script>
    let notifLoaded = false;

    function toggleNotifPanel() {
        const panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && !notifLoaded) {
            loadNotifications();
        }
    }

    function loadNotifications() {
        fetch('<%= ctx %>/NotificationServlet?action=liste-json')
            .then(function(r) { return r.json(); })
            .then(function(data) {
                notifLoaded = true;
                const list = document.getElementById('notifList');
                if (!data || data.length === 0) {
                    list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>';
                    return;
                }
                list.innerHTML = data.map(function(n) {
                    var content = (n.expediteur ? '<p class="text-xs text-gray-500">De: ' + n.expediteur + '</p>' : '') +
                        '<p class="text-sm text-gray-700">' + (n.message || '') + '</p>' +
                        '<p class="text-xs text-gray-400 mt-0.5">' + (n.date || '') + '</p>' +
                        (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                    var cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                    var url = n.replyUrl || n.markReadUrl;
                    return url ? '<a href="' + url + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
                }).join('');
                var badge = document.getElementById('notifBadge');
                var nonLues = data.filter(function(n) { return !n.lu; }).length;
                if (badge) {
                    if (nonLues === 0) badge.remove();
                    else badge.textContent = nonLues > 9 ? '9+' : nonLues;
                }
            })
            .catch(function() {
                document.getElementById('notifList').innerHTML =
                    '<div class="px-4 py-4 text-center text-red-400 text-sm">Erreur de chargement.</div>';
            });
    }

    function toggleProfilePanel() {
        document.getElementById('profilePanel').classList.toggle('hidden');
    }

    document.addEventListener('click', function(e) {
        var notifPanel = document.getElementById('notifPanel');
        var notifBtn = document.getElementById('notifBtn');
        if (notifPanel && notifBtn && !notifPanel.contains(e.target) && !notifBtn.contains(e.target)) {
            notifPanel.classList.add('hidden');
        }
        var profilePanel = document.getElementById('profilePanel');
        var profileBtn = document.querySelector('button[onclick="toggleProfilePanel()"]');
        if (profilePanel && profileBtn && !profilePanel.contains(e.target) && !profileBtn.contains(e.target)) {
            profilePanel.classList.add('hidden');
        }
    });
</script>
</body>
</html>