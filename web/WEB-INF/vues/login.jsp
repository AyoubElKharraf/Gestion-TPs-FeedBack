<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>EtudAcadPro – Connexion</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: { primary: '#1a2744' }
                }
            }
        }
    </script>
</head>
<body class="min-h-screen bg-gray-50 flex items-center justify-center">

<div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">

    <!-- Logo et titre -->
    <div class="flex flex-col items-center mb-8">
        <div class="w-16 h-16 bg-primary rounded-full flex items-center justify-center mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8 text-white" fill="none"
                 viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 
                         01.665 6.479A11.952 11.952 0 0012 20.055a11.952 
                         11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
            </svg>
        </div>
        <h1 class="text-2xl font-bold text-primary">EtudAcadPro</h1>
        <p class="text-gray-400 text-sm mt-1">Connectez-vous à votre espace</p>
    </div>

    <!-- Message d'erreur -->
    <% if (request.getAttribute("erreur") != null) { %>
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">
        <%= request.getAttribute("erreur") %>
    </div>
    <% } %>

    <!-- Formulaire -->
    <form action="<%= request.getContextPath() %>/LoginServlet" method="POST"
          id="loginForm" novalidate>

        <!-- Email -->
        <div class="mb-5">
            <label for="email" class="block text-sm font-semibold text-gray-700 mb-1">
                Email
            </label>
            <input type="email" id="email" name="email"
                   placeholder="exemple@test.com"
                   class="w-full border border-gray-300 rounded-lg px-4 py-3 text-sm
                          focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent
                          transition"
                   value="<%= request.getAttribute("emailValue") != null ? request.getAttribute("emailValue") : "" %>"/>
            <p id="emailError" class="text-red-500 text-xs mt-1 hidden">
                Veuillez saisir un email valide.
            </p>
        </div>

        <!-- Mot de passe -->
        <div class="mb-6">
            <label for="motDePasse" class="block text-sm font-semibold text-gray-700 mb-1">
                Mot de passe
            </label>
            <div class="relative">
                <input type="password" id="motDePasse" name="motDePasse"
                       placeholder="••••••••"
                       class="w-full border border-gray-300 rounded-lg px-4 py-3 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent
                              transition pr-12"/>
                <button type="button" onclick="togglePassword()"
                        class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                    <svg id="eyeIcon" xmlns="http://www.w3.org/2000/svg" class="w-5 h-5"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 
                                 0 8.268 2.943 9.542 7-1.274 4.057-5.064 
                                 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                    </svg>
                </button>
            </div>
            <p id="mdpError" class="text-red-500 text-xs mt-1 hidden">
                Le mot de passe est obligatoire.
            </p>
        </div>

        <!-- Bouton connexion -->
        <button type="submit"
                class="w-full bg-primary text-white font-semibold py-3 rounded-lg
                       hover:bg-blue-900 transition duration-200 text-sm">
            Se connecter
        </button>
    </form>

    <!-- Mot de passe oublié -->
    <!--div class="text-center mt-4">
        <a href="#" class="text-sm text-gray-500 underline hover:text-primary">
            Mot de passe oublié ?
        </a>
    </div-->
</div>

<script>
    // Afficher / masquer le mot de passe
    function togglePassword() {
        const input = document.getElementById('motDePasse');
        input.type = input.type === 'password' ? 'text' : 'password';
    }

    // Validation côté client
    document.getElementById('loginForm').addEventListener('submit', function (e) {
        let valid = true;

        const email = document.getElementById('email');
        const mdp = document.getElementById('motDePasse');
        const emailError = document.getElementById('emailError');
        const mdpError = document.getElementById('mdpError');

        // Reset
        emailError.classList.add('hidden');
        mdpError.classList.add('hidden');
        email.classList.remove('border-red-500');
        mdp.classList.remove('border-red-500');

        // Validation email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!email.value.trim() || !emailRegex.test(email.value.trim())) {
            emailError.classList.remove('hidden');
            email.classList.add('border-red-500');
            valid = false;
        }

        // Validation mot de passe
        if (!mdp.value.trim()) {
            mdpError.classList.remove('hidden');
            mdp.classList.add('border-red-500');
            valid = false;
        }

        if (!valid) e.preventDefault();
    });
</script>
</body>
</html>