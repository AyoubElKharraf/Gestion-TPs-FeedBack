<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String activeSection = (String) request.getAttribute("activeSection");
    if (activeSection == null) activeSection = "absences";
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Absences – Enseignant</title>
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
            <a href="<%= ctx %>/enseignant/RapportServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "rapports".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
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
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium <%= "absences".equals(activeSection) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100 transition" %>">
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
        <div class="bg-white rounded-xl shadow p-8">
            <h1 class="text-2xl font-bold text-primary mb-2">Gestion des Absences</h1>
            <p class="text-gray-500 text-sm mb-4">
                Les absences sont gérées par le système externe <strong>AbsTrack</strong>.
                Signalez ci-dessous les étudiants qui n'ont pas rendu leur TP avant la date limite : l'absence sera enregistrée dans le système externe.
                Lorsqu'un étudiant dépasse la limite (3 enseignants distincts), vous recevez une notification.
            </p>
            <% if (Boolean.TRUE.equals(request.getAttribute("signale"))) { %>
            <div class="mb-4 p-3 bg-green-100 text-green-800 rounded-lg text-sm">
                <strong>Absence signalée au système AbsTrack.</strong><br/>
                Pour voir les absences dans le tableau de bord de AbsTrack, connectez-vous avec le <strong>même email</strong>.
            </div>
            <% } %>
            <% if (Boolean.FALSE.equals(request.getAttribute("signale"))) { %>
            <div class="mb-4 p-3 bg-amber-100 text-amber-800 rounded-lg text-sm">
                <strong>Le système Gestion_AbsencesAlerts n'a pas enregistré l'absence.</strong> Vérifiez que : (1) l'URL est configurée dans <code>web.xml</code> (context-param <code>absence.system.url</code>) et pointe vers l'application Gestion_AbsencesAlerts ; (2) cette application est démarrée ; (3) l'étudiant et l'enseignant existent dans Gestion_AbsencesAlerts avec les <strong>mêmes adresses email</strong> que dans EtudAcadPro.
            </div>
            <% } %>
            <% if ("param".equals(request.getAttribute("erreur")) || "module".equals(request.getAttribute("erreur")) || "etudiant".equals(request.getAttribute("erreur"))) { %>
            <div class="mb-4 p-3 bg-red-100 text-red-800 rounded-lg text-sm">Erreur lors du signalement. Vérifiez les paramètres.</div>
            <% } %>

            <% java.util.List<model.NonRemisItem> nonRemisList = (java.util.List<model.NonRemisItem>) request.getAttribute("nonRemisList"); %>
            <% if (nonRemisList != null && !nonRemisList.isEmpty()) { %>
            <h2 class="text-lg font-semibold text-gray-800 mt-6 mb-3">Étudiants n'ayant pas rendu le TP (date limite dépassée)</h2>
            <p class="text-gray-500 text-sm mb-3">Cliquez sur « Signaler absence » pour enregistrer l'absence dans le système Gestion_AbsencesAlerts.</p>
            <div class="overflow-x-auto">
                <table class="min-w-full border border-gray-200 rounded-lg">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Module</th>
                            <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Rapport / TP</th>
                            <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Étudiant</th>
                            <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (model.NonRemisItem item : nonRemisList) { %>
                        <tr class="border-t border-gray-200 hover:bg-gray-50">
                            <td class="px-4 py-2 text-sm"><%= item.getModule() != null ? item.getModule().getNom() : "-" %></td>
                            <td class="px-4 py-2 text-sm"><%= item.getRapport() != null ? item.getRapport().getTitre() : "-" %></td>
                            <td class="px-4 py-2 text-sm"><%= item.getEtudiant() != null ? item.getEtudiant().getNomComplet() + " (" + item.getEtudiant().getEmail() + ")" : "-" %></td>
                            <td class="px-4 py-2">
                                <% if (item.getEtudiant() != null && item.getModule() != null) { %>
                                <a href="<%= ctx %>/enseignant/SignalerAbsenceTpServlet?etudiantId=<%= item.getEtudiant().getId() %>&moduleId=<%= item.getModule().getId() %>"
                                   class="inline-block px-3 py-1.5 bg-primary text-white text-sm font-medium rounded-lg hover:bg-blue-900 transition">Signaler absence</a>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            <% } else { %>
            <p class="text-gray-500 text-sm mt-4">Aucun étudiant en retard de rendu de TP pour vos modules (date limite dépassée).</p>
            <% } %>
        </div>
    </main>
</div>

<script>
    function toggleNotifications() {
        var panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && document.getElementById('notifList').innerText === 'Chargement...')
            fetch('<%= ctx %>/NotificationServlet?action=liste-json').then(function(r){ return r.json(); }).then(function(data){
                var list = document.getElementById('notifList');
                if (!data.length) { list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>'; return; }
                list.innerHTML = data.map(function(n){
                    var content = '<p class="text-sm text-gray-700">' + (n.message||'') + '</p><p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' + (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                    var cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                    return n.replyUrl ? '<a href="' + n.replyUrl + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
                }).join('');
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
