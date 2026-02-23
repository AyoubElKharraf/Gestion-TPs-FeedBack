<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.TravailPratique, model.FeedItem, java.util.List, java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<TravailPratique> travaux = (List<TravailPratique>) request.getAttribute("travaux");
    List<FeedItem> feedItems = (List<FeedItem>) request.getAttribute("feedItems");
    Long nbSoumis = (Long) request.getAttribute("nbSoumis");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String activeSection = (String) request.getAttribute("activeSection");
    if (activeSection == null) activeSection = "dashboard";
    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("d MMM", java.util.Locale.FRENCH);
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Tableau de bord – Enseignant</title>
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
    <div class="flex items-center gap-4">
        <button id="notifBtn" onclick="toggleNotifications()" class="relative p-2 rounded-full hover:bg-blue-900 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (nbNotifs != null && nbNotifs > 0) { %>
            <span id="notifBadge" class="absolute top-1 right-1 w-4 h-4 bg-red-500 rounded-full text-xs flex items-center justify-center font-bold"><%= nbNotifs > 9 ? "9+" : nbNotifs %></span>
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

<div id="notifPanel" class="fixed right-4 top-16 w-80 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b font-semibold text-primary flex justify-between items-center">
        <span>Notifications</span>
        <div class="flex gap-2">
            <a href="<%= ctx %>/NotificationServlet?action=tout-lire" class="text-xs text-blue-600 hover:underline">Tout lire</a>
            <button onclick="toggleNotifications()" class="text-gray-400 hover:text-gray-600">✕</button>
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
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "tps".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                TPs
            </a>
            <a href="<%= ctx %>/enseignant/RapportServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "rapports".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Rapports
            </a>
            <a href="<%= ctx %>/enseignant/CommentaireServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "commentaires".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h6m-6 4h4M5 4h14a2 2 0 012 2v9a2 2 0 01-2 2H9l-4 3v-3H5a2 2 0 01-2-2V6a2 2 0 012-2z"/>
                </svg>
                Commentaires
            </a>
            <a href="<%= ctx %>/enseignant/AbsenceServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "absences".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-6h6v6m2 4H7a2 2 0 01-2-2V7a2 2 0 012-2h3l2-2h3l2 2h3a2 2 0 012 2v12a2 2 0 01-2 2z"/>
                </svg>
                Absence
            </a>
            <a href="<%= ctx %>/enseignant/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "messages".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                </svg>
                Envoyer un message
            </a>
            <div class="flex-1"></div>
            <a href="<%= ctx %>/LogoutServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-red-500 hover:bg-red-50 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                Déconnexion
            </a>
        </nav>
    </aside>

    <main class="flex-1 p-6">
        <div class="mb-6">
            <h2 class="text-2xl font-bold text-primary">Tableau de bord</h2>
            <p class="text-gray-500 text-sm mt-1">Bienvenue, <%= userSession != null ? userSession.getNomComplet() : "" %></p>
        </div>

        <%-- Fil d'activité (rapports publiés + TPs déposés par les étudiants) --%>
        <div class="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden mb-6">
            <div class="px-6 py-4 border-b border-gray-100 bg-gradient-to-r from-primary/5 to-blue-50">
                <h3 class="font-bold text-lg text-primary">Fil d'activité</h3>
                <p class="text-gray-500 text-sm mt-0.5">Rapports et TPs récents</p>
            </div>
            <div class="p-6">
            <% if (feedItems == null || feedItems.isEmpty()) { %>
            <p class="text-gray-400 text-sm py-4">Aucune activité récente.</p>
            <% } else { %>
            <div class="space-y-2">
                <% for (FeedItem item : feedItems) {
                    boolean isRapport = (item.getType() == FeedItem.Type.RAPPORT);
                    String iconBg = isRapport ? "bg-blue-500/10 text-blue-600" : "bg-amber-500/10 text-amber-600";
                    String btnClass = isRapport ? "bg-primary hover:bg-blue-900 text-white" : "bg-amber-500 hover:bg-amber-600 text-white";
                %>
                <div class="flex items-center gap-4 p-4 rounded-xl border border-gray-100 hover:border-gray-200 hover:shadow-sm transition-all duration-200 bg-gray-50/30">
                    <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 shadow-sm <%= iconBg %>">
                        <% if (isRapport) { %>
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
                        <% } else { %>
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                        <% } %>
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="font-semibold text-gray-800"><%= item.getTitle() %></p>
                        <p class="text-sm text-gray-500 mt-0.5"><%= item.getAuthorName() %> · <%= item.getSubtitle() %></p>
                        <p class="text-xs text-gray-400 mt-1"><%= item.getDate() != null ? sdf.format(item.getDate()) : "" %></p>
                    </div>
                    <a href="<%= item.getActionUrl() %>" class="flex-shrink-0 px-4 py-2 rounded-xl text-sm font-medium transition <%= btnClass %>">
                        <%= item.getActionLabel() %>
                    </a>
                </div>
                <% } %>
            </div>
            <% } %>
            </div>
        </div>
    </main>
</div>

<script>
    function toggleNotifications() {
        const panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && document.getElementById('notifList').innerText === 'Chargement...')
            loadNotifications();
    }
    function loadNotifications() {
        fetch('<%= ctx %>/NotificationServlet?action=liste-json')
            .then(r => r.json())
            .then(data => {
                const list = document.getElementById('notifList');
                if (!data.length) { list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>'; return; }
                list.innerHTML = data.map(n => {
                    var de = (n.expediteur ? '<p class="text-xs text-gray-500">De: ' + n.expediteur + '</p>' : '');
                    var content = de + '<p class="text-sm text-gray-700">' + (n.message||'') + '</p><p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' + (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
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
    document.addEventListener('click', function(e) {
        const panel = document.getElementById('notifPanel');
        const btn = document.getElementById('notifBtn');
        if (btn && !panel.contains(e.target) && !btn.contains(e.target)) panel.classList.add('hidden');
    });
</script>
</body>
</html>
