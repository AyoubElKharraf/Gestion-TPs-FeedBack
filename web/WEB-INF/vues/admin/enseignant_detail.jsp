<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Enseignant, model.Module, java.util.List" %>
<%
    Enseignant enseignant = (Enseignant) request.getAttribute("enseignant");
    List<Module> modules  = (List<Module>)  request.getAttribute("modules");
    String ctx = request.getContextPath();
    boolean updated = "1".equals(request.getParameter("updated"));
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Détail Enseignant – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">
<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= ctx %>/admin/EnseignantServlet?action=list"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold">Fiche Enseignant</span>
</header>

<main class="flex-1 p-6 max-w-2xl mx-auto w-full">
    <% if (updated) { %>
    <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm">✅ Modifications enregistrées.</div>
    <% } %>

    <% if (enseignant == null) { %>
    <div class="bg-red-50 text-red-600 p-4 rounded-xl">Enseignant introuvable.</div>
    <% } else { %>

    <%-- Profil --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <div class="flex items-center gap-5">
            <div class="w-20 h-20 rounded-full bg-purple-100 flex items-center justify-center
                        font-bold text-purple-700 text-2xl flex-shrink-0">
                <%= String.valueOf(enseignant.getPrenom().charAt(0)).toUpperCase() %><%= String.valueOf(enseignant.getNom().charAt(0)).toUpperCase() %>
            </div>
            <div class="flex-1">
                <h2 class="text-2xl font-bold text-primary"><%= enseignant.getNomComplet() %></h2>
                <p class="text-gray-400 text-sm mt-1"><%= enseignant.getEmail() %></p>
                <% if (enseignant.getSpecialite() != null && !enseignant.getSpecialite().isEmpty()) { %>
                <span class="inline-block mt-2 bg-purple-100 text-purple-700 text-xs px-2 py-1 rounded font-medium">
                    📚 <%= enseignant.getSpecialite() %>
                </span>
                <% } %>
            </div>
            <a href="<%= ctx %>/admin/EnseignantServlet?action=form&id=<%= enseignant.getId() %>"
               class="flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg hover:bg-blue-900 transition text-sm font-medium">
                ✏️ Modifier
            </a>
        </div>
    </div>

    <%-- Modules assignés --%>
    <div class="bg-white rounded-xl shadow p-6 mb-5">
        <h3 class="font-bold text-primary mb-4 text-lg">
            Modules enseignés
            <span class="text-sm font-normal text-gray-400 ml-2">
                (<%= modules != null ? modules.size() : 0 %> module<%= (modules != null && modules.size() > 1) ? "s" : "" %>)
            </span>
        </h3>
        <% if (modules == null || modules.isEmpty()) { %>
        <p class="text-gray-400 text-sm">Aucun module assigné à cet enseignant.</p>
        <% } else { %>
        <div class="space-y-2">
            <% for (Module mod : modules) { %>
            <div class="flex items-center justify-between p-3 rounded-lg border border-gray-100 hover:border-primary transition">
                <div>
                    <p class="font-semibold text-gray-800 text-sm"><%= mod.getNom() %></p>
                    <span class="text-xs bg-blue-100 text-primary px-2 py-0.5 rounded">
                        <%= mod.getFiliere() != null ? mod.getFiliere() : "M2I" %>
                    </span>
                </div>
                <a href="<%= ctx %>/admin/ModuleServlet?action=detail&id=<%= mod.getId() %>"
                   class="text-xs text-blue-600 hover:underline">Voir →</a>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>

    <%-- Zone danger --%>
    <div class="bg-white rounded-xl shadow p-6 border border-red-100">
        <h3 class="font-bold text-red-500 mb-2">Zone de danger</h3>
        <p class="text-sm text-gray-400 mb-4">Supprimer cet enseignant le retirera de tous les modules associés.</p>
        <form method="POST" action="<%= ctx %>/admin/EnseignantServlet"
              onsubmit="return confirm('Supprimer définitivement <%= enseignant.getNomComplet() %> ?');">
            <input type="hidden" name="action" value="delete"/>
            <input type="hidden" name="id" value="<%= enseignant.getId() %>"/>
            <button type="submit"
                    class="bg-red-500 text-white px-5 py-2 rounded-lg hover:bg-red-600 transition text-sm font-medium">
                🗑️ Supprimer cet enseignant
            </button>
        </form>
    </div>
    <% } %>
</main>
</body>
</html>