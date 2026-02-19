<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    TravailPratique tp = (TravailPratique) request.getAttribute("tp");
    List<Commentaire> commentaires = (List<Commentaire>) request.getAttribute("commentaires");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    boolean corrected = "1".equals(request.getParameter("corrected"));
    boolean commented = "1".equals(request.getParameter("commented"));
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Correction TP – Enseignant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3 flex-1 min-w-0">
        <a href="<%= ctx %>/enseignant/CorrectionTPServlet?action=list"
           class="p-2 rounded-full hover:bg-blue-900 transition shrink-0">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
        </a>
        <span class="text-xl font-bold truncate">Correction : <%= tp != null ? tp.getTitre() : "" %></span>
    </div>
    <div class="flex items-center gap-2 shrink-0">
        <button id="notifBtn" onclick="toggleNotifPanel()" class="relative p-2 rounded-full hover:bg-blue-900 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (nbNotifs != null && nbNotifs > 0) { %>
            <span id="notifBadge" class="absolute top-0 right-0 w-4 h-4 bg-red-500 rounded-full text-xs flex items-center justify-center font-bold"><%= nbNotifs > 9 ? "9+" : nbNotifs %></span>
            <% } %>
        </button>
        <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2 p-1 rounded-full hover:bg-blue-900 transition">
            <div class="w-8 h-8 bg-blue-400 rounded-full flex items-center justify-center font-bold text-white text-xs">
                <%= userSession != null ? String.valueOf(userSession.getPrenom().charAt(0)) + userSession.getNom().charAt(0) : "EN" %>
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
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>
                </svg>
                Tableau de bord
            </a>
            <a href="<%= ctx %>/enseignant/CorrectionTPServlet?action=list"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                TPs
            </a>
            <a href="<%= ctx %>/enseignant/RapportServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
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
            <a href="<%= ctx %>/enseignant/AbsenceServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 17v-6h6v6m2 4H7a2 2 0 01-2-2V7a2 2 0 012-2h3l2-2h3l2 2h3a2 2 0 012 2v12a2 2 0 01-2 2z"/>
                </svg>
                Absence
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

    <main class="flex-1 p-6 max-w-3xl mx-auto w-full">
    <% if (corrected) { %>
    <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">
        ✅ Correction enregistrée. L'étudiant a été notifié.
    </div>
    <% } %>
    <% if (commented) { %>
    <div class="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded-lg mb-4 text-sm">
        💬 Commentaire ajouté.
    </div>
    <% } %>

    <% if (tp == null) { %>
    <div class="bg-red-50 text-red-600 p-4 rounded-xl">TP introuvable.</div>
    <% } else { %>

    <%-- Informations du TP --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <div class="flex items-start justify-between mb-4">
            <div>
                <h2 class="text-xl font-bold text-primary"><%= tp.getTitre() %></h2>
                <div class="flex items-center gap-3 mt-2 text-sm text-gray-500">
                    <% if (tp.getEtudiant() != null) { %>
                    <span class="flex items-center gap-1">
                        <div class="w-6 h-6 bg-green-100 rounded-full flex items-center justify-center
                                    text-xs font-bold text-green-700">
                            <%= String.valueOf(tp.getEtudiant().getPrenom().charAt(0)).toUpperCase() %>
                        </div>
                        <%= tp.getEtudiant().getNomComplet() %>
                    </span>
                    <% } %>
                    <span>📚 <%= tp.getModule() != null ? tp.getModule().getNom() : "–" %></span>
                    <span>📅 <%= sdf.format(tp.getDateSoumission()) %></span>
                    <% if (tp.getVersion() > 1) { %>
                    <span class="bg-purple-100 text-purple-600 text-xs px-2 py-0.5 rounded">
                        Version <%= tp.getVersion() %>
                    </span>
                    <% } %>
                </div>
                <% if (tp.getDescription() != null && !tp.getDescription().isEmpty()) { %>
                <div class="mt-3 p-3 bg-gray-50 rounded-lg text-sm text-gray-600">
                    <%= tp.getDescription() %>
                </div>
                <% } %>
            </div>
            <% if (tp.getNomFichier() != null) { %>
            <div class="flex flex-col items-center gap-1 ml-4">
                <div class="w-12 h-14 bg-blue-50 border border-blue-200 rounded-lg flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                </div>
                <p class="text-xs text-gray-400 max-w-[80px] truncate text-center"><%= tp.getNomFichier() %></p>
            </div>
            <% } %>
        </div>
    </div>

    <%-- Formulaire de correction --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <h3 class="font-bold text-primary mb-4 text-lg">📝 Saisir la correction</h3>
        <form action="<%= ctx %>/enseignant/CorrectionTPServlet" method="POST">
            <input type="hidden" name="action" value="corriger"/>
            <input type="hidden" name="travailId" value="<%= tp.getId() %>"/>

            <%-- Note --%>
            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Note (sur 20)
                </label>
                <div class="flex items-center gap-3">
                    <input type="number" name="note" min="0" max="20" step="0.25"
                           value="<%= tp.getNote() != null ? tp.getNote() : "" %>"
                           placeholder="ex: 14.5"
                           class="w-32 border border-gray-300 rounded-lg px-3 py-2 text-sm
                                  focus:outline-none focus:ring-2 focus:ring-primary text-center
                                  font-semibold text-lg"/>
                    <span class="text-gray-400 font-medium">/ 20</span>
                    <% if (tp.getNote() != null) { %>
                    <span class="text-green-600 font-bold text-lg"><%= tp.getNote() %>/20</span>
                    <% } %>
                </div>
            </div>

            <%-- Statut --%>
            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Statut</label>
                <select name="statut"
                        class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm
                               focus:outline-none focus:ring-2 focus:ring-primary">
                    <option value="EN_CORRECTION" <%= tp.getStatut() == TravailPratique.Statut.EN_CORRECTION ? "selected":"" %>>En correction</option>
                    <option value="CORRIGE"       <%= tp.getStatut() == TravailPratique.Statut.CORRIGE       ? "selected":"" %>>Corrigé</option>
                    <option value="RENDU"         <%= tp.getStatut() == TravailPratique.Statut.RENDU         ? "selected":"" %>>Rendu à l'étudiant</option>
                </select>
            </div>

            <%-- Feedback --%>
            <div class="mb-5">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Feedback détaillé
                </label>
                <textarea name="feedback" rows="5"
                          placeholder="Commentaires sur le travail, points forts, points à améliorer..."
                          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm
                                 focus:outline-none focus:ring-2 focus:ring-primary resize-none"></textarea>
                <p class="text-xs text-gray-400 mt-1">Le feedback sera ajouté comme commentaire visible par l'étudiant.</p>
            </div>

            <button type="submit"
                    class="w-full bg-primary text-white py-2.5 rounded-lg hover:bg-blue-900
                           transition text-sm font-medium">
                ✅ Enregistrer la correction et notifier l'étudiant
            </button>
        </form>
    </div>

    <%-- Section Commentaires --%>
    <div class="bg-white rounded-xl shadow p-6">
        <h3 class="font-bold text-primary mb-4 flex items-center gap-2">
            💬 Échanges
            <span class="text-sm font-normal text-gray-400">
                (<%= commentaires != null ? commentaires.size() : 0 %>)
            </span>
        </h3>

        <% if (commentaires != null && !commentaires.isEmpty()) { %>
        <p class="text-xs text-gray-500 mb-3">Messages de l'étudiant et vos réponses.</p>
        <div class="space-y-3 mb-5">
            <% for (Commentaire c : commentaires) {
                boolean isEns = c.getAuteur() != null &&
                    c.getAuteur().getRole() == Utilisateur.Role.ENSEIGNANT;
            %>
            <div class="flex gap-3 <%= isEns ? "flex-row-reverse" : "flex-row" %>">
                <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0
                            <%= isEns ? "bg-purple-100 text-purple-700" : "bg-green-100 text-green-700" %>">
                    <%= c.getAuteur() != null ? String.valueOf(c.getAuteur().getPrenom().charAt(0)).toUpperCase() : "?" %>
                </div>
                <div class="max-w-xs">
                    <div class="<%= isEns ? "bg-purple-50 border border-purple-100" : "bg-gray-50 border border-gray-200" %>
                                rounded-xl px-4 py-2">
                        <p class="text-xs font-semibold mb-1 <%= isEns ? "text-purple-700" : "text-gray-600" %>">
                            <%= isEns ? "Vous (Enseignant)" : "Étudiant · " + (c.getAuteur() != null ? c.getAuteur().getNomComplet() : "?") %>
                        </p>
                        <p class="text-sm text-gray-700"><%= c.getContenu() %></p>
                    </div>
                    <p class="text-xs text-gray-400 mt-1 <%= isEns ? "text-right" : "" %>">
                        <%= sdf.format(c.getDateCreation()) %>
                    </p>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>

        <%-- Répondre à l'étudiant --%>
        <p class="text-xs font-medium text-gray-600 mb-2">Répondre à l'étudiant</p>
        <form action="<%= ctx %>/enseignant/CorrectionTPServlet" method="POST">
            <input type="hidden" name="action" value="commenter"/>
            <input type="hidden" name="travailId" value="<%= tp.getId() %>"/>
            <div class="flex gap-3">
                <input type="text" name="contenu" placeholder="Votre réponse à l'étudiant..."
                       required maxlength="500"
                       class="flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary"/>
                <button type="submit"
                        class="bg-primary text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-900 transition">
                    Répondre
                </button>
            </div>
        </form>
    </div>

    <% } %>
    </main>
</div>
<script>
    function toggleNotifPanel() {
        var panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && document.getElementById('notifList').innerText === 'Chargement...') {
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
    }
    function toggleProfilePanel() { document.getElementById('profilePanel').classList.toggle('hidden'); }
    document.addEventListener('click', function(e) {
        var panel = document.getElementById('notifPanel'), btn = document.getElementById('notifBtn');
        if (btn && !panel.contains(e.target) && !btn.contains(e.target)) panel.classList.add('hidden');
    });
</script>
</body>
</html>