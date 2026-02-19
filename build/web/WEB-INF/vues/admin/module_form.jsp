<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Module, model.Enseignant, java.util.List" %>
<%
    Module module = (Module) request.getAttribute("module");
    List<Enseignant> enseignants = (List<Enseignant>) request.getAttribute("enseignants");
    String ctx = request.getContextPath();
    boolean isEdit = (module != null);
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title><%= isEdit ? "Modifier" : "Ajouter" %> Module – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen">

<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= ctx %>/admin/ModuleServlet?action=list"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
             viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold">
        <%= isEdit ? "Modifier le module" : "Ajouter un module" %>
    </span>
</header>

<main class="p-6 max-w-lg mx-auto">
    <!-- Message d'erreur serveur -->
    <% if (request.getAttribute("erreur") != null) { %>
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">
        <%= request.getAttribute("erreur") %>
    </div>
    <% } %>

    <div class="bg-white rounded-xl shadow p-6">
        <form action="<%= ctx %>/admin/ModuleServlet" method="POST" id="moduleForm" novalidate>
            <input type="hidden" name="action" value="save"/>
            <% if (isEdit) { %>
            <input type="hidden" name="id" value="<%= module.getId() %>"/>
            <% } %>

            <!-- Nom du module -->
            <div class="mb-5">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Nom du module <span class="text-red-500">*</span>
                </label>
                <input type="text" name="nom" id="nom"
                       value="<%= isEdit ? module.getNom() : "" %>"
                       placeholder="ex: Algorithmique Avancée"
                       class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary"/>
                <p id="nomError" class="text-red-500 text-xs mt-1 hidden">Ce champ est obligatoire.</p>
            </div>

            <!-- Description -->
            <div class="mb-5">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Description</label>
                <textarea name="description" rows="3"
                          placeholder="Description du module..."
                          class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm
                                 focus:outline-none focus:ring-2 focus:ring-primary"><%= isEdit && module.getDescription() != null ? module.getDescription() : "" %></textarea>
            </div>

            <!-- Filière -->
            <div class="mb-5">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Filière</label>
                <input type="text" name="filiere"
                       value="<%= isEdit && module.getFiliere() != null ? module.getFiliere() : "M2I" %>"
                       class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary"/>
            </div>

            <!-- Enseignant -->
            <div class="mb-6">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Enseignant correspondant
                </label>
                <select name="enseignantId"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm
                               focus:outline-none focus:ring-2 focus:ring-primary">
                    <option value="">-- Sélectionner un enseignant --</option>
                    <% if (enseignants != null) {
                        for (Enseignant ens : enseignants) { %>
                    <option value="<%= ens.getId() %>"
                            <%= (isEdit && module.getEnseignant() != null
                                    && module.getEnseignant().getId().equals(ens.getId()))
                                ? "selected" : "" %>>
                        <%= ens.getNomComplet() %>
                    </option>
                    <% } } %>
                </select>
            </div>

            <!-- Boutons -->
            <div class="flex gap-3">
                <button type="submit"
                        class="flex-1 bg-primary text-white py-2 rounded-lg hover:bg-blue-900
                               transition text-sm font-medium">
                    <%= isEdit ? "Enregistrer les modifications" : "Ajouter le module" %>
                </button>
                <a href="<%= ctx %>/admin/ModuleServlet?action=list"
                   class="flex-1 text-center border border-gray-300 text-gray-600 py-2 rounded-lg
                          hover:bg-gray-50 transition text-sm font-medium">
                    Annuler
                </a>
            </div>
        </form>
    </div>
</main>

<script>
    // Validation front-end
    document.getElementById('moduleForm').addEventListener('submit', function (e) {
        const nom = document.getElementById('nom');
        const nomError = document.getElementById('nomError');
        nomError.classList.add('hidden');
        nom.classList.remove('border-red-500');

        if (!nom.value.trim()) {
            nomError.classList.remove('hidden');
            nom.classList.add('border-red-500');
            e.preventDefault();
        }
    });
</script>
</body>
</html>