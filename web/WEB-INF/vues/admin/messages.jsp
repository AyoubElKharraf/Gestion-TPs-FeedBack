<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.Enseignant, model.Etudiant, java.util.List" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Enseignant> enseignants = (List<Enseignant>) request.getAttribute("enseignants");
    List<Etudiant> etudiants = (List<Etudiant>) request.getAttribute("etudiants");
    Long preselectedDestinataireId = (Long) request.getAttribute("preselectedDestinataireId");
    String activeSection = (String) request.getAttribute("activeSection");
    if (activeSection == null) activeSection = "messages";
    String ctx = request.getContextPath();
    boolean sent = "1".equals(request.getParameter("sent"));
    boolean error = request.getParameter("error") != null;
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
                <%= userSession != null ? String.valueOf(userSession.getPrenom().charAt(0)) + userSession.getNom().charAt(0) : "AD" %>
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
            <form method="post" action="<%= ctx %>/admin/MessageServlet">
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Destinataire</label>
                    <select name="type" id="type" required class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm mb-2">
                        <option value="">-- Type --</option>
                        <option value="enseignant">Enseignant</option>
                        <option value="etudiant">Étudiant</option>
                    </select>
                    <select name="destinataireId" id="destinataireId" required class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm">
                        <option value="">-- Choisir --</option>
                        <% if (enseignants != null) for (Enseignant e : enseignants) { %>
                        <option value="<%= e.getId() %>" data-type="enseignant"<%= (preselectedDestinataireId != null && preselectedDestinataireId.equals(e.getId())) ? " selected" : "" %>><%= e.getNomComplet() %> – <%= e.getEmail() %></option>
                        <% } %>
                        <% if (etudiants != null) for (Etudiant e : etudiants) { %>
                        <option value="<%= e.getId() %>" data-type="etudiant"<%= (preselectedDestinataireId != null && preselectedDestinataireId.equals(e.getId())) ? " selected" : "" %>><%= e.getNomComplet() %> – <%= e.getEmail() %></option>
                        <% } %>
                    </select>
                </div>
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Message</label>
                    <textarea name="message" required rows="4" maxlength="1000" placeholder="Votre message..."
                              class="border border-gray-300 rounded-lg px-3 py-2 w-full text-sm"></textarea>
                </div>
                <button type="submit" class="bg-primary text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-900 transition">Envoyer</button>
            </form>
        </div>
    </main>
</div>
<script>
    function toggleProfilePanel() { document.getElementById('profilePanel').classList.toggle('hidden'); }
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
    <% if (preselectedDestinataireId != null) {
        String preType = "";
        if (enseignants != null) { for (Enseignant e : enseignants) { if (e.getId().equals(preselectedDestinataireId)) { preType = "enseignant"; break; } } }
        if ("".equals(preType) && etudiants != null) { for (Etudiant e : etudiants) { if (e.getId().equals(preselectedDestinataireId)) { preType = "etudiant"; break; } } }
    %>
    (function() {
        var typeSel = document.getElementById('type');
        var destSel = document.getElementById('destinataireId');
        typeSel.value = '<%= preType %>';
        for (var i = 0; i < destSel.options.length; i++) {
            var opt = destSel.options[i];
            opt.style.display = (opt.getAttribute('data-type') === '<%= preType %>' || opt.value === '') ? 'block' : 'none';
        }
        destSel.value = '<%= preselectedDestinataireId %>';
    })();
    <% } %>
</script>
</body>
</html>
