<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.Enseignant, model.Etudiant, model.Notification, java.util.List, java.util.Map, java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Enseignant> enseignants = (List<Enseignant>) request.getAttribute("enseignants");
    List<Etudiant> etudiants = (List<Etudiant>) request.getAttribute("etudiants");
    Map<Long, java.util.Date> lastMessageDateMap = (Map<Long, java.util.Date>) request.getAttribute("lastMessageDateMap");
    Map<Long, Long> unreadCountMap = (Map<Long, Long>) request.getAttribute("unreadCountMap");
    Long preselectedDestinataireId = (Long) request.getAttribute("preselectedDestinataireId");
    Utilisateur otherUser = (Utilisateur) request.getAttribute("otherUser");
    List<Notification> conversation = (List<Notification>) request.getAttribute("conversation");
    String activeSection = (String) request.getAttribute("activeSection");
    SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm", java.util.Locale.FRENCH);
    if (activeSection == null) activeSection = "messages";
    String ctx = request.getContextPath();
    boolean sent = "1".equals(request.getParameter("sent"));
    boolean error = request.getParameter("error") != null;
    String preType = "";
    if (preselectedDestinataireId != null) {
        if (enseignants != null) { for (Enseignant en : enseignants) { if (en.getId().equals(preselectedDestinataireId)) { preType = "enseignant"; break; } } }
        if ("".equals(preType) && etudiants != null) { for (Etudiant et : etudiants) { if (et.getId().equals(preselectedDestinataireId)) { preType = "etudiant"; break; } } }
    }
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Envoyer un message – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace de Travail</span>
    </div>
    <div class="flex items-center gap-4">
        <button onclick="toggleProfilePanel()" class="flex items-center gap-2">
            <div class="w-9 h-9 bg-blue-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
                <%= userSession != null && userSession.getPrenom() != null && userSession.getNom() != null ? String.valueOf(userSession.getPrenom().charAt(0)) + String.valueOf(userSession.getNom().charAt(0)) : "AD" %>
            </div>
            <span class="text-sm font-medium hidden md:block"><%= userSession != null ? userSession.getNomComplet() : "Admin" %></span>
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
        <p><span class="font-semibold">Rôle :</span> <%= userSession != null ? userSession.getRole().name() : "-" %></p>
    </div>
</div>

<div class="flex flex-1">
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/admin/ModuleServlet?action=list" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Modules
            </a>
            <a href="<%= ctx %>/admin/EtudiantServlet?action=list" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                Étudiants
            </a>
            <a href="<%= ctx %>/admin/EnseignantServlet?action=list" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                Enseignants
            </a>
            <a href="<%= ctx %>/admin/MessageServlet" class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
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
        <h2 class="text-2xl font-bold text-primary mb-2">Envoyer un message</h2>
        <p class="text-gray-500 text-sm mb-6">Envoyez un commentaire à un enseignant ou un étudiant. Il apparaîtra dans ses notifications.</p>

        <% if (sent) { %>
        <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">✅ Message envoyé.</div>
        <% } %>
        <% if (error) { %>
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">⚠️ Veuillez remplir le destinataire et le message.</div>
        <% } %>

        <div class="bg-white rounded-xl shadow p-6 max-w-xl">
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-2">Destinataire</label>
                <select name="type" id="type" class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm mb-2">
                    <option value="">-- Type --</option>
                    <option value="enseignant">Enseignant</option>
                    <option value="etudiant">Étudiant</option>
                </select>
                <select id="destinataireId" class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm">
                    <option value="">-- Choisir un destinataire pour voir la conversation --</option>
                    <% if (enseignants != null) for (Enseignant e : enseignants) {
                        java.util.Date lastDate = (lastMessageDateMap != null) ? lastMessageDateMap.get(e.getId()) : null;
                        Long unread = (unreadCountMap != null) ? unreadCountMap.get(e.getId()) : null;
                        int unreadInt = (unread != null && unread > 0) ? unread.intValue() : 0;
                    %>
                    <option value="<%= e.getId() %>" data-type="enseignant"<%= (preselectedDestinataireId != null && preselectedDestinataireId.equals(e.getId())) ? " selected" : "" %>><%= e.getNomComplet() %><%= lastDate != null ? " – Dernier: " + sdfTime.format(lastDate) : "" %><%= unreadInt > 0 ? " (" + unreadInt + " non lu(s))" : "" %></option>
                    <% } %>
                    <% if (etudiants != null) for (Etudiant e : etudiants) {
                        java.util.Date lastDate = (lastMessageDateMap != null) ? lastMessageDateMap.get(e.getId()) : null;
                        Long unread = (unreadCountMap != null) ? unreadCountMap.get(e.getId()) : null;
                        int unreadInt = (unread != null && unread > 0) ? unread.intValue() : 0;
                    %>
                    <option value="<%= e.getId() %>" data-type="etudiant"<%= (preselectedDestinataireId != null && preselectedDestinataireId.equals(e.getId())) ? " selected" : "" %>><%= e.getNomComplet() %><%= lastDate != null ? " – Dernier: " + sdfTime.format(lastDate) : "" %><%= unreadInt > 0 ? " (" + unreadInt + " non lu(s))" : "" %></option>
                    <% } %>
                </select>
            </div>
            <% if (otherUser != null) { %>
            <div class="border-t border-gray-200 pt-4 mt-4">
                <h3 class="text-sm font-semibold text-primary mb-3">Conversation avec <%= otherUser.getNomComplet() %></h3>
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
                <form method="post" action="<%= ctx %>/admin/MessageServlet">
                    <% boolean otherIsEnseignant = false; if (enseignants != null) for (Enseignant e : enseignants) { if (e.getId().equals(otherUser.getId())) { otherIsEnseignant = true; break; } } %>
                    <input type="hidden" name="type" value="<%= otherIsEnseignant ? "enseignant" : "etudiant" %>"/>
                    <input type="hidden" name="destinataireId" value="<%= otherUser.getId() %>"/>
                    <div class="mb-3">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Répondre</label>
                        <textarea name="message" required rows="3" maxlength="1000" placeholder="Votre message..."
                                  class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm"></textarea>
                    </div>
                    <button type="submit" class="bg-primary text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-900 transition">Envoyer</button>
                </form>
            </div>
            <% } %>
        </div>
    </main>
</div>
<script>
    function toggleProfilePanel() { document.getElementById('profilePanel').classList.toggle('hidden'); }
    var ctx = '<%= ctx %>';
    var preType = '<%= preType %>';
    var preselectedDestId = '<%= preselectedDestinataireId != null ? preselectedDestinataireId : "" %>';
    document.getElementById('type').addEventListener('change', function() {
        var type = this.value;
        var sel = document.getElementById('destinataireId');
        for (var i = 0; i < sel.options.length; i++) {
            var opt = sel.options[i];
            if (opt.value === '') { opt.style.display = 'block'; continue; }
            opt.style.display = (opt.getAttribute('data-type') === type || !type) ? 'block' : 'none';
        }
        if (!type) sel.value = '';
    });
    document.getElementById('destinataireId').addEventListener('change', function() {
        if (this.value) window.location = ctx + '/admin/MessageServlet?destinataireId=' + this.value;
    });
    if (preselectedDestId) {
        (function() {
            var typeSel = document.getElementById('type');
            var destSel = document.getElementById('destinataireId');
            typeSel.value = preType;
            for (var i = 0; i < destSel.options.length; i++) {
                var opt = destSel.options[i];
                opt.style.display = (opt.getAttribute('data-type') === preType || opt.value === '') ? 'block' : 'none';
            }
            destSel.value = preselectedDestId;
        })();
    }
</script>
</body>
</html>
