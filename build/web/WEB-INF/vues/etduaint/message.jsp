<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.Enseignant, model.Notification, java.util.List, java.util.Map, java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Enseignant> enseignants = (List<Enseignant>) request.getAttribute("enseignants");
    Map<Long, java.util.Date> lastMessageDateMap = (Map<Long, java.util.Date>) request.getAttribute("lastMessageDateMap");
    Map<Long, Long> unreadCountMap = (Map<Long, Long>) request.getAttribute("unreadCountMap");
    Long preselectedDestinataireId = (Long) request.getAttribute("preselectedDestinataireId");
    Utilisateur otherUser = (Utilisateur) request.getAttribute("otherUser");
    List<Notification> conversation = (List<Notification>) request.getAttribute("conversation");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm", java.util.Locale.FRENCH);
    boolean sent = "1".equals(request.getParameter("sent"));
    boolean error = request.getParameter("error") != null;
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Envoyer un message – Étudiant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">
<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace Étudiant</span>
    </div>
    <div class="flex items-center gap-3">
        <button id="notifBtn" onclick="toggleNotifPanel()" class="relative p-2 rounded-full hover:bg-blue-900 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (nbNotifs != null && nbNotifs > 0) { %>
            <span id="notifBadge" class="absolute top-0 right-0 w-4 h-4 bg-red-500 rounded-full text-xs flex items-center justify-center font-bold"><%= nbNotifs > 9 ? "9+" : nbNotifs %></span>
            <% } %>
        </button>
        <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2">
            <div class="w-9 h-9 bg-green-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
                <% if (userSession != null && userSession.getPrenom() != null && userSession.getNom() != null) {
                    String p = (userSession.getPrenom() != null && !userSession.getPrenom().isEmpty()) ? String.valueOf(userSession.getPrenom().charAt(0)) : "?";
                    String n = (userSession.getNom() != null && !userSession.getNom().isEmpty()) ? String.valueOf(userSession.getNom().charAt(0)) : "?";
                    out.print(p + n);
                } else { %>ET<% } %>
            </div>
            <span class="text-sm font-medium hidden md:block"><%= userSession != null && userSession.getNom() != null && userSession.getPrenom() != null ? userSession.getNomComplet() : "Étudiant" %></span>
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
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=modules" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Modules
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=devoirs" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                Mes TPs
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=feedback" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Feedback des TPs
            </a>
            <a href="<%= ctx %>/etudiant/MessageServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
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
    <main class="flex-1 p-6">
        <h2 class="text-2xl font-bold text-primary mb-2">Envoyer un message à un enseignant</h2>
        <p class="text-gray-500 text-sm mb-6">Les enseignants listés sont ceux de vos modules (TPs déposés). Le message apparaîtra dans leurs notifications.</p>
        <% if (sent) { %>
        <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">✅ Message envoyé.</div>
        <% } %>
        <% if (error) { %>
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">⚠️ Veuillez remplir le destinataire et le message.</div>
        <% } %>
        <% if (enseignants == null || enseignants.isEmpty()) { %>
        <div class="bg-white rounded-xl shadow p-8 text-center text-gray-500">
            Aucun enseignant pour l'instant. Déposez un TP dans un module pour voir les enseignants ici.
        </div>
        <% } else if (otherUser != null) { %>
        <div class="bg-white rounded-xl shadow p-6 max-w-xl">
            <h3 class="text-lg font-semibold text-primary mb-3">Conversation avec <%= otherUser.getNomComplet() %></h3>
            <% if (conversation != null && !conversation.isEmpty()) { %>
            <p class="text-xs text-gray-500 mb-2">Dernier message : <%= sdfTime.format(conversation.get(conversation.size()-1).getDateCreation()) %></p>
            <% } %>
            <div class="bg-gray-50 rounded-xl p-4 mb-4 max-h-80 overflow-y-auto space-y-2">
                <% if (conversation != null && !conversation.isEmpty()) {
                    for (Notification n : conversation) {
                        boolean fromMe = n.getExpediteur() != null && userSession != null && n.getExpediteur().getId().equals(userSession.getId());
                        boolean iAmDest = userSession != null && n.getDestinataire() != null && n.getDestinataire().getId().equals(userSession.getId());
                %>
                <div class="flex <%= fromMe ? "justify-end" : "justify-start" %>">
                    <div class="max-w-[85%] rounded-2xl px-4 py-2 <%= fromMe ? "bg-primary text-white" : "bg-white border border-gray-200 text-gray-800" %>">
                        <p class="text-sm"><%= n.getMessage() != null ? n.getMessage().replace("<", "&lt;").replace(">", "&gt;") : "" %></p>
                        <p class="text-xs mt-1 opacity-80"><%= n.getDateCreation() != null ? sdfTime.format(n.getDateCreation()) : "" %><% if (iAmDest) { %> · <%= n.isLu() ? "Lu" : "Non lu" %><% } %></p>
                    </div>
                </div>
                <% } } else { %>
                <p class="text-gray-400 text-sm text-center py-4">Aucun message encore. Envoyez le premier.</p>
                <% } %>
            </div>
            <form method="post" action="<%= ctx %>/etudiant/MessageServlet">
                <input type="hidden" name="destinataireId" value="<%= otherUser.getId() %>"/>
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Répondre</label>
                    <textarea name="message" required rows="3" maxlength="1000" placeholder="Votre message..."
                              class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm"></textarea>
                </div>
                <button type="submit" class="bg-primary text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-900 transition">Envoyer</button>
            </form>
        </div>
        <% } else { %>
        <div class="bg-white rounded-xl shadow p-6 max-w-xl">
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-2">Enseignant</label>
                <select id="selectEnseignant" class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm">
                    <option value="">-- Choisir un destinataire pour voir la conversation --</option>
                    <% for (Enseignant e : enseignants) {
                        java.util.Date lastDate = (lastMessageDateMap != null) ? lastMessageDateMap.get(e.getId()) : null;
                        Long unread = (unreadCountMap != null) ? unreadCountMap.get(e.getId()) : null;
                        int unreadInt = (unread != null && unread > 0) ? unread.intValue() : 0;
                    %>
                    <option value="<%= e.getId() %>"<%= (preselectedDestinataireId != null && preselectedDestinataireId.equals(e.getId())) ? " selected" : "" %>><%= e.getNomComplet() %><%= lastDate != null ? " – Dernier msg: " + sdfTime.format(lastDate) : "" %><%= unreadInt > 0 ? " (" + unreadInt + " non lu(s))" : "" %></option>
                    <% } %>
                </select>
            </div>
            <p class="text-gray-500 text-sm">Sélectionnez un enseignant pour afficher la conversation et répondre.</p>
        </div>
        <script>
            document.getElementById('selectEnseignant').addEventListener('change', function() {
                if (this.value) window.location = '<%= ctx %>/etudiant/MessageServlet?destinataireId=' + this.value;
            });
        </script>
        <% } %>
    </main>
</div>
<script>
    function toggleNotifPanel() {
        var panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && document.getElementById('notifList').innerText === 'Chargement...')
            fetch('<%= ctx %>/NotificationServlet?action=liste-json').then(function(r){ return r.json(); }).then(function(data){
                var list = document.getElementById('notifList');
                if (!data.length) { list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>'; return; }
                list.innerHTML = data.map(function(n){
                    var content = '<p class="text-xs text-gray-500">' + (n.expediteur ? 'De: ' + n.expediteur : '') + '</p><p class="text-sm text-gray-700">' + (n.message||'') + '</p><p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' + (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                    var cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                    var url = n.replyUrl || n.markReadUrl;
                    return url ? '<a href="' + url + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
                }).join('');
            });
    }
    function toggleProfilePanel() {
        document.getElementById('profilePanel').classList.toggle('hidden');
    }
    document.addEventListener('click', function(e) {
        var panel = document.getElementById('notifPanel'), btn = document.getElementById('notifBtn');
        if (btn && !panel.contains(e.target) && !btn.contains(e.target)) panel.classList.add('hidden');
        var profilePanel = document.getElementById('profilePanel'), profileBtn = document.querySelector('button[onclick="toggleProfilePanel()"]');
        if (profilePanel && profileBtn && !profilePanel.contains(e.target) && !profileBtn.contains(e.target)) profilePanel.classList.add('hidden');
    });
</script>
</body>
</html>
