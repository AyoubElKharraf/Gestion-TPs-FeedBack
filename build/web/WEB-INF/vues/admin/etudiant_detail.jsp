<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Etudiant, model.Utilisateur, java.util.List, util.AbsenceIntegrationService" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    Etudiant etudiant = (Etudiant) request.getAttribute("etudiant");
    @SuppressWarnings("unchecked")
    List<AbsenceIntegrationService.AbsenceParEnseignant> absencesParEnseignant = (List<AbsenceIntegrationService.AbsenceParEnseignant>) request.getAttribute("absencesParEnseignant");
    if (absencesParEnseignant == null) absencesParEnseignant = java.util.Collections.emptyList();
    String ctx = request.getContextPath();
    boolean updated = "1".equals(request.getParameter("updated"));
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Détail Étudiant – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= ctx %>/admin/EtudiantServlet?action=list"
       class="p-2 rounded-full hover:bg-blue-900 transition" title="Retour">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold">Fiche Étudiant</span>
</header>

<main class="flex-1 p-6 max-w-2xl mx-auto w-full">
    <% if (updated) { %>
    <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">
        ✅ Modifications enregistrées.
    </div>
    <% } %>

    <% if (etudiant == null) { %>
    <div class="bg-red-50 text-red-600 p-4 rounded-xl">Étudiant introuvable.</div>
    <% } else { %>

    <%-- Carte profil --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <div class="flex items-center gap-5">
            <div class="w-20 h-20 rounded-full bg-green-100 flex items-center justify-center
                        font-bold text-green-700 text-2xl flex-shrink-0">
                <%= (etudiant.getPrenom() != null && !etudiant.getPrenom().isEmpty()) ? String.valueOf(etudiant.getPrenom().charAt(0)).toUpperCase() : "?" %><%= (etudiant.getNom() != null && !etudiant.getNom().isEmpty()) ? String.valueOf(etudiant.getNom().charAt(0)).toUpperCase() : "?" %>
            </div>
            <div class="flex-1">
                <h2 class="text-2xl font-bold text-primary"><%= etudiant.getNomComplet() %></h2>
                <p class="text-gray-400 text-sm mt-1"><%= etudiant.getEmail() %></p>
                <div class="flex items-center gap-2 mt-2">
                    <span class="bg-blue-100 text-primary text-xs px-2 py-1 rounded font-medium">
                        <%= etudiant.getFiliere() != null ? etudiant.getFiliere() : "M2I" %>
                    </span>
                    <span class="bg-gray-100 text-gray-500 text-xs px-2 py-1 rounded font-mono">
                        N° <%= etudiant.getNumeroEtudiant() != null ? etudiant.getNumeroEtudiant() : "–" %>
                    </span>
                </div>
            </div>
            <a href="<%= ctx %>/admin/EtudiantServlet?action=form&id=<%= etudiant.getId() %>"
               class="flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg
                      hover:bg-blue-900 transition text-sm font-medium">
                ✏️ Modifier
            </a>
        </div>
    </div>

    <%-- Informations détaillées --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <h3 class="font-bold text-primary mb-4 text-lg">Informations</h3>
        <div class="grid grid-cols-2 gap-4">
            <div>
                <p class="text-xs text-gray-400 uppercase font-semibold">Nom</p>
                <p class="text-gray-800 mt-1 font-medium"><%= etudiant.getNom() %></p>
            </div>
            <div>
                <p class="text-xs text-gray-400 uppercase font-semibold">Prénom</p>
                <p class="text-gray-800 mt-1 font-medium"><%= etudiant.getPrenom() %></p>
            </div>
            <div>
                <p class="text-xs text-gray-400 uppercase font-semibold">Email</p>
                <p class="text-gray-800 mt-1"><%= etudiant.getEmail() %></p>
            </div>
            <div>
                <p class="text-xs text-gray-400 uppercase font-semibold">N° Étudiant</p>
                <p class="text-gray-800 mt-1 font-mono">
                    <%= etudiant.getNumeroEtudiant() != null ? etudiant.getNumeroEtudiant() : "–" %>
                </p>
            </div>
            <div>
                <p class="text-xs text-gray-400 uppercase font-semibold">Filière</p>
                <p class="text-gray-800 mt-1"><%= etudiant.getFiliere() != null ? etudiant.getFiliere() : "–" %></p>
            </div>
            <div>
                <p class="text-xs text-gray-400 uppercase font-semibold">Rôle</p>
                <p class="text-gray-800 mt-1">Étudiant</p>
            </div>
        </div>

        <%-- Absences par enseignant (données Gestion_AbsencesAlerts) --%>
        <% if (absencesParEnseignant != null && !absencesParEnseignant.isEmpty()) { %>
        <div class="mt-6 pt-4 border-t border-gray-100">
            <p class="text-xs text-gray-400 uppercase font-semibold mb-3">Absences par enseignant</p>
            <p class="text-sm text-gray-500 mb-3">Nombre d'absences enregistrées par chaque enseignant (source : Gestion Absences).</p>
            <ul class="space-y-2">
                <% for (AbsenceIntegrationService.AbsenceParEnseignant a : absencesParEnseignant) { %>
                <li class="flex items-center justify-between py-2 px-3 rounded-lg bg-gray-50 border border-gray-100">
                    <span class="text-gray-800 font-medium"><%= a.getEnseignantNom() %></span>
                    <span class="inline-flex items-center justify-center min-w-[3rem] px-2 py-1 rounded text-sm font-semibold <%= a.getNbAbsences() >= 3 ? "bg-red-100 text-red-700" : "bg-amber-50 text-amber-700" %>">
                        <%= a.getNbAbsences() %> absence<%= a.getNbAbsences() > 1 ? "s" : "" %>
                    </span>
                </li>
                <% } %>
            </ul>
        </div>
        <% } else if (etudiant.getNbAbsences() > 0) { %>
        <div class="mt-6 pt-4 border-t border-gray-100">
            <p class="text-xs text-gray-400 uppercase font-semibold mb-2">Absences par enseignant</p>
            <p class="text-sm text-gray-500">Détail par enseignant non disponible (vérifier que Gestion Absences est configuré et démarré). Total : <strong><%= etudiant.getNbAbsences() %> absence(s)</strong>.</p>
        </div>
        <% } %>
    </div>

    <%-- Zone danger --%>
    <div class="bg-white rounded-xl shadow p-6 border border-red-100">
        <h3 class="font-bold text-red-500 mb-2">Zone de danger</h3>
        <p class="text-sm text-gray-400 mb-4">
            La suppression est irréversible. Toutes les données liées à cet étudiant seront perdues.
        </p>
        <form method="POST" action="<%= ctx %>/admin/EtudiantServlet"
              onsubmit="return confirm('Supprimer définitivement <%= etudiant.getNomComplet() %> ?');">
            <input type="hidden" name="action" value="delete"/>
            <input type="hidden" name="id" value="<%= etudiant.getId() %>"/>
            <button type="submit"
                    class="bg-red-500 text-white px-5 py-2 rounded-lg hover:bg-red-600 transition text-sm font-medium">
                🗑️ Supprimer cet étudiant
            </button>
        </form>
    </div>
    <% } %>
</main>
</body>
</html>