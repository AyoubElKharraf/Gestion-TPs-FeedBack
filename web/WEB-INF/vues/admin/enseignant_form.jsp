<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Enseignant" %>
<%
    Enseignant enseignant = (Enseignant) request.getAttribute("enseignant");
    String ctx = request.getContextPath();
    boolean isEdit = (enseignant != null);
    String fNom       = isEdit ? enseignant.getNom()       : "";
    String fPrenom    = isEdit ? enseignant.getPrenom()    : "";
    String fEmail     = isEdit ? enseignant.getEmail()     : "";
    String fSpecialite = (isEdit && enseignant.getSpecialite() != null) ? enseignant.getSpecialite() : "";
    // Re-remplir après erreur serveur
    if (request.getAttribute("formNom") != null) fNom = (String) request.getAttribute("formNom");
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title><%= isEdit ? "Modifier" : "Ajouter" %> Enseignant – Admin</title>
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
    <span class="text-xl font-bold"><%= isEdit ? "Modifier l'enseignant" : "Ajouter un enseignant" %></span>
</header>

<main class="p-6 max-w-lg mx-auto w-full">
    <% if (request.getAttribute("erreur") != null) { %>
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">
        ⚠️ <%= request.getAttribute("erreur") %>
    </div>
    <% } %>

    <div class="bg-white rounded-xl shadow p-6">
        <form action="<%= ctx %>/admin/EnseignantServlet" method="POST" id="enseignantForm" novalidate>
            <input type="hidden" name="action" value="save"/>
            <% if (isEdit) { %><input type="hidden" name="id" value="<%= enseignant.getId() %>"/><% } %>

            <div class="grid grid-cols-2 gap-4 mb-4">
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1">Prénom <span class="text-red-500">*</span></label>
                    <input type="text" name="prenom" id="prenom" value="<%= fPrenom %>"
                           placeholder="ex: Jean"
                           class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"/>
                    <p id="prenomError" class="text-red-500 text-xs mt-1 hidden">Obligatoire.</p>
                </div>
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1">Nom <span class="text-red-500">*</span></label>
                    <input type="text" name="nom" id="nom" value="<%= fNom %>"
                           placeholder="ex: Dupont"
                           class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"/>
                    <p id="nomError" class="text-red-500 text-xs mt-1 hidden">Obligatoire.</p>
                </div>
            </div>

            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Email <span class="text-red-500">*</span></label>
                <input type="email" name="email" id="email" value="<%= fEmail %>"
                       placeholder="enseignant@test.com"
                       class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"/>
                <p id="emailError" class="text-red-500 text-xs mt-1 hidden">Email invalide.</p>
            </div>

            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Mot de passe <%= !isEdit ? "<span class='text-red-500'>*</span>" : "(laisser vide = inchangé)" %>
                </label>
                <div class="relative">
                    <input type="password" name="motDePasse" id="motDePasse"
                           placeholder="<%= isEdit ? "Laisser vide pour ne pas changer" : "Minimum 4 caractères" %>"
                           class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm pr-10 focus:outline-none focus:ring-2 focus:ring-primary"/>
                    <button type="button" onclick="togglePwd()"
                            class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                        </svg>
                    </button>
                </div>
                <p id="mdpError" class="text-red-500 text-xs mt-1 hidden">Mot de passe obligatoire.</p>
            </div>

            <div class="mb-6">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Spécialité</label>
                <input type="text" name="specialite" value="<%= fSpecialite %>"
                       placeholder="ex: Algorithmique, Réseaux, IA..."
                       class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"/>
            </div>

            <div class="flex gap-3">
                <button type="submit"
                        class="flex-1 bg-primary text-white py-2 rounded-lg hover:bg-blue-900 transition text-sm font-medium">
                    <%= isEdit ? "Enregistrer les modifications" : "Ajouter l'enseignant" %>
                </button>
                <a href="<%= ctx %>/admin/EnseignantServlet?action=list"
                   class="flex-1 text-center border border-gray-300 text-gray-600 py-2 rounded-lg hover:bg-gray-50 transition text-sm font-medium">
                    Annuler
                </a>
            </div>
        </form>
    </div>
</main>

<script>
    function togglePwd() {
        const i = document.getElementById('motDePasse');
        i.type = i.type === 'password' ? 'text' : 'password';
    }
    document.getElementById('enseignantForm').addEventListener('submit', function (e) {
        let valid = true;
        [['prenom','prenomError'], ['nom','nomError']].forEach(([id, errId]) => {
            const el = document.getElementById(id);
            const err = document.getElementById(errId);
            err.classList.add('hidden'); el.classList.remove('border-red-500');
            if (!el.value.trim()) { err.classList.remove('hidden'); el.classList.add('border-red-500'); valid = false; }
        });
        const emailEl = document.getElementById('email');
        const emailErr = document.getElementById('emailError');
        emailErr.classList.add('hidden'); emailEl.classList.remove('border-red-500');
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailEl.value.trim())) {
            emailErr.classList.remove('hidden'); emailEl.classList.add('border-red-500'); valid = false;
        }
        <% if (!isEdit) { %>
        const mdp = document.getElementById('motDePasse');
        const mdpErr = document.getElementById('mdpError');
        mdpErr.classList.add('hidden'); mdp.classList.remove('border-red-500');
        if (!mdp.value.trim()) { mdpErr.classList.remove('hidden'); mdp.classList.add('border-red-500'); valid = false; }
        <% } %>
        if (!valid) e.preventDefault();
    });
</script>
</body>
</html>