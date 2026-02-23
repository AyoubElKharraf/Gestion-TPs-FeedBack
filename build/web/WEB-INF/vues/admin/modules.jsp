<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Module, model.Enseignant, model.Utilisateur, java.util.List" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Module> modules = (List<Module>) request.getAttribute("modules");
    List<Enseignant> enseignants = (List<Enseignant>) request.getAttribute("enseignants");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    boolean success = "1".equals(request.getParameter("success"));
    boolean deleted = "1".equals(request.getParameter("deleted"));
    boolean notfound = "1".equals(request.getParameter("notfound"));
    boolean nonRemisChecked = "1".equals(request.getParameter("nonRemisChecked"));
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Modules – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<!-- HEADER (identique) -->
<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none"
             viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 
                     01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 
                     00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace de Travail</span>
    </div>
    <div class="flex items-center gap-4">
        <button id="notifBtn" onclick="toggleNotifications()"
                class="relative p-2 rounded-full hover:bg-blue-900 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none"
                 viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 
                         6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 
                         8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 
                         0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (nbNotifs != null && nbNotifs > 0) { %>
            <span id="notifBadge" class="absolute top-1 right-1 w-4 h-4 bg-red-500 rounded-full text-xs flex items-center justify-center font-bold"><%= nbNotifs > 9 ? "9+" : nbNotifs %></span>
            <% } %>
        </button>
        <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2">
            <div class="w-9 h-9 bg-blue-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
                <%= userSession != null && userSession.getPrenom() != null && userSession.getNom() != null ? String.valueOf(userSession.getPrenom().charAt(0)) + String.valueOf(userSession.getNom().charAt(0)) : "AD" %>
            </div>
            <span class="text-sm font-medium hidden md:block"><%= userSession != null ? userSession.getNomComplet() : "Admin" %></span>
        </button>
    </div>
</header>
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
<div id="profilePanel" class="fixed right-4 top-16 w-72 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b flex justify-between items-center">
        <span class="font-semibold text-gray-800">Profil</span>
        <button onclick="toggleProfilePanel()" class="text-gray-400 hover:text-gray-600 text-sm">✕</button>
    </div>
    <div class="px-4 py-4 text-sm text-gray-700 space-y-1">
        <p><span class="font-semibold">Nom :</span> <%= userSession != null ? userSession.getNomComplet() : "-" %></p>
        <p><span class="font-semibold">Email :</span> <%= userSession != null ? userSession.getEmail() : "-" %></p>
        <p><span class="font-semibold">Rôle :</span> <%= userSession != null ? userSession.getRole().name() : "-" %></p>
    </div>
</div>
<div class="flex flex-1">
    <!-- SIDEBAR -->
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/admin/ModuleServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 
                             1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                Modules
            </a>
            <a href="<%= ctx %>/admin/EtudiantServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283
                             -.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126
                             -1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
                Étudiants
            </a>
            <a href="<%= ctx %>/admin/EnseignantServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                </svg>
                Enseignants
            </a>
            <a href="<%= ctx %>/admin/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                </svg>
                Envoyer un message
            </a>
            <div class="flex-1"></div>
            <a href="<%= ctx %>/LogoutServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-red-500 hover:bg-red-50 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 
                             01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                Déconnexion
            </a>
        </nav>
    </aside>

    <!-- CONTENU MODULES -->
    <main class="flex-1 p-6">
        <!-- Messages -->
        <% if (success) { %>
        <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">
            ✅ Module enregistré avec succès.
        </div>
        <% } %>
        <% if (deleted) { %>
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">
            🗑️ Module supprimé.
        </div>
        <% } %>
        <% if (notfound) { %>
        <div class="bg-yellow-50 border border-yellow-200 text-yellow-700 px-4 py-3 rounded-lg mb-4 text-sm">
            ⚠️ Module introuvable.
        </div>
        <% } %>
        <% if (nonRemisChecked) { %>
        <div class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded-lg mb-4 text-sm">
            Vérification effectuée : alertes TPs non rendus envoyées au système d'absences (si configuré).
        </div>
        <% } %>

        <!-- En-tête section -->
        <div class="flex items-center justify-between mb-6">
            <div>
                <h2 class="text-2xl font-bold text-primary">Modules – M2I</h2>
                <p class="text-gray-400 text-sm mt-1">Gérer les modules de la filière M2I</p>
            </div>
            <a href="<%= ctx %>/admin/CheckNonRemisServlet" class="text-sm text-primary hover:underline font-medium mr-4">Vérifier TPs non rendus → alerte absences</a>
            <a href="<%= ctx %>/admin/ModuleServlet?action=form"
               class="flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg
                      hover:bg-blue-900 transition text-sm font-medium">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M12 4v16m8-8H4"/>
                </svg>
                Ajouter un module
            </a>
        </div>

        <!-- Grille des modules -->
        <% if (modules == null || modules.isEmpty()) { %>
        <div class="bg-white rounded-xl shadow p-10 text-center text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-12 h-12 mx-auto mb-3 text-gray-300"
                 fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 
                         1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <p>Aucun module. Commencez par en ajouter un.</p>
        </div>
        <% } else { %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <% for (Module mod : modules) { %>
            <div class="bg-white rounded-xl shadow hover:shadow-md transition border border-gray-100">
                <!-- Bouton principal du module -->
                <a href="<%= ctx %>/admin/ModuleServlet?action=detail&id=<%= mod.getId() %>"
                   class="block p-5">
                    <div class="flex items-start justify-between">
                        <div>
                            <span class="text-xs bg-blue-100 text-primary px-2 py-0.5 rounded font-medium">
                                M2I
                            </span>
                            <h3 class="font-bold text-primary mt-2"><%= mod.getNom() %></h3>
                            <p class="text-sm text-gray-500 mt-1">
                                👨‍🏫 <%= mod.getEnseignant() != null ? mod.getEnseignant().getNomComplet() : "Non assigné" %>
                            </p>
                        </div>
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-gray-300 mt-1"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                  d="M9 5l7 7-7 7"/>
                        </svg>
                    </div>
                </a>
                <!-- Actions rapides -->
                <div class="border-t px-5 py-3 flex gap-3">
                    <a href="<%= ctx %>/admin/ModuleServlet?action=form&id=<%= mod.getId() %>"
                       class="text-xs text-blue-600 hover:underline flex items-center gap-1">
                        ✏️ Modifier
                    </a>
                    <form method="POST" action="<%= ctx %>/admin/ModuleServlet"
                          onsubmit="return confirm('Supprimer ce module ?');"
                          class="inline">
                        <input type="hidden" name="action" value="delete"/>
                        <input type="hidden" name="id" value="<%= mod.getId() %>"/>
                        <button type="submit"
                                class="text-xs text-red-500 hover:underline flex items-center gap-1">
                            🗑️ Supprimer
                        </button>
                    </form>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </main>
</div>

<script>
    function toggleNotifications() {
        var panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && document.getElementById('notifList').innerText === 'Chargement...')
            loadNotifications();
    }
    function loadNotifications() {
        fetch('<%= ctx %>/NotificationServlet?action=liste-json').then(function(r){ return r.json(); }).then(function(data){
            var list = document.getElementById('notifList');
            if (!data.length) { list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>'; return; }
            list.innerHTML = data.map(function(n){
                var de = (n.expediteur ? '<p class="text-xs text-gray-500">De: ' + n.expediteur + '</p>' : '');
                var reply = (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                var content = de + '<p class="text-sm text-gray-700">' + (n.message||'') + '</p><p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' + reply;
                var cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                return n.replyUrl ? '<a href="' + n.replyUrl + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
            }).join('');
            var badge = document.getElementById('notifBadge');
            var nonLues = data.filter(function(n){ return !n.lu; }).length;
            if (badge) { badge.textContent = nonLues > 9 ? '9+' : nonLues; if (nonLues === 0) badge.remove(); }
        });
    }
    function toggleProfilePanel() { document.getElementById('profilePanel').classList.toggle('hidden'); }
    document.addEventListener('click', function(e) {
        var panel = document.getElementById('notifPanel'), btn = document.getElementById('notifBtn');
        if (btn && !panel.contains(e.target) && !btn.contains(e.target)) panel.classList.add('hidden');
    });
</script>
</body>
</html>