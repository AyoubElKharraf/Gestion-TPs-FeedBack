<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Module, model.Enseignant, model.Utilisateur, java.util.List" %>
<%
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    Module module = (Module) request.getAttribute("module");
    List<Enseignant> enseignants = (List<Enseignant>) request.getAttribute("enseignants");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Détail Module – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= ctx %>/admin/ModuleServlet?action=list"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
             viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold">Détail du Module</span>
</header>

<main class="flex-1 p-6 max-w-2xl mx-auto w-full">
    <% if (module == null) { %>
    <div class="bg-red-50 text-red-600 p-4 rounded-xl">Module introuvable.</div>
    <% } else { %>

    <!-- Carte info module -->
    <div class="bg-white rounded-xl shadow p-6 mb-6">
        <div class="flex items-center justify-between mb-4">
            <span class="text-xs bg-blue-100 text-primary px-2 py-1 rounded font-medium">
                <%= module.getFiliere() != null ? module.getFiliere() : "M2I" %>
            </span>
            <a href="<%= ctx %>/admin/ModuleServlet?action=form&id=<%= module.getId() %>"
               class="text-sm text-primary hover:underline font-medium">
                ✏️ Modifier
            </a>
        </div>
        <h2 class="text-2xl font-bold text-primary"><%= module.getNom() %></h2>
        <% if (module.getDescription() != null && !module.getDescription().isEmpty()) { %>
        <p class="text-gray-500 mt-2"><%= module.getDescription() %></p>
        <% } %>
    </div>

    <!-- Enseignant assigné -->
    <div class="bg-white rounded-xl shadow p-6 mb-6">
        <h3 class="font-bold text-primary mb-4">Enseignant responsable</h3>
        <% if (module.getEnseignant() != null) { %>
        <div class="flex items-center gap-4">
            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center
                        font-bold text-primary text-lg">
                <%= module.getEnseignant().getPrenom().charAt(0) %>
            </div>
            <div>
                <p class="font-semibold text-gray-800"><%= module.getEnseignant().getNomComplet() %></p>
                <p class="text-sm text-gray-400"><%= module.getEnseignant().getEmail() %></p>
                <% if (module.getEnseignant().getSpecialite() != null) { %>
                <p class="text-sm text-gray-400"><%= module.getEnseignant().getSpecialite() %></p>
                <% } %>
            </div>
        </div>
        <% } else { %>
        <p class="text-gray-400 text-sm">Aucun enseignant assigné.</p>
        <% } %>
    </div>

    <!-- Changer l'enseignant -->
    <div class="bg-white rounded-xl shadow p-6">
        <h3 class="font-bold text-primary mb-4">Modifier l'enseignant / le nom</h3>
        <form action="<%= ctx %>/admin/ModuleServlet" method="POST">
            <input type="hidden" name="action" value="save"/>
            <input type="hidden" name="id" value="<%= module.getId() %>"/>

            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Nom du module</label>
                <input type="text" name="nom" value="<%= module.getNom() %>" required
                       class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary"/>
            </div>

            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Enseignant</label>
                <select name="enseignantId"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm
                               focus:outline-none focus:ring-2 focus:ring-primary">
                    <option value="">-- Non assigné --</option>
                    <% if (enseignants != null) {
                        for (Enseignant ens : enseignants) { %>
                    <option value="<%= ens.getId() %>"
                            <%= (module.getEnseignant() != null && module.getEnseignant().getId().equals(ens.getId()))
                                ? "selected" : "" %>>
                        <%= ens.getNomComplet() %>
                    </option>
                    <% } } %>
                </select>
            </div>

            <input type="hidden" name="filiere" value="<%= module.getFiliere() != null ? module.getFiliere() : "M2I" %>"/>

            <button type="submit"
                    class="bg-primary text-white px-6 py-2 rounded-lg hover:bg-blue-900 transition text-sm font-medium">
                Enregistrer les modifications
            </button>
        </form>
    </div>

    <% } %>
</main>
</body>
</html>