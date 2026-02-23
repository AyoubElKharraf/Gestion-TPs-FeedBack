<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.Rapport, model.Module, model.TravailPratique, java.text.SimpleDateFormat, java.util.Date" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    Rapport rapport = (Rapport) request.getAttribute("rapport");
    Module module = (Module) request.getAttribute("module");
    TravailPratique tpPourModule = (TravailPratique) request.getAttribute("tpPourModule");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM.", new java.util.Locale("fr"));
    SimpleDateFormat sdfLong = new SimpleDateFormat("dd/MM/yyyy HH:mm", new java.util.Locale("fr"));
    String enseignantNom = (module != null && module.getEnseignant() != null) ? module.getEnseignant().getNomComplet() : "";
    Long enseignantId = (module != null && module.getEnseignant() != null) ? module.getEnseignant().getId() : null;
    boolean dateLimiteDepassee = (rapport != null && rapport.getDateLimite() != null && rapport.getDateLimite().before(new Date()));
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title><%= rapport != null ? rapport.getTitre() : "Devoir" %> – Étudiant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=devoirs"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold">Devoir</span>
    <button type="button" onclick="toggleProfilePanel()" class="flex items-center gap-2 p-1 rounded-full hover:bg-blue-900 transition">
        <div class="w-9 h-9 bg-green-400 rounded-full flex items-center justify-center font-bold text-white text-sm">
            <% if (userSession != null && userSession.getPrenom() != null && userSession.getNom() != null) {
                String p = (userSession.getPrenom() != null && !userSession.getPrenom().isEmpty()) ? String.valueOf(userSession.getPrenom().charAt(0)) : "?";
                String n = (userSession.getNom() != null && !userSession.getNom().isEmpty()) ? String.valueOf(userSession.getNom().charAt(0)) : "?";
                out.print(p + n);
            } else { %>ET<% } %>
        </div>
    </button>
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

<div class="flex flex-1">
    <%-- Sidebar (TPs & Feedback on the side for student) --%>
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full flex-shrink-0">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=modules"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Modules
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=devoirs"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium bg-primary text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                Mes TPs
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=feedback"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Feedback des TPs
            </a>
            <a href="<%= ctx %>/etudiant/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
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
    <div class="flex flex-1 p-6 max-w-5xl w-full gap-6 overflow-auto">
    <%-- Colonne gauche : contenu du devoir --%>
    <div class="flex-1 min-w-0">
        <div class="bg-white rounded-xl shadow border border-gray-100 overflow-hidden">
            <div class="p-5 border-b border-gray-100">
                <div class="flex items-start justify-between gap-3">
                    <div class="flex items-start gap-3 min-w-0">
                        <div class="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                        </div>
                        <div class="min-w-0">
                            <h1 class="text-xl font-bold text-gray-800"><%= rapport != null ? rapport.getTitre() : "Devoir" %></h1>
                            <p class="text-sm text-gray-500 mt-0.5"><%= enseignantNom %> • <%= rapport != null ? sdf.format(rapport.getDateCreation()) : "" %></p>
                            <% if (rapport != null && rapport.getDateLimite() != null) { %>
                            <p class="text-xs text-amber-600 mt-1">Date limite : <%= new java.text.SimpleDateFormat("dd MMM. HH:mm", new java.util.Locale("fr")).format(rapport.getDateLimite()) %></p>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>

            <%-- Fichier joint (rapport) --%>
            <div class="p-5 border-b border-gray-100">
                <p class="text-sm font-medium text-gray-700 mb-2">Document du cours</p>
                <a href="<%= ctx %>/RapportDownloadServlet?id=<%= rapport != null ? rapport.getId() : "" %>"
                   class="flex items-center gap-4 p-4 bg-gray-50 hover:bg-gray-100 rounded-xl border border-gray-100 transition">
                    <div class="w-12 h-14 bg-red-100 rounded flex items-center justify-center flex-shrink-0">
                        <span class="text-red-600 font-bold text-sm">PDF</span>
                    </div>
                    <div class="min-w-0 flex-1">
                        <p class="font-medium text-gray-800 truncate"><%= rapport != null && rapport.getFileName() != null ? rapport.getFileName() : "Support de cours" %></p>
                        <p class="text-xs text-gray-500">Télécharger le document</p>
                    </div>
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-primary flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                    </svg>
                </a>
            </div>

            <%-- Commentaires du cours --%>
            <div class="p-5">
                <p class="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                    Commentaires ajoutés au cours
                </p>
                <% if (tpPourModule != null) { %>
                <a href="<%= ctx %>/etudiant/DepotTPServlet?action=detail&id=<%= tpPourModule.getId() %>" class="text-sm text-primary hover:underline flex items-center gap-1">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
                    Voir les commentaires de mon rendu
                </a>
                <% } else { %>
                <p class="text-xs text-gray-500">Déposez un TP pour participer aux échanges.</p>
                <% } %>
            </div>
        </div>
    </div>

    <%-- Colonne droite : Vos devoirs --%>
    <div class="w-80 flex-shrink-0">
        <div class="bg-white rounded-xl shadow border border-gray-100 p-5 sticky top-6">
            <div class="flex items-center justify-between mb-4">
                <h2 class="font-bold text-gray-800">Vos devoirs</h2>
                <span class="text-xs px-2.5 py-1 rounded-full <%= tpPourModule != null ? "bg-green-100 text-green-700" : "bg-amber-100 text-amber-700" %> font-medium">
                    <%= tpPourModule != null ? "Rendu" : "Attribué" %>
                </span>
            </div>
            <% if (tpPourModule != null) { %>
            <p class="text-sm text-gray-600 mb-3">Vous avez déposé un TP pour ce devoir.</p>
            <% if (!dateLimiteDepassee) { %>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=detail&id=<%= tpPourModule.getId() %>"
               class="block w-full text-center py-2.5 px-4 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium text-gray-700 transition mb-4">
                Voir mon rendu
            </a>
            <% } else { %>
            <p class="text-xs text-amber-600 font-medium mb-4">⏰ Date limite dépassée. Le bouton « Voir mon rendu » n'est plus disponible.</p>
            <% } %>
            <% } else { %>
            <% if (dateLimiteDepassee) { %>
            <p class="text-sm text-gray-600 mb-3">Vous n'avez pas déposé de TP pour ce devoir.</p>
            <p class="text-xs text-amber-600 font-medium mb-4">⏰ Date limite dépassée. Vous ne pouvez plus déposer de TP pour ce devoir.</p>
            <% } else { %>
            <p class="text-sm text-gray-600 mb-3">Déposez votre travail pour ce devoir.</p>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form<%= module != null ? "&moduleId=" + module.getId() : "" %><%= rapport != null ? "&rapportId=" + rapport.getId() : "" %>"
               class="flex items-center justify-center gap-2 w-full py-3 px-4 bg-primary text-white rounded-lg hover:bg-blue-900 transition text-sm font-medium mb-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                Déposer un TP
            </a>
            <p class="text-xs text-gray-400">Consultez le document ci-contre puis déposez votre travail.</p>
            <% } %>
            <% } %>

            <div class="pt-4 border-t border-gray-100 mt-4">
                <p class="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    Commentaires privés
                </p>
                <a href="<%= ctx %>/etudiant/MessageServlet<%= enseignantId != null ? "?destinataireId=" + enseignantId : "" %>"
                   class="text-sm text-primary hover:underline flex items-center gap-1">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
                    Envoyer un message à <%= enseignantNom %>
                </a>
            </div>
        </div>
    </div>
    </div>
</div>
<script>
    function toggleProfilePanel() {
        document.getElementById('profilePanel').classList.toggle('hidden');
    }
    document.addEventListener('click', function(e) {
        const profilePanel = document.getElementById('profilePanel');
        const profileBtn = document.querySelector('button[onclick="toggleProfilePanel()"]');
        if (profilePanel && profileBtn && !profilePanel.contains(e.target) && !profileBtn.contains(e.target)) {
            profilePanel.classList.add('hidden');
        }
    });
</script>
</body>
</html>
