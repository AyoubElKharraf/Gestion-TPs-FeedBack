<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur,model.TravailPratique,model.Module,model.Rapport,java.util.List,java.util.Date,java.util.Locale,java.text.SimpleDateFormat" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<TravailPratique> travaux = (List<TravailPratique>) request.getAttribute("travaux");
    List<Module> modules = (List<Module>) request.getAttribute("modules");
    List<Rapport> rapports = (List<Rapport>) request.getAttribute("rapports");
    String section = (String) request.getAttribute("section");
    if (section == null) section = "modules";
    Long moduleFiltreId = (Long) request.getAttribute("moduleFiltreId");
    String filtreStatut = (String) request.getAttribute("filtreStatut");
    String filtreDateMin = (String) request.getAttribute("filtreDateMin");
    String filtreDateMax = (String) request.getAttribute("filtreDateMax");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
    boolean success = "1".equals(request.getParameter("success"));
    boolean deleted = "1".equals(request.getParameter("deleted"));
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    SimpleDateFormat sdfJour = new SimpleDateFormat("EEEE", Locale.FRENCH);
    SimpleDateFormat sdfHeure = new SimpleDateFormat("HH:mm");
    SimpleDateFormat sdfCourt = new SimpleDateFormat("d MMM", Locale.FRENCH);
    Date now = new Date();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Mes TPs – Étudiant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<%-- HEADER --%>
<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace Étudiant</span>
    </div>
    <div class="flex items-center gap-3">
        <%-- Cloche notifications --%>
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

<%-- Panneau notifications AJAX --%>
<div id="notifPanel"
     class="fixed right-4 top-16 w-80 bg-white shadow-xl rounded-xl z-50 hidden border border-gray-200">
    <div class="px-4 py-3 border-b font-semibold text-primary flex justify-between items-center">
        <span>Notifications</span>
        <div class="flex gap-2">
            <a href="<%= ctx %>/NotificationServlet?action=tout-lire"
               class="text-xs text-blue-600 hover:underline">Tout lire</a>
            <button onclick="toggleNotifPanel()" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
    </div>
    <div id="notifList" class="divide-y max-h-72 overflow-y-auto">
        <div class="px-4 py-4 text-center text-gray-400 text-sm">Chargement...</div>
    </div>
    <div class="px-4 py-3 border-t text-center">
        <a href="<%= ctx %>/NotificationServlet" class="text-xs text-primary hover:underline">
            Voir toutes les notifications
        </a>
    </div>
</div>

<div class="flex flex-1">
    <%-- SIDEBAR --%>
    <aside class="w-64 bg-white shadow-md flex flex-col min-h-full">
        <nav class="flex flex-col p-4 gap-2 flex-1">
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=modules"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "modules".equals(section) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                Modules
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=devoirs"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "devoirs".equals(section) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M12 4v16m8-8H4"/>
                </svg>
                Mes TPs
            </a>
            <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list&section=feedback"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition <%= "feedback".equals(section) ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100" %>">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                Feedback des TPs
            </a>
            <a href="<%= ctx %>/etudiant/MessageServlet"
               class="flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                </svg>
                Envoyer un message
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

    <main class="flex-1 p-6 max-w-5xl mx-auto w-full">

    <%-- Alertes --%>
    <% if (success) { %>
    <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">
        ✅ TP déposé avec succès. L'enseignant a été notifié.
    </div>
    <% } %>
    <% if (deleted) { %>
    <div class="bg-orange-50 border border-orange-200 text-orange-700 px-4 py-3 rounded-lg mb-4 text-sm">
        🗑️ TP supprimé.
    </div>
    <% } %>
    <% if ("1".equals(request.getParameter("deadlineDepasse"))) { %>
    <div class="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg mb-4 text-sm">
        ⏰ La date limite pour déposer ou modifier ce TP est dépassée.
    </div>
    <% } %>

    <%-- Section Modules (affichage type Classroom) --%>
    <% if ("modules".equals(section)) { %>
    <div id="modulesSection" class="mb-8">
        <h2 class="text-xl font-bold text-primary mb-4">Mes modules</h2>
        <% if (modules == null || modules.isEmpty()) { %>
        <p class="text-gray-400 text-sm">Aucun module disponible pour le moment.</p>
        <% } else { %>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <%
            String[] headerBg = new String[] { "bg-blue-600", "bg-gray-700" };
            String[] avatarBg = new String[] { "bg-white text-gray-700 border-2 border-gray-200", "bg-red-700 text-white border-0" };
            int idx = 0;
            for (model.Module m : modules) {
                String headerClass = headerBg[idx % 2];
                String avatarClass = avatarBg[idx % 2];
                idx++;
                String enseignantNom = (m.getEnseignant() != null) ? m.getEnseignant().getNomComplet() : "Sans enseignant";
                String enseignantInitial = "?";
                if (m.getEnseignant() != null && m.getEnseignant().getPrenom() != null && !m.getEnseignant().getPrenom().isEmpty() && m.getEnseignant().getNom() != null && !m.getEnseignant().getNom().isEmpty()) {
                    enseignantInitial = String.valueOf(m.getEnseignant().getPrenom().charAt(0)) + String.valueOf(m.getEnseignant().getNom().charAt(0));
                } else if (m.getEnseignant() != null && m.getEnseignant().getNom() != null && !m.getEnseignant().getNom().isEmpty()) {
                    enseignantInitial = String.valueOf(m.getEnseignant().getNom().charAt(0));
                }
                boolean canDepotModule = true;
                Rapport prochainRapport = null;
                Rapport dernierRapportAvecLimite = null;
                if (rapports != null && m != null) {
                    Date maxLimite = null;
                    for (Rapport r : rapports) {
                        if (r.getModule() != null && r.getModule().getId().equals(m.getId()) && r.getDateLimite() != null) {
                            if (maxLimite == null || r.getDateLimite().after(maxLimite)) {
                                maxLimite = r.getDateLimite();
                                dernierRapportAvecLimite = r;
                            }
                            if (r.getDateLimite().after(now) && (prochainRapport == null || r.getDateLimite().before(prochainRapport.getDateLimite())))
                                prochainRapport = r;
                        }
                    }
                    if (maxLimite != null && now.after(maxLimite)) canDepotModule = false;
                }
            %>
            <div class="bg-white rounded-2xl shadow-lg border border-gray-200 overflow-hidden hover:shadow-xl transition flex flex-col">
                <%-- En-tête style Classroom : bandeau coloré + avatar enseignant --%>
                <div class="<%= headerClass %> relative min-h-[120px] px-5 pt-5 pb-3 flex flex-col justify-end">
                    <%-- Icône décorative (chapeau) en haut à droite --%>
                    <div class="absolute top-3 right-3 opacity-20">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-10 h-10 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12 3L2 12h3v9h14v-9h3L12 3zm0 2.5l6.5 6.5H14v7h-4v-7H5.5L12 5.5z"/></svg>
                    </div>
                    <p class="text-white font-bold text-xl underline decoration-white/40"><%= m.getNom() %></p>
                    <p class="text-white/90 text-sm underline decoration-white/30 mt-0.5"><%= m.getFiliere() != null ? m.getFiliere() + " 2025-2026" : "M2I 2025-2026" %></p>
                    <p class="text-white/90 text-sm mt-1"><%= enseignantNom %></p>
                    <%-- Avatar enseignant (initial) qui chevauche le contenu --%>
                    <div class="absolute bottom-0 right-4 translate-y-1/2 w-14 h-14 rounded-full flex items-center justify-center font-bold text-lg shadow-md <%= avatarClass %>">
                        <%= enseignantInitial %>
                    </div>
                </div>
                <%-- Zone blanche : date limite (toujours affichée si elle existe), puis bouton Déposer --%>
                <div class="flex-1 p-5 pt-10 min-h-[100px]">
                    <% if (prochainRapport != null && prochainRapport.getDateLimite() != null) {
                        String jour = sdfJour.format(prochainRapport.getDateLimite());
                        String heure = sdfHeure.format(prochainRapport.getDateLimite());
                        String titreRapport = prochainRapport.getTitre() != null ? prochainRapport.getTitre() : "Devoir";
                    %>
                    <p class="text-sm text-gray-600 mb-2">
                        <span class="font-medium text-gray-700">Date limite :</span> <%= jour %> <%= heure %> – <%= titreRapport %>
                    </p>
                    <% } else if (dernierRapportAvecLimite != null && dernierRapportAvecLimite.getDateLimite() != null) {
                        String jour = sdfJour.format(dernierRapportAvecLimite.getDateLimite());
                        String heure = sdfHeure.format(dernierRapportAvecLimite.getDateLimite());
                        String titreRapport = dernierRapportAvecLimite.getTitre() != null ? dernierRapportAvecLimite.getTitre() : "Devoir";
                    %>
                    <p class="text-sm text-gray-600 mb-2">
                        <span class="font-medium text-gray-700">Date limite :</span> <%= jour %> <%= heure %> – <%= titreRapport %> <span class="text-amber-600">(dépassée)</span>
                    </p>
                    <% } %>
                    <% if (!canDepotModule) { %>
                    <p class="text-xs text-amber-600 font-medium mb-2">⏰ Date limite dépassée pour ce module.</p>
                    <% } %>
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&moduleId=<%= m.getId() %>"
                       class="inline-flex items-center gap-1.5 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-xl hover:bg-gray-50 transition text-sm font-medium">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                        Déposer un TP
                    </a>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>
    <% } %>

    <%-- Section Devoirs annoncés – flux type Classroom --%>
    <% if ("devoirs".equals(section)) { %>
    <div id="devoirsSection" class="mb-8">
        <h2 class="text-xl font-bold text-primary mb-4">Mes TPs – Devoirs annoncés</h2>
        <% if (rapports == null || rapports.isEmpty()) { %>
        <div class="bg-white rounded-xl shadow border border-gray-100 p-12 text-center text-gray-400">
            <p class="font-medium">Aucun devoir annoncé pour vos modules.</p>
        </div>
        <% } else { %>
        <div class="space-y-4">
            <% for (Rapport r : rapports) {
                if (r.getModule() == null) continue;
                String auteurNom = (r.getModule().getEnseignant() != null) ? r.getModule().getEnseignant().getNomComplet() : "Enseignant";
                String datePubli = r.getDateCreation() != null ? sdfCourt.format(r.getDateCreation()) : "";
            %>
            <div class="bg-white rounded-xl shadow border border-gray-100 overflow-hidden hover:shadow-md transition">
                <div class="p-5">
                    <div class="flex items-start gap-3">
                        <%-- Avatar type document (devoir) --%>
                        <div class="w-10 h-10 rounded-full bg-gray-500 flex items-center justify-center flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="font-semibold text-gray-800"><%= auteurNom %> a publié un nouveau devoir : <%= r.getTitre() != null ? r.getTitre() : "Devoir" %></p>
                            <p class="text-sm text-gray-500 mt-0.5">Publié le <%= datePubli %></p>
                            <% if (r.getDateLimite() != null) {
                                String dateLimStr = sdfCourt.format(r.getDateLimite()) + " " + sdfHeure.format(r.getDateLimite());
                            %>
                            <p class="text-sm text-amber-600 font-medium mt-1">Date limite : <%= dateLimStr %></p>
                            <% } %>
                        </div>
                        <button type="button" class="p-1 rounded-full hover:bg-gray-100 text-gray-400 hover:text-gray-600 flex-shrink-0" aria-label="Options">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                        </button>
                    </div>
                    <div class="mt-4 pt-4 border-t border-gray-100 flex justify-center">
                        <a href="<%= ctx %>/etudiant/DepotTPServlet?action=voir-devoir&rapportId=<%= r.getId() %>"
                           class="inline-flex items-center gap-2 px-4 py-2 text-blue-600 hover:bg-blue-50 rounded-lg transition text-sm font-medium">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
                            Voir le devoir
                        </a>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>
    <% } %>

    <%-- Section Feedback des TPs – flux type Classroom --%>
    <% if ("feedback".equals(section)) { %>
    <div id="feedbackSection" class="mb-8">
        <h2 class="text-xl font-bold text-primary mb-4">Feedback des TPs</h2>
        <p class="text-gray-500 text-sm mb-4">Vos TPs déposés : corrigés (avec note) ou en attente.</p>
        <form method="get" action="<%= ctx %>/etudiant/DepotTPServlet" class="flex flex-wrap gap-3 items-end mb-4 p-3 bg-gray-50 rounded-lg">
            <input type="hidden" name="action" value="list"/>
            <input type="hidden" name="section" value="feedback"/>
            <div>
                <label class="block text-xs font-medium text-gray-500 mb-1">Module</label>
                <select name="moduleId" class="border border-gray-300 rounded px-2 py-1.5 text-sm">
                    <option value="">Tous</option>
                    <% if (modules != null) for (model.Module m : modules) { %>
                    <option value="<%= m.getId() %>"<%= (moduleFiltreId != null && moduleFiltreId.equals(m.getId())) ? " selected" : "" %>><%= m.getNom() %></option>
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
        <% if (travaux == null || travaux.isEmpty()) { %>
        <div class="bg-white rounded-xl shadow border border-gray-100 p-12 text-center text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-14 h-14 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <p class="font-medium">Aucun TP déposé.</p>
            <p class="text-sm mt-1">Les retours des enseignants apparaîtront ici une fois vos TPs corrigés.</p>
        </div>
        <% } else { %>
        <div class="space-y-4">
            <% for (TravailPratique tp : travaux) {
                String statutColor = "bg-gray-100 text-gray-600";
                String statutLabel = "Soumis";
                switch (tp.getStatut()) {
                    case EN_CORRECTION: statutColor = "bg-yellow-100 text-yellow-700"; statutLabel = "En correction"; break;
                    case CORRIGE:       statutColor = "bg-green-100 text-green-700";   statutLabel = "Corrigé"; break;
                    case RENDU:         statutColor = "bg-blue-100 text-blue-700";     statutLabel = "Rendu"; break;
                }
                String enseignantNom = (tp.getModule() != null && tp.getModule().getEnseignant() != null) ? tp.getModule().getEnseignant().getNomComplet() : "";
                String dateDepot = tp.getDateSoumission() != null ? sdfCourt.format(tp.getDateSoumission()) : "";
                boolean canNewVersion = false;
                if (tp.getStatut() == TravailPratique.Statut.SOUMIS && tp.getModule() != null && rapports != null) {
                    java.util.Date maxLimiteMod = null;
                    for (Rapport r : rapports) {
                        if (r.getModule() != null && r.getModule().getId().equals(tp.getModule().getId()) && r.getDateLimite() != null) {
                            if (maxLimiteMod == null || r.getDateLimite().after(maxLimiteMod)) maxLimiteMod = r.getDateLimite();
                        }
                    }
                    if (maxLimiteMod == null || now.before(maxLimiteMod)) canNewVersion = true;
                }
            %>
            <div class="bg-white rounded-xl shadow border border-gray-100 overflow-hidden hover:shadow-md transition">
                <div class="p-5">
                    <div class="flex items-start gap-3">
                        <%-- Avatar document (TP) --%>
                        <div class="w-10 h-10 rounded-full bg-gray-500 flex items-center justify-center flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="font-semibold text-gray-800"><%= tp.getModule() != null ? tp.getModule().getNom() : "Module" %> – <%= tp.getTitre() != null ? tp.getTitre() : "TP" %></p>
                            <% if (enseignantNom != null && !enseignantNom.isEmpty()) { %>
                            <p class="text-sm text-gray-500 mt-0.5"><%= enseignantNom %></p>
                            <% } %>
                            <p class="text-sm text-gray-400 mt-0.5"><%= dateDepot %></p>
                            <div class="flex flex-wrap items-center gap-2 mt-2">
                                <span class="text-xs text-gray-500 font-medium">Version <%= tp.getVersion() %></span>
                                <span class="<%= statutColor %> text-xs px-2 py-1 rounded-full font-medium"><%= statutLabel %></span>
                                <% if (tp.getNote() != null) { %>
                                <span class="text-sm font-semibold text-green-600"><%= tp.getNote() %>/20</span>
                                <% } else { %>
                                <span class="text-xs text-amber-600 font-medium">Pas encore noté</span>
                                <% } %>
                            </div>
                        </div>
                        <button type="button" class="p-1 rounded-full hover:bg-gray-100 text-gray-400 hover:text-gray-600 flex-shrink-0" aria-label="Options">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                        </button>
                    </div>
                    <div class="mt-4 pt-4 border-t border-gray-100 flex justify-center gap-3 flex-wrap">
                        <a href="<%= ctx %>/etudiant/DepotTPServlet?action=detail&id=<%= tp.getId() %>"
                           class="inline-flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-blue-900 transition text-sm font-medium">
                            Voir
                        </a>
                        <% if (canNewVersion) { %>
                        <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&id=<%= tp.getId() %>"
                           class="inline-flex items-center gap-2 px-4 py-2 border border-primary text-primary rounded-lg hover:bg-primary/5 transition text-sm font-medium">
                            Nouvelle version
                        </a>
                        <% } %>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>
    <% } %>

    </main>
</div>

<script>
    let notifLoaded = false;

    function toggleNotifPanel() {
        const panel = document.getElementById('notifPanel');
        panel.classList.toggle('hidden');
        if (!panel.classList.contains('hidden') && !notifLoaded) {
            loadNotifications();
        }
    }

    function loadNotifications() {
        fetch('<%= ctx %>/NotificationServlet?action=liste-json')
            .then(r => r.json())
            .then(data => {
                notifLoaded = true;
                const list = document.getElementById('notifList');
                if (data.length === 0) {
                    list.innerHTML = '<div class="px-4 py-4 text-center text-gray-400 text-sm">Aucune notification.</div>';
                    return;
                }
                list.innerHTML = data.map(n => {
                    const content = (n.expediteur ? '<p class="text-xs text-gray-500">De: ' + n.expediteur + '</p>' : '') +
                        '<p class="text-sm text-gray-700">' + (n.message||'') + '</p>' +
                        '<p class="text-xs text-gray-400 mt-0.5">' + (n.date||'') + '</p>' +
                        (n.replyUrl ? '<p class="text-xs text-primary font-medium mt-1">Cliquez pour répondre →</p>' : '');
                    const cls = 'px-4 py-3 hover:bg-gray-50 ' + (n.lu ? '' : 'bg-blue-50');
                    var url = n.replyUrl || n.markReadUrl;
                    return url ? '<a href="' + url + '" class="block ' + cls + '">' + content + '</a>' : '<div class="' + cls + '">' + content + '</div>';
                }).join('');
                // Mettre à jour le badge
                const badge = document.getElementById('notifBadge');
                const nonLues = data.filter(n => !n.lu).length;
                if (badge) {
                    if (nonLues === 0) badge.remove();
                    else badge.textContent = nonLues > 9 ? '9+' : nonLues;
                }
            })
            .catch(() => {
                document.getElementById('notifList').innerHTML =
                    '<div class="px-4 py-4 text-center text-red-400 text-sm">Erreur de chargement.</div>';
            });
    }

    function toggleProfilePanel() {
        document.getElementById('profilePanel').classList.toggle('hidden');
    }
    document.addEventListener('click', function(e) {
        const panel = document.getElementById('notifPanel');
        const btn = document.getElementById('notifBtn');
        if (!panel.contains(e.target) && !btn.contains(e.target)) {
            panel.classList.add('hidden');
        }
        const profilePanel = document.getElementById('profilePanel');
        const profileBtn = document.querySelector('button[onclick="toggleProfilePanel()"]');
        if (profilePanel && profileBtn && !profilePanel.contains(e.target) && !profileBtn.contains(e.target)) {
            profilePanel.classList.add('hidden');
        }
    });
</script>
</body>
</html>