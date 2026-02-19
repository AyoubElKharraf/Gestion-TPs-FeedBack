<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.Module, model.Rapport, java.util.List, java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Module> modules = (List<Module>) request.getAttribute("modules");
    List<Rapport> rapports = (List<Rapport>) request.getAttribute("rapports");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String activeSection = (String) request.getAttribute("activeSection");
    if (activeSection == null) activeSection = "rapports";
    String ctx = request.getContextPath();
    boolean success = "1".equals(request.getParameter("success"));
    boolean deleted = "1".equals(request.getParameter("deleted"));
    boolean error = request.getParameter("error") != null;
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Rapports – Enseignant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">
<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace Enseignant</span>
    </div>
    <div class="flex items-center gap-4">
        <button id="notifBtn" onclick="toggleNotifications()" class="relative p-2 rounded-full hover:bg-blue-900 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (nbNotifs != null && nbNotifs > 0) { %>
            <span id="notifBadge" class="absolute top-1 right-1 w-4 h-4 bg-red-500 rounded-full text-xs flex items-center justify-center font-bold"><%= nbNotifs > 9 ? "9+" : nbNotifs %></span>
            <% } %>
        </button>
        <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2">
            <div class="w-9 h-9 bg-blue-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
                <%= userSession != null ? String.valueOf(userSession.getPrenom().charAt(0)) + userSession.getNom().charAt(0) : "EN" %>
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
        <p><span class="font-semibold">Rôle :</span> ENSEIGNANT</p>
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
            <a href="<%= ctx %>/enseignant/DashboardServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
                Tableau de bord
            </a>
            <a href="<%= ctx %>/enseignant/CorrectionTPServlet?action=list" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                TPs
            </a>
            <a href="<%= ctx %>/enseignant/RapportServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Rapports
            </a>
            <a href="<%= ctx %>/enseignant/CommentaireServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h6m-6 4h4M5 4h14a2 2 0 012 2v9a2 2 0 01-2 2H9l-4 3v-3H5a2 2 0 01-2-2V6a2 2 0 012-2z"/></svg>
                Commentaires
            </a>
            <a href="<%= ctx %>/enseignant/AbsenceServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-6h6v6m2 4H7a2 2 0 01-2-2V7a2 2 0 012-2h3l2-2h3l2 2h3a2 2 0 012 2v12a2 2 0 01-2 2z"/></svg>
                Absence
            </a>
            <a href="<%= ctx %>/enseignant/MessageServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
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
    <main class="flex-1 p-6 max-w-4xl">
        <h1 class="text-2xl font-bold text-primary mb-2">Rapports par module</h1>
        <p class="text-gray-500 text-sm mb-6">Déposez autant de rapports que vous voulez par module. Chaque dépôt ajoute un nouveau document. Les étudiants pourront les consulter puis déposer leur TP.</p>
        <% if (success) { %>
        <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">Rapport enregistré. Les étudiants peuvent le télécharger.</div>
        <% } %>
        <% if (deleted) { %>
        <div class="bg-amber-50 border border-amber-200 text-amber-700 px-4 py-3 rounded-lg mb-4 text-sm">Rapport supprimé.</div>
        <% } %>
        <% if (error) { %>
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">Veuillez remplir le titre, choisir un module et joindre un fichier.</div>
        <% } %>
        <% if (modules == null || modules.isEmpty()) { %>
        <div class="bg-white rounded-xl shadow p-8 text-center text-gray-500">Aucun module assigné. Contactez l'administrateur.</div>
        <% } else { %>
        <div class="space-y-6">
            <% for (Module m : modules) {
                java.util.List<Rapport> rapportsDuModule = new java.util.ArrayList<>();
                if (rapports != null) {
                    for (Rapport r : rapports) {
                        if (r.getModule() != null && r.getModule().getId().equals(m.getId())) rapportsDuModule.add(r);
                    }
                }
            %>
            <div class="bg-white rounded-xl shadow border border-gray-100 p-5">
                <div class="flex items-center justify-between mb-4">
                    <h2 class="font-bold text-primary text-lg"><%= m.getNom() %></h2>
                </div>
                <% if (!rapportsDuModule.isEmpty()) { %>
                <p class="text-xs font-medium text-gray-500 mb-2">Rapports déposés (<%= rapportsDuModule.size() %>)</p>
                <ul class="space-y-2 mb-4">
                    <% for (Rapport rapp : rapportsDuModule) { %>
                    <li class="flex items-center justify-between gap-2 py-2 border-b border-gray-100 last:border-0">
                        <div>
                            <strong><%= rapp.getTitre() %></strong><% if (rapp.getFileName() != null) { %> — <%= rapp.getFileName() %><% } %>
                            <span class="text-xs text-gray-400 ml-2"><%= sdf.format(rapp.getDateCreation()) %></span>
                            <% if (rapp.getDateLimite() != null) { %>
                            <span class="text-xs text-amber-600 ml-2">Limite : <%= sdf.format(rapp.getDateLimite()) %></span>
                            <% } %>
                        </div>
                        <div class="flex items-center gap-2">
                            <a href="<%= ctx %>/RapportDownloadServlet?id=<%= rapp.getId() %>"
                               class="px-2 py-1 text-sm bg-primary text-white rounded hover:bg-blue-900 transition">Télécharger</a>
                            <a href="<%= ctx %>/enseignant/RapportServlet?action=delete&id=<%= rapp.getId() %>"
                               onclick="return confirm('Supprimer ce rapport ?');"
                               class="px-2 py-1 text-sm text-red-600 hover:bg-red-50 rounded transition">Supprimer</a>
                        </div>
                    </li>
                    <% } %>
                </ul>
                <% } else { %>
                <p class="text-sm text-gray-500 mb-3">Aucun rapport déposé pour ce module.</p>
                <% } %>
                <p class="text-xs text-gray-400 mb-2">Déposer un nouveau rapport :</p>
                <form action="<%= ctx %>/enseignant/RapportServlet" method="post" enctype="multipart/form-data" class="flex flex-wrap gap-3 items-end">
                    <input type="hidden" name="moduleId" value="<%= m.getId() %>"/>
                    <div class="flex-1 min-w-[200px]">
                        <label class="block text-xs font-medium text-gray-500 mb-1">Titre du rapport</label>
                        <input type="text" name="titre" required placeholder="ex. Sujet TP1 - Consignes"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"/>
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-500 mb-1">Date limite (dépôt TP étudiant)</label>
                        <input type="datetime-local" name="dateLimite"
                               class="border border-gray-300 rounded-lg px-3 py-2 text-sm"/>
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-500 mb-1">Fichier (PDF, etc.)</label>
                        <input type="file" name="fichier" required accept=".pdf,.doc,.docx,.txt"
                               class="border border-gray-300 rounded-lg px-3 py-2 text-sm"/>
                    </div>
                    <button type="submit" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-blue-900 transition text-sm font-medium">
                        Déposer
                    </button>
                </form>
            </div>
            <% } %>
        </div>
        <% } %>
    </main>
</div>
<script>
function toggleProfilePanel() { document.getElementById('profilePanel').classList.toggle('hidden'); }
function toggleNotifications() {
    const panel = document.getElementById('notifPanel');
    panel.classList.toggle('hidden');
    if (!panel.classList.contains('hidden') && document.getElementById('notifList').innerHTML.includes('Chargement')) {
        fetch('<%= ctx %>/NotificationServlet?action=liste-json').then(r => r.json()).then(data => {
            const list = document.getElementById('notifList');
            if (data.length === 0) { list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>'; return; }
            list.innerHTML = data.map(n => {
                var content = (n.expediteur ? '<p class="text-xs text-gray-500">De: ' + n.expediteur + '</p>' : '') + '<p class="text-sm text-gray-700">' + (n.message||'') + '</p><p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' + (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                var cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                return n.replyUrl ? '<a href="' + n.replyUrl + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
            }).join('');
            const badge = document.getElementById('notifBadge');
            const nonLues = data.filter(n => !n.lu).length;
            if (badge) { if (nonLues === 0) badge.remove(); else badge.textContent = nonLues > 9 ? '9+' : nonLues; }
        }).catch(() => { document.getElementById('notifList').innerHTML = '<div class="px-4 py-4 text-center text-red-400 text-sm">Erreur.</div>'; });
    }
}
document.addEventListener('click', function(e) {
    if (!document.getElementById('profilePanel').contains(e.target) && !e.target.closest('button[onclick*="toggleProfilePanel"]')) document.getElementById('profilePanel').classList.add('hidden');
    if (!document.getElementById('notifPanel').contains(e.target) && !e.target.closest('#notifBtn')) document.getElementById('notifPanel').classList.add('hidden');
});
</script>
</body>
</html>
