<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur,model.TravailPratique,model.Module,model.Rapport,java.util.List,java.util.Date,java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<TravailPratique> travaux = (List<TravailPratique>) request.getAttribute("travaux");
    List<Module> modules = (List<Module>) request.getAttribute("modules");
    List<Rapport> rapports = (List<Rapport>) request.getAttribute("rapports");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    boolean success = "1".equals(request.getParameter("success"));
    boolean deleted = "1".equals(request.getParameter("deleted"));
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    Date now = new Date();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Mes TPs – Étudiant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<%-- HEADER --%>
<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace Étudiant</span>
    </div>
    <div class="flex items-center gap-3">
        <%-- Cloche notifications --%>
        <button id="notifBtn" onclick="toggleNotifPanel()"
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
        <div class="w-9 h-9 bg-green-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
            <%= userSession != null ? String.valueOf(userSession.getPrenom().charAt(0)) + userSession.getNom().charAt(0) : "ET" %>
        </div>
    </div>
</header>

<%-- Panneau notifications AJAX --%>
<div id="notifPanel"
     class="fixed right-4 top-16 w-80 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b font-semibold text-primary flex justify-between items-center">
        <span>Notifications</span>
        <div class="flex gap-2">
            <a href="<%= ctx %>/NotificationServlet?action=tout-lire"
               class="text-xs text-blue-600 hover:underline">Tout lire</a>
            <button onclick="toggleNotifPanel()" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
    </div>
    <div id="notifList" class="divide-y max-h-72 overflow-y-auto">
        <div class="px-4 py-4 text-center text-gray-400 text-sm">Chargement...</div>
    </div>
    <div class="px-4 py-3 border-t text-center">
        <a href="<%= ctx %>/NotificationServlet" class="text-xs text-primary hover:underline">
            Voir toutes les notifications
        </a>
    </div>
</div>

<div class="flex flex-1">
    <%-- SIDEBAR --%>
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="#modulesSection"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                Modules
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M12 4v16m8-8H4"/>
                </svg>
                Mes TPs & Feedback
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
                </svg>
                Déposer / Modifier un TP
            </a>
            <a href="<%= ctx %>/etudiant/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                </svg>
                Envoyer un message
            </a>
            <div class="flex-1"></div>
            <a href="<%= ctx %>/LogoutServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-red-500 hover:bg-red-50 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                Déconnexion
            </a>
        </nav>
    </aside>

    <main class="flex-1">

        <%-- NAV TABS --%>
        <div class="bg-white shadow-sm px-6">
            <nav class="flex gap-6">
                <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list"
                   class="py-4 text-sm font-medium border-b-2 border-primary text-primary">
                    📁 Mes TPs
                </a>
                <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form"
                   class="py-4 text-sm font-medium border-b-2 border-transparent text-gray-500 hover:text-primary">
                    ➕ Déposer un TP
                </a>
            </nav>
        </div>

<main class="flex-1 p-6 max-w-5xl mx-auto w-full">

    <%-- Alertes --%>
    <% if (success) { %>
    <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">
        ✅ TP déposé avec succès. L'enseignant a été notifié.
    </div>
    <% } %>
    <% if (deleted) { %>
    <div class="bg-orange-50 border border-orange-200 text-orange-700 px-4 py-3 rounded-lg mb-4 text-sm">
        🗑️ TP supprimé.
    </div>
    <% } %>
    <% if ("1".equals(request.getParameter("deadlineDepasse"))) { %>
    <div class="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg mb-4 text-sm">
        ⏰ La date limite pour déposer ou modifier ce TP est dépassée.
    </div>
    <% } %>

    <%-- Section Modules (style Classroom) --%>
    <div id="modulesSection" class="mb-8">
        <h2 class="text-xl font-bold text-primary mb-4">Mes modules</h2>
        <% if (modules == null || modules.isEmpty()) { %>
        <p class="text-gray-400 text-sm">Aucun module disponible pour le moment.</p>
        <% } else { %>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <% 
            String[] headerColors = new String[] { "bg-primary", "bg-gray-700" };
            int colorIndex = 0;
            for (Module m : modules) {
                java.util.List<Rapport> rapportsDuModule = new java.util.ArrayList<>();
                if (rapports != null) {
                    for (Rapport r : rapports) {
                        if (r.getModule() != null && r.getModule().getId().equals(m.getId())) rapportsDuModule.add(r);
                    }
                }
                String headerClass = headerColors[colorIndex % 2];
                colorIndex++;
                String enseignantInitial = (m.getEnseignant() != null && m.getEnseignant().getPrenom() != null && m.getEnseignant().getNom() != null)
                    ? String.valueOf(m.getEnseignant().getPrenom().charAt(0)) + m.getEnseignant().getNom().charAt(0) : "?";
            %>
            <div class="bg-white rounded-xl shadow-md border border-gray-100 overflow-hidden hover:shadow-lg transition flex flex-col">
                <%-- En-tête type Classroom --%>
                <div class="<%= headerClass %> relative h-24 px-5 pt-4 pb-2 flex flex-col justify-end">
                    <p class="text-white font-bold text-lg underline decoration-white/50"><%= m.getNom() %></p>
                    <p class="text-white/90 text-sm underline decoration-white/30"><%= m.getFiliere() != null ? m.getFiliere() + " 2025-2026" : "M2I 2025-2026" %></p>
                    <p class="text-white/90 text-sm mt-0.5"><%= m.getEnseignant() != null ? m.getEnseignant().getNomComplet() : "Sans enseignant" %></p>
                    <div class="absolute bottom-0 right-4 translate-y-1/2 w-12 h-12 rounded-full bg-white border-2 border-gray-200 flex items-center justify-center text-gray-700 font-bold text-sm shadow">
                        <%= enseignantInitial %>
                    </div>
                </div>
                <%-- Contenu : plusieurs devoirs (rapports) par module --%>
                <div class="flex-1 p-5 pt-8 min-h-[120px]">
                    <%
                        boolean canDepotModule = true;
                        if (rapports != null && m != null) {
                            Date maxLimite = null;
                            for (Rapport r : rapports) {
                                if (r.getModule() != null && r.getModule().getId().equals(m.getId()) && r.getDateLimite() != null) {
                                    if (maxLimite == null || r.getDateLimite().after(maxLimite)) maxLimite = r.getDateLimite();
                                }
                            }
                            if (maxLimite != null && now.after(maxLimite)) canDepotModule = false;
                        }
                    %>
                    <% if (!rapportsDuModule.isEmpty()) { %>
                    <p class="text-sm text-gray-600 mb-2">Devoirs / supports</p>
                    <ul class="space-y-2 mb-3">
                        <% for (Rapport rapp : rapportsDuModule) { %>
                        <li class="flex items-center justify-between gap-2 flex-wrap">
                            <span class="text-sm font-medium text-gray-700"><%= rapp.getTitre() %></span>
                            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=voir-devoir&rapportId=<%= rapp.getId() %>"
                               class="inline-flex items-center gap-1.5 px-2.5 py-1.5 bg-primary text-white rounded-lg hover:bg-blue-900 transition text-xs font-medium">
                                <svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                Voir le devoir
                            </a>
                        </li>
                        <% } %>
                    </ul>
                    <% if (canDepotModule) { %>
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&moduleId=<%= m.getId() %>"
                       class="inline-flex items-center gap-1.5 px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition text-sm font-medium">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                        Déposer un TP
                    </a>
                    <% } else { %>
                    <p class="text-xs text-amber-600 font-medium">⏰ Date limite dépassée pour ce module. Déposer ou modifier un TP n'est plus possible.</p>
                    <% } %>
                    <% } else { %>
                    <p class="text-sm text-gray-500 mb-2">Aucun support déposé pour ce module.</p>
                    <% if (canDepotModule) { %>
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&moduleId=<%= m.getId() %>"
                       class="inline-flex items-center gap-1.5 px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition text-sm font-medium">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                        Déposer un TP
                    </a>
                    <% } %>
                    <% } %>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>

    <%-- En-tête --%>
    <div class="flex items-center justify-between mb-6">
        <div>
            <h2 class="text-2xl font-bold text-primary">Mes Travaux Pratiques</h2>
            <p class="text-gray-400 text-sm mt-1">
                <%= travaux != null ? travaux.size() : 0 %> TP<%= (travaux != null && travaux.size() > 1) ? "s" : "" %> soumis
            </p>
        </div>
        <div class="text-right">
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form"
               class="inline-flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg
                      hover:bg-blue-900 transition text-sm font-medium">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                Déposer ou modifier un TP
            </a>
            <p class="text-xs text-gray-500 mt-1">Uniquement avant la date limite par module.</p>
        </div>
    </div>

    <%-- Liste des TPs --%>
    <% if (travaux == null || travaux.isEmpty()) { %>
    <div class="bg-white rounded-xl shadow p-12 text-center text-gray-400">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-14 h-14 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
        </svg>
        <p class="font-medium">Aucun TP déposé pour l'instant.</p>
        <p class="text-sm mt-1">Commencez par déposer votre premier travail pratique.</p>
        <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form"
           class="inline-block mt-4 bg-primary text-white px-5 py-2 rounded-lg text-sm hover:bg-blue-900 transition">
            Déposer un TP
        </a>
    </div>
    <% } else { %>
    <div class="space-y-3">
        <% for (TravailPratique tp : travaux) {
            String statutColor = "bg-gray-100 text-gray-600";
            String statutLabel = "Soumis";
            switch (tp.getStatut()) {
                case EN_CORRECTION: statutColor = "bg-yellow-100 text-yellow-700"; statutLabel = "En correction"; break;
                case CORRIGE:       statutColor = "bg-green-100 text-green-700";   statutLabel = "Corrigé"; break;
                case RENDU:         statutColor = "bg-blue-100 text-blue-700";     statutLabel = "Rendu"; break;
            }
        %>
        <div class="bg-white rounded-xl shadow hover:shadow-md transition border border-gray-100">
            <div class="p-5 flex items-start gap-4">
                <%-- Icône fichier --%>
                <div class="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center flex-shrink-0">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                </div>
                <%-- Contenu --%>
                <div class="flex-1 min-w-0">
                    <div class="flex items-start justify-between gap-2">
                        <div>
                            <h3 class="font-bold text-gray-800">
                                <%= tp.getTitre() %>
                                <% if (tp.getVersion() > 1) { %>
                                <span class="text-xs bg-purple-100 text-purple-600 px-1.5 py-0.5 rounded ml-1">
                                    v<%= tp.getVersion() %>
                                </span>
                                <% } %>
                            </h3>
                            <p class="text-sm text-gray-500 mt-0.5">
                                📚 <%= tp.getModule() != null ? tp.getModule().getNom() : "–" %>
                            </p>
                        </div>
                        <span class="<%= statutColor %> text-xs px-2.5 py-1 rounded-full font-medium flex-shrink-0">
                            <%= statutLabel %>
                        </span>
                    </div>
                    <div class="flex items-center gap-4 mt-2">
                        <span class="text-xs text-gray-400">
                            📅 <%= sdf.format(tp.getDateSoumission()) %>
                        </span>
                        <% if (tp.getNomFichier() != null) { %>
                        <span class="text-xs text-gray-400">
                            📎 <%= tp.getNomFichier() %>
                        </span>
                        <% } %>
                        <% if (tp.getNote() != null) { %>
                        <span class="text-xs font-bold text-green-600">
                            ⭐ <%= tp.getNote() %>/20
                        </span>
                        <% } %>
                    </div>
                </div>
                <%-- Actions --%>
                <div class="flex gap-2 flex-shrink-0">
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=detail&id=<%= tp.getId() %>"
                       class="px-3 py-1.5 text-xs bg-primary text-white rounded-lg hover:bg-blue-900 transition">
                        Voir
                    </a>
                    <%
                        boolean canUpdate = true;
                        if (tp.getModule() != null && rapports != null) {
                            Date maxLimite = null;
                            for (Rapport r : rapports) {
                                if (r.getModule() != null && r.getModule().getId().equals(tp.getModule().getId()) && r.getDateLimite() != null) {
                                    if (maxLimite == null || r.getDateLimite().after(maxLimite)) maxLimite = r.getDateLimite();
                                }
                            }
                            if (maxLimite != null && now.after(maxLimite)) canUpdate = false;
                        }
                    %>
                    <% if (tp.getStatut() == TravailPratique.Statut.SOUMIS) { %>
                    <% if (canUpdate) { %>
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&id=<%= tp.getId() %>"
                       class="px-3 py-1.5 text-xs border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 transition">
                        Nouvelle version
                    </a>
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=supprimer&id=<%= tp.getId() %>"
                       onclick="return confirm('Supprimer ce TP ?');"
                       class="px-3 py-1.5 text-xs border border-red-200 text-red-500 rounded-lg hover:bg-red-50 transition">
                        Retirer
                    </a>
                    <% } else { %>
                    <span class="px-3 py-1.5 text-xs text-amber-600 bg-amber-50 rounded-lg" title="Date limite dépassée">Modification non autorisée</span>
                    <% } %>
                    <% } %>
                </div>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>
    </main>
</div>
</main>

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
            .then(r => r.json())
            .then(data => {
                notifLoaded = true;
                const list = document.getElementById('notifList');
                if (data.length === 0) {
                    list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>';
                    return;
                }
                list.innerHTML = data.map(n => {
                    const content = (n.expediteur ? '<p class="text-xs text-gray-500">De: ' + n.expediteur + '</p>' : '') +
                        '<p class="text-sm text-gray-700">' + (n.message||'') + '</p>' +
                        '<p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' +
                        (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                    const cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                    return n.replyUrl ? '<a href="' + n.replyUrl + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
                }).join('');
                // Mettre à jour le badge
                const badge = document.getElementById('notifBadge');
                const nonLues = data.filter(n => !n.lu).length;
                if (badge) {
                    if (nonLues === 0) badge.remove();
                    else badge.textContent = nonLues > 9 ? '9+' : nonLues;
                }
            })
            .catch(() => {
                document.getElementById('notifList').innerHTML =
                    '<div class="px-4 py-4 text-center text-red-400 text-sm">Erreur de chargement.</div>';
            });
    }

    // Fermer le panel si clic extérieur
    document.addEventListener('click', function(e) {
        const panel = document.getElementById('notifPanel');
        const btn = document.getElementById('notifBtn');
        if (!panel.contains(e.target) && !btn.contains(e.target)) {
            panel.classList.add('hidden');
        }
    });
</script>
</body>
</html>