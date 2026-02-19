<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Module,model.TravailPratique,model.Rapport,java.util.List,java.util.Date,java.text.SimpleDateFormat" %>
<%
    List<Module> modules = (List<Module>) request.getAttribute("modules");
    List<Rapport> rapports = (List<Rapport>) request.getAttribute("rapports");
    TravailPratique tpParent = (TravailPratique) request.getAttribute("tpParent");
    Long preselectedModuleId = (Long) request.getAttribute("preselectedModuleId");
    String preselectedRapportTitre = (String) request.getAttribute("preselectedRapportTitre");
    Long preselectedRapportId = (Long) request.getAttribute("preselectedRapportId");
    String ctx = request.getContextPath();
    boolean isNouvelleVersion = (tpParent != null);
    Date now = new Date();
    SimpleDateFormat sdfRapport = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Déposer un TP – Étudiant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { theme: { extend: { colors: { primary: '#1a2744' } } } }</script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">

<header class="bg-primary text-white px-6 py-4 flex items-center gap-4 shadow-md">
    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list"
       class="p-2 rounded-full hover:bg-blue-900 transition">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
    </a>
    <span class="text-xl font-bold">
        <%= isNouvelleVersion ? "Nouvelle version – " + tpParent.getTitre() : "Déposer un Travail Pratique" %>
    </span>
</header>

<main class="p-6 max-w-2xl mx-auto w-full">

    <%-- Rechercher / Choisir le TP (devoir) de l'enseignant --%>
    <div class="bg-white rounded-xl shadow p-6 mb-6">
        <h2 class="text-lg font-bold text-primary mb-1">Rechercher les TPs déposés par l'enseignant</h2>
        <p class="text-sm text-gray-500 mb-4">Choisissez le devoir pour lequel vous souhaitez envoyer votre TP correspondant.</p>
        <input type="text" id="searchRapports" placeholder="Rechercher par module, enseignant ou titre du TP..."
               class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm mb-4
                      focus:outline-none focus:ring-2 focus:ring-primary"/>
        <div id="listeRapports" class="space-y-2 max-h-64 overflow-y-auto">
            <% if (rapports != null && !rapports.isEmpty()) {
                for (Rapport rapp : rapports) {
                    if (rapp.getModule() == null) continue;
                    String moduleNom = rapp.getModule().getNom();
                    String enseignantNom = rapp.getModule().getEnseignant() != null ? rapp.getModule().getEnseignant().getNomComplet() : "";
                    String titreRapport = rapp.getTitre() != null ? rapp.getTitre() : "Document";
                    boolean avantDateLimite = rapp.getDateLimite() == null || !now.after(rapp.getDateLimite());
            %>
            <div class="rapport-item border border-gray-100 rounded-lg p-3 hover:bg-gray-50 transition flex flex-wrap items-center gap-2"
                 data-module="<%= moduleNom %>" data-enseignant="<%= enseignantNom %>" data-titre="<%= titreRapport %>">
                <div class="flex-1 min-w-0">
                    <p class="font-medium text-gray-800 text-sm"><%= titreRapport %></p>
                    <p class="text-xs text-gray-500"><%= moduleNom %><%= enseignantNom != null && !enseignantNom.isEmpty() ? " · " + enseignantNom : "" %></p>
                    <% if (rapp.getDateLimite() != null) { %>
                    <p class="text-xs <%= avantDateLimite ? "text-gray-400" : "text-amber-600" %>">
                        Date limite : <%= sdfRapport.format(rapp.getDateLimite()) %><%= !avantDateLimite ? " (dépassée)" : "" %>
                    </p>
                    <% } %>
                </div>
                <div class="flex gap-2 flex-shrink-0">
                    <a href="<%= ctx %>/RapportDownloadServlet?id=<%= rapp.getId() %>" target="_blank"
                       class="px-2.5 py-1.5 text-xs border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-100 transition">
                        📄 Consulter
                    </a>
                    <% if (avantDateLimite) { %>
                    <a href="<%= ctx %>/etudiant/DepotTPServlet?action=form&moduleId=<%= rapp.getModule().getId() %>&rapportId=<%= rapp.getId() %>"
                       class="px-2.5 py-1.5 text-xs bg-primary text-white rounded-lg hover:bg-blue-900 transition">
                        Déposer mon TP
                    </a>
                    <% } else { %>
                    <span class="px-2.5 py-1.5 text-xs text-amber-600 bg-amber-50 rounded-lg">Date limite dépassée</span>
                    <% } %>
                </div>
            </div>
            <% }
            } else { %>
            <p class="text-sm text-gray-400 py-2">Aucun TP (devoir) déposé par les enseignants pour vos modules.</p>
            <% } %>
        </div>
    </div>

    <% if (request.getAttribute("erreur") != null) { %>
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">
        ⚠️ <%= request.getAttribute("erreur") %>
    </div>
    <% } %>

    <% if (isNouvelleVersion) { %>
    <div class="bg-purple-50 border border-purple-200 text-purple-700 px-4 py-3 rounded-lg mb-4 text-sm">
        📌 Vous déposez la version <strong><%= tpParent.getVersion() + 1 %></strong>
        de ce TP. La version précédente sera conservée.
    </div>
    <% } %>
    <% if (preselectedRapportTitre != null && !preselectedRapportTitre.isEmpty()) { %>
    <div class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded-lg mb-4 text-sm">
        📄 Vous envoyez votre TP correspondant au devoir de l'enseignant : <strong><%= preselectedRapportTitre %></strong>
    </div>
    <% } %>

    <div class="bg-white rounded-xl shadow p-6">
        <form action="<%= ctx %>/etudiant/DepotTPServlet" method="POST"
              enctype="multipart/form-data" id="tpForm" novalidate>
            <input type="hidden" name="action" value="save"/>
            <% if (isNouvelleVersion) { %>
            <input type="hidden" name="tpParentId" value="<%= tpParent.getId() %>"/>
            <% } %>

            <%
                boolean fromDeposerMonTP = (preselectedRapportTitre != null && !preselectedRapportTitre.isEmpty() && preselectedModuleId != null);
                String moduleDisplayName = null;
                if (fromDeposerMonTP && modules != null) {
                    for (Module m : modules) {
                        if (m.getId().equals(preselectedModuleId)) {
                            moduleDisplayName = m.getNom() + (m.getEnseignant() != null ? " (" + m.getEnseignant().getNomComplet() + ")" : "");
                            break;
                        }
                    }
                }
            %>
            <%-- Titre : affiché automatiquement si venu de "Déposer mon TP", sinon saisie --%>
            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Titre du TP <span class="text-red-500">*</span>
                </label>
                <% if (fromDeposerMonTP) { %>
                <input type="hidden" name="titre" value="<%= preselectedRapportTitre %>"/>
                <p class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-gray-50 text-gray-800"><%= preselectedRapportTitre %></p>
                <p id="titreError" class="text-red-500 text-xs mt-1 hidden">Titre obligatoire.</p>
                <% } else { %>
                <input type="text" name="titre" id="titre"
                       value="<%= isNouvelleVersion ? tpParent.getTitre() : "" %>"
                       placeholder="ex: TP1 – Algorithmes de tri"
                       class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm
                              focus:outline-none focus:ring-2 focus:ring-primary"/>
                <p id="titreError" class="text-red-500 text-xs mt-1 hidden">Titre obligatoire.</p>
                <% } %>
            </div>

            <%-- Module : affiché automatiquement si venu de "Déposer mon TP", sinon liste --%>
            <div class="mb-4">
                <label class="block text-sm font-semibold text-gray-700 mb-1">
                    Module <span class="text-red-500">*</span>
                </label>
                <% if (fromDeposerMonTP && moduleDisplayName != null) { %>
                <input type="hidden" name="moduleId" value="<%= preselectedModuleId %>"/>
                <p class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-gray-50 text-gray-800"><%= moduleDisplayName %></p>
                <p id="moduleError" class="text-red-500 text-xs mt-1 hidden">Sélectionnez un module.</p>
                <% if (rapports != null && !rapports.isEmpty()) {
                    for (Rapport rapp : rapports) {
                        if (rapp.getModule() == null || !rapp.getModule().getId().equals(preselectedModuleId)) continue;
                %>
                <p class="text-xs text-gray-500 mt-2">Consulter le rapport de l'enseignant :</p>
                <a href="<%= ctx %>/RapportDownloadServlet?id=<%= rapp.getId() %>" target="_blank"
                   class="text-sm text-primary hover:underline font-medium">📄 <%= rapp.getTitre() != null ? rapp.getTitre() : "Télécharger" %></a>
                <% } } %>
                <% } else { %>
                <select name="moduleId" id="moduleId"
                        class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm
                               focus:outline-none focus:ring-2 focus:ring-primary">
                    <option value="">-- Sélectionner un module --</option>
                    <% if (modules != null) {
                        for (Module m : modules) {
                            boolean selected = (isNouvelleVersion && tpParent.getModule() != null && tpParent.getModule().getId().equals(m.getId()))
                                || (preselectedModuleId != null && preselectedModuleId.equals(m.getId()));
                    %>
                    <option value="<%= m.getId() %>" <%= selected ? "selected" : "" %>>
                        <%= m.getNom() %>
                        <%= m.getEnseignant() != null ? "(" + m.getEnseignant().getNomComplet() + ")" : "" %>
                    </option>
                    <% } } %>
                </select>
                <p id="moduleError" class="text-red-500 text-xs mt-1 hidden">Sélectionnez un module.</p>
                <% if (rapports != null && !rapports.isEmpty()) { %>
                <div id="rapportLinkBox" class="mt-2 hidden">
                    <p class="text-xs text-gray-500 mb-1">Consulter le rapport de l'enseignant pour ce module :</p>
                    <% for (Rapport rapp : rapports) {
                        if (rapp.getModule() == null) continue;
                    %>
                    <a href="<%= ctx %>/RapportDownloadServlet?id=<%= rapp.getId() %>" target="_blank"
                       class="rapport-link text-sm text-primary hover:underline font-medium"
                       data-module-id="<%= rapp.getModule().getId() %>" style="display:none;">
                        📄 <%= rapp.getTitre() != null ? rapp.getTitre() : "Télécharger le rapport" %>
                    </a>
                    <% } %>
                </div>
                <% } %>
                <% } %>
            </div>

            <%-- Description --%>
            <div class="mb-5">
                <label class="block text-sm font-semibold text-gray-700 mb-1">Description / Remarques</label>
                <textarea name="description" rows="3"
                          placeholder="Décrivez brièvement votre travail, les difficultés rencontrées..."
                          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm
                                 focus:outline-none focus:ring-2 focus:ring-primary resize-none"></textarea>
            </div>

            <%-- Zone upload fichier --%>
            <div class="mb-6">
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                    Fichier <span class="text-red-500">*</span>
                </label>
                <div id="dropZone"
                     class="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center
                            hover:border-primary transition cursor-pointer"
                     onclick="document.getElementById('fichier').click()">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-10 h-10 mx-auto mb-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
                    </svg>
                    <p class="text-sm text-gray-500" id="dropText">
                        Cliquez ou glissez votre fichier ici
                    </p>
                    <p class="text-xs text-gray-400 mt-1">
                        PDF, DOC, DOCX, ZIP, Java, Python · Max 10 Mo
                    </p>
                    <input type="file" name="fichier" id="fichier" class="hidden"
                           accept=".pdf,.doc,.docx,.zip,.rar,.java,.py,.txt,.png,.jpg"
                           onchange="afficherFichier(this)"/>
                </div>
                <p id="fichierError" class="text-red-500 text-xs mt-1 hidden">Veuillez joindre un fichier.</p>
            </div>

            <%-- Boutons --%>
            <div class="flex gap-3">
                <button type="submit"
                        class="flex-1 bg-primary text-white py-2.5 rounded-lg hover:bg-blue-900
                               transition text-sm font-medium flex items-center justify-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
                    </svg>
                    <%= isNouvelleVersion ? "Déposer la nouvelle version" : "Déposer le TP" %>
                </button>
                <a href="<%= ctx %>/etudiant/DepotTPServlet?action=list"
                   class="flex-1 text-center border border-gray-300 text-gray-600 py-2.5 rounded-lg
                          hover:bg-gray-50 transition text-sm font-medium">
                    Annuler
                </a>
            </div>
        </form>
    </div>
</main>

<script>
    function afficherFichier(input) {
        const dropText = document.getElementById('dropText');
        const dropZone = document.getElementById('dropZone');
        if (input.files && input.files[0]) {
            const fichier = input.files[0];
            const taille = (fichier.size / 1024 / 1024).toFixed(2);
            dropText.textContent = '📎 ' + fichier.name + ' (' + taille + ' Mo)';
            dropZone.classList.add('border-primary', 'bg-blue-50');
            dropZone.classList.remove('border-gray-300');
        }
    }

    // Drag & drop
    const dropZone = document.getElementById('dropZone');
    dropZone.addEventListener('dragover', e => { e.preventDefault(); dropZone.classList.add('border-primary'); });
    dropZone.addEventListener('dragleave', () => dropZone.classList.remove('border-primary'));
    dropZone.addEventListener('drop', e => {
        e.preventDefault();
        const fichierInput = document.getElementById('fichier');
        fichierInput.files = e.dataTransfer.files;
        afficherFichier(fichierInput);
    });

    // Validation front-end (titre et module peuvent être en hidden si venus de "Déposer mon TP")
    document.getElementById('tpForm').addEventListener('submit', function(e) {
        var valid = true;
        var titreEl = document.querySelector('input[name="titre"]');
        var moduleEl = document.querySelector('select[name="moduleId"], input[name="moduleId"]');
        var fichier = document.getElementById('fichier');

        if (titreEl && titreEl.type === 'text') {
            var err = document.getElementById('titreError');
            err.classList.add('hidden'); titreEl.classList.remove('border-red-500');
            if (!titreEl.value.trim()) { err.classList.remove('hidden'); titreEl.classList.add('border-red-500'); valid = false; }
        }
        if (moduleEl && moduleEl.tagName === 'SELECT') {
            var err = document.getElementById('moduleError');
            err.classList.add('hidden'); moduleEl.classList.remove('border-red-500');
            if (!moduleEl.value) { err.classList.remove('hidden'); moduleEl.classList.add('border-red-500'); valid = false; }
        }

        var fichierErr = document.getElementById('fichierError');
        fichierErr.classList.add('hidden');
        if (!fichier.files || fichier.files.length === 0) {
            fichierErr.classList.remove('hidden'); valid = false;
        }
        if (!valid) e.preventDefault();
    });

    // Afficher le lien "Télécharger le rapport" pour le module sélectionné
    const rapportLinkBox = document.getElementById('rapportLinkBox');
    const moduleSelect = document.getElementById('moduleId');
    if (rapportLinkBox && moduleSelect) {
        function updateRapportLink() {
            const links = document.querySelectorAll('.rapport-link');
            links.forEach(l => { l.style.display = 'none'; });
            const val = moduleSelect.value;
            if (!val) { rapportLinkBox.classList.add('hidden'); return; }
            const matching = document.querySelectorAll('.rapport-link[data-module-id="' + val + '"]');
            matching.forEach(l => { l.style.display = 'inline-block'; });
            if (matching.length) {
                rapportLinkBox.classList.remove('hidden');
                rapportLinkBox.querySelector('p').textContent = matching.length > 1
                    ? 'Consulter les rapports de l\'enseignant pour ce module :'
                    : 'Consulter le rapport de l\'enseignant pour ce module :';
            } else rapportLinkBox.classList.add('hidden');
        }
        moduleSelect.addEventListener('change', updateRapportLink);
        updateRapportLink();
    }

    // Recherche dans la liste des TPs de l'enseignant
    const searchRapports = document.getElementById('searchRapports');
    const listeRapports = document.getElementById('listeRapports');
    if (searchRapports && listeRapports) {
        searchRapports.addEventListener('input', function() {
            const q = this.value.trim().toLowerCase();
            const items = listeRapports.querySelectorAll('.rapport-item');
            items.forEach(function(item) {
                const module = (item.getAttribute('data-module') || '').toLowerCase();
                const enseignant = (item.getAttribute('data-enseignant') || '').toLowerCase();
                const titre = (item.getAttribute('data-titre') || '').toLowerCase();
                const match = !q || module.indexOf(q) >= 0 || enseignant.indexOf(q) >= 0 || titre.indexOf(q) >= 0;
                item.style.display = match ? '' : 'none';
            });
        });
    }

</script>
</body>
</html>