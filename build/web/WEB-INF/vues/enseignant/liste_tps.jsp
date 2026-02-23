<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<TravailPratique> travaux = (List<TravailPratique>) request.getAttribute("travaux");
    List<model.Module> modules = (List<model.Module>) request.getAttribute("modules");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    Long nbSoumis = (Long) request.getAttribute("nbSoumis");
    String filtreStatut = (String) request.getAttribute("filtreStatut");
    String filtreModuleId = (String) request.getAttribute("filtreModuleId");
    String filtreDateMin = (String) request.getAttribute("filtreDateMin");
    String filtreDateMax = (String) request.getAttribute("filtreDateMax");
    String activeSection = (String) request.getAttribute("activeSection");
    if (activeSection == null) activeSection = "tps";
    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>TPs à corriger – Enseignant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace Enseignant</span>
    </div>
    <div class="flex items-center gap-3">
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
        <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2">
            <div class="w-9 h-9 bg-blue-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
                <%= userSession != null && userSession.getPrenom() != null && userSession.getNom() != null ? String.valueOf(userSession.getPrenom().charAt(0)) + String.valueOf(userSession.getNom().charAt(0)) : "EN" %>
            </div>
            <span class="text-sm font-medium hidden md:block"><%= userSession != null ? userSession.getNomComplet() : "Enseignant" %></span>
        </button>
    </div>
</header>

<div id="profilePanel" class="fixed right-4 top-16 w-72 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b flex justify-between items-center">
        <span class="font-semibold text-gray-800">Profil</span>
        <button onclick="toggleProfilePanel()" class="text-gray-400 hover:text-gray-600 text-sm">✕</button>
    </div>
    <div class="px-4 py-4 text-sm text-gray-700 space-y-1">
        <p><span class="font-semibold">Nom :</span> <%= userSession != null ? userSession.getNomComplet() : "-" %></p>
        <p><span class="font-semibold">Email :</span> <%= userSession != null ? userSession.getEmail() : "-" %></p>
        <p><span class="font-semibold">Rôle :</span> <%= userSession != null ? userSession.getRole().name() : "ENSEIGNANT" %></p>
    </div>
</div>

<%-- Panneau notifications --%>
<div id="notifPanel"
     class="fixed right-4 top-16 w-80 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b font-semibold text-primary flex justify-between items-center">
        <span>Notifications</span>
        <div class="flex gap-2">
            <a href="<%= ctx %>/NotificationServlet?action=tout-lire" class="text-xs text-blue-600 hover:underline">Tout lire</a>
            <button onclick="toggleNotifPanel()" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
    </div>
    <div id="notifList" class="divide-y max-h-72 overflow-y-auto">
        <div class="px-4 py-4 text-center text-gray-400 text-sm">Chargement...</div>
    </div>
    <div class="px-4 py-3 border-t text-center">
        <a href="<%= ctx %>/NotificationServlet" class="text-xs text-primary hover:underline">Voir toutes</a>
    </div>
</div>

<div class="flex flex-1">
    <!-- SIDEBAR -->
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/enseignant/DashboardServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "dashboard".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>
                </svg>
                Tableau de bord
            </a>
            <a href="<%= ctx %>/enseignant/CorrectionTPServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium <%= "tps".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100 transition" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                TPs
            </a>
            <a href="<%= ctx %>/enseignant/RapportServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium <%= "rapports".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100 transition" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Rapports
            </a>
            <a href="<%= ctx %>/enseignant/CommentaireServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M7 8h10M7 12h6m-6 4h4M5 4h14a2 2 0 012 2v9a2 2 0 01-2 2H9l-4 3v-3H5a2 2 0 01-2-2V6a2 2 0 012-2z"/>
                </svg>
                Commentaires
            </a>

            <!-- Absence -->
            <a href="<%= ctx %>/enseignant/AbsenceServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 17v-6h6v6m2 4H7a2 2 0 01-2-2V7a2 2 0 012-2h3l2-2h3l2 2h3a2 2 0 012 2v12a2 2 0 01-2 2z"/>
                </svg>
                Absence
            </a>
            <a href="<%= ctx %>/enseignant/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                </svg>
                Envoyer un message
            </a>
            <div class="flex-1"></div>

            <!-- Déconnexion -->
            <a href="<%= ctx %>/LogoutServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-red-500 hover:bg-red-50 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 
                             01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                Déconnexion
            </a>
        </nav>
    </aside>

    <main class="flex-1 p-6 max-w-5xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
        <div>
            <h2 class="text-2xl font-bold text-primary">TPs à corriger</h2>
        </div>
    </div>
    <form method="get" action="<%= ctx %>/enseignant/CorrectionTPServlet" class="flex flex-wrap gap-3 items-end mb-6 p-3 bg-gray-50 rounded-lg">
        <input type="hidden" name="action" value="list"/>
        <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Module</label>
            <select name="moduleId" class="border border-gray-300 rounded px-2 py-1.5 text-sm">
                <option value="">Tous</option>
                <% if (modules != null) for (model.Module m : modules) { %>
                <option value="<%= m.getId() %>"<%= (filtreModuleId != null && filtreModuleId.equals(String.valueOf(m.getId()))) ? " selected" : "" %>><%= m.getNom() %></option>
                <% } %>
            </select>
        </div>
        <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Statut</label>
            <select name="statut" class="border border-gray-300 rounded px-2 py-1.5 text-sm">
                <option value="">Tous</option>
                <option value="SOUMIS"<%= "SOUMIS".equals(filtreStatut) ? " selected" : "" %>>Soumis</option>
                <option value="EN_CORRECTION"<%= "EN_CORRECTION".equals(filtreStatut) ? " selected" : "" %>>En correction</option>
                <option value="CORRIGE"<%= "CORRIGE".equals(filtreStatut) ? " selected" : "" %>>Corrigé</option>
                <option value="RENDU"<%= "RENDU".equals(filtreStatut) ? " selected" : "" %>>Rendu</option>
            </select>
        </div>
        <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Date dépôt (début)</label>
            <input type="date" name="dateMin" value="<%= filtreDateMin != null ? filtreDateMin : "" %>" class="border border-gray-300 rounded px-2 py-1.5 text-sm"/>
        </div>
        <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Date dépôt (fin)</label>
            <input type="date" name="dateMax" value="<%= filtreDateMax != null ? filtreDateMax : "" %>" class="border border-gray-300 rounded px-2 py-1.5 text-sm"/>
        </div>
        <button type="submit" class="px-3 py-1.5 bg-primary text-white text-sm rounded hover:bg-blue-900 transition">Filtrer</button>
    </form>

    <%-- Liste (statut affiché dans le tableau pour chaque TP) --%>
    <% if (travaux == null || travaux.isEmpty()) { %>
    <div class="bg-white rounded-xl shadow p-10 text-center text-gray-400">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-12 h-12 mx-auto mb-3 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
        </svg>
        <p>Aucun TP trouvé.</p>
    </div>
    <% } else { %>
    <div class="bg-white rounded-xl shadow overflow-hidden">
        <table class="w-full text-sm">
            <thead class="bg-gray-50 text-gray-500 uppercase text-xs">
                <tr>
                    <th class="px-5 py-3 text-left font-semibold">TP</th>
                    <th class="px-5 py-3 text-left font-semibold">Étudiant</th>
                    <th class="px-5 py-3 text-left font-semibold">Module</th>
                    <th class="px-5 py-3 text-left font-semibold">Déposé le</th>
                    <th class="px-5 py-3 text-center font-semibold">Statut</th>
                    <th class="px-5 py-3 text-center font-semibold">Note</th>
                    <th class="px-5 py-3 text-center font-semibold">Action</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                <% for (TravailPratique tp : travaux) {
                    String sc = "bg-gray-100 text-gray-600"; String sl = "Soumis";
                    switch (tp.getStatut()) {
                        case EN_CORRECTION: sc = "bg-yellow-100 text-yellow-700"; sl = "En correction"; break;
                        case CORRIGE:       sc = "bg-green-100 text-green-700";   sl = "Corrigé"; break;
                        case RENDU:         sc = "bg-blue-100 text-blue-700";     sl = "Rendu"; break;
                    }
                %>
                <tr class="hover:bg-gray-50 transition">
                    <td class="px-5 py-3 font-medium text-gray-800">
                        <%= tp.getTitre() %>
                        <% if (tp.getVersion() > 1) { %>
                        <span class="text-xs bg-purple-100 text-purple-600 px-1 rounded">v<%= tp.getVersion() %></span>
                        <% } %>
                    </td>
                    <td class="px-5 py-3 text-gray-600">
                        <% if (tp.getEtudiant() != null) { %>
                        <div class="flex items-center gap-2">
                            <div class="w-7 h-7 bg-green-100 rounded-full flex items-center justify-center text-xs font-bold text-green-700">
                                <%= (tp.getEtudiant().getPrenom() != null && !tp.getEtudiant().getPrenom().isEmpty()) ? String.valueOf(tp.getEtudiant().getPrenom().charAt(0)).toUpperCase() : "?" %>
                            </div>
                            <%= tp.getEtudiant().getNomComplet() %>
                        </div>
                        <% } %>
                    </td>
                    <td class="px-5 py-3 text-gray-600">
                        <%= tp.getModule() != null ? tp.getModule().getNom() : "–" %>
                    </td>
                    <td class="px-5 py-3 text-gray-400 text-xs">
                        <%= sdf.format(tp.getDateSoumission()) %>
                    </td>
                    <td class="px-5 py-3 text-center">
                        <span class="<%= sc %> text-xs px-2.5 py-1 rounded-full font-medium">
                            <%= sl %>
                        </span>
                    </td>
                    <td class="px-5 py-3 text-center font-bold
                               <%= tp.getNote() != null ? "text-green-600" : "text-gray-300" %>">
                        <%= tp.getNote() != null ? tp.getNote() + "/20" : "–" %>
                    </td>
                    <td class="px-5 py-3 text-center">
                        <a href="<%= ctx %>/enseignant/CorrectionTPServlet?action=detail&id=<%= tp.getId() %>"
                           class="px-3 py-1.5 bg-primary text-white text-xs rounded-lg hover:bg-blue-900 transition">
                            Corriger
                        </a>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</main>

<script>
    let notifLoaded = false;
    function toggleNotifPanel() {
        const panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && !notifLoaded) loadNotifications();
    }
    function loadNotifications() {
        fetch('<%= ctx %>/NotificationServlet?action=liste-json')
            .then(r => r.json())
            .then(data => {
                notifLoaded = true;
                const list = document.getElementById('notifList');
                if (!data.length) {
                    list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>';
                    return;
                }
                list.innerHTML = data.map(n => {
                    var content = '<p class="text-sm text-gray-700">' + (n.message||'') + '</p><p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' + (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                    var cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                    var url = n.replyUrl || n.markReadUrl;
                    return url ? '<a href="' + url + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
                }).join('');
                const badge = document.getElementById('notifBadge');
                const nonLues = data.filter(n => !n.lu).length;
                if (badge) { badge.textContent = nonLues > 9 ? '9+' : nonLues; if (!nonLues) badge.remove(); }
            });
    }
    function toggleProfilePanel() {
        document.getElementById('profilePanel').classList.toggle('hidden');
    }
    document.addEventListener('click', e => {
        const panel = document.getElementById('notifPanel');
        const btn = document.getElementById('notifBtn');
        if (!panel.contains(e.target) && !btn.contains(e.target)) panel.classList.add('hidden');
    });
</script>
</body>
</html>