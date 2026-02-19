<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur" %>
<%
    Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Étudiant – EtudAcadPro</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">
<header class="bg-primary text-white px-6 py-4 flex items-center justify-between shadow-md">
    <div class="flex items-center gap-3">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none"
             viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 
                     01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 
                     00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
        </svg>
        <span class="text-xl font-bold">Espace Étudiant</span>
    </div>
    <a href="<%= ctx %>/LogoutServlet"
       class="text-sm text-white border border-white px-3 py-1 rounded-lg hover:bg-white hover:text-primary transition">
        Déconnexion
    </a>
</header>
<main class="flex-1 flex items-center justify-center p-6">
    <div class="bg-white rounded-xl shadow p-10 text-center max-w-md">
        <div class="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <span class="text-3xl font-bold text-green-600">
                <%= u != null ? u.getPrenom().charAt(0) + "" + u.getNom().charAt(0) : "ET" %>
            </span>
        </div>
        <h2 class="text-xl font-bold text-primary mb-2">
            Bienvenue, <%= u != null ? u.getNomComplet() : "Étudiant" %>
        </h2>
        <p class="text-gray-400 text-sm mb-6">Espace étudiant – fonctionnalités à venir</p>
        <div class="grid grid-cols-2 gap-3">
            <div class="border rounded-lg p-4 text-left hover:border-green-500 transition cursor-pointer">
                <p class="font-semibold text-primary text-sm">Mes TPs</p>
                <p class="text-xs text-gray-400 mt-1">Déposer un travail</p>
            </div>
            <div class="border rounded-lg p-4 text-left hover:border-green-500 transition cursor-pointer">
                <p class="font-semibold text-primary text-sm">Mes Notes</p>
                <p class="text-xs text-gray-400 mt-1">À implémenter</p>
            </div>
        </div>
    </div>
</main>
</body>
</html>