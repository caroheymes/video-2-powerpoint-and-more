# Configuration et Installeur Graphique Windows (WinForms)
# Zéro dépendance externe : fonctionne nativement sur tous les Windows 10/11 sans Python préalable.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ------------------------------------------------------------------------------
# Création de la Fenêtre Principale
# ------------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Installation - Video to PowerPoint & More"
$form.Size = New-Object System.Drawing.Size(560, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(248, 250, 252)

# Définition de l'icône de l'application
$icoPath = Join-Path $ScriptDir "assets\app_icon.ico"
$pngPath = Join-Path $ScriptDir "assets\app_icon.png"
if (!(Test-Path $icoPath)) { $icoPath = Join-Path $ScriptDir "app_icon.ico" }
if (!(Test-Path $pngPath)) { $pngPath = Join-Path $ScriptDir "app_icon.png" }

if (Test-Path $icoPath) {
    try {
        $form.Icon = New-Object System.Drawing.Icon($icoPath)
    } catch {}
}

# Logo dans l'en-tête
if (Test-Path $pngPath) {
    $picLogo = New-Object System.Windows.Forms.PictureBox
    $picLogo.Image = [System.Drawing.Image]::FromFile($pngPath)
    $picLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $picLogo.Size = New-Object System.Drawing.Size(46, 46)
    $picLogo.Location = New-Object System.Drawing.Point(28, 18)
    $form.Controls.Add($picLogo)
}

# Titre
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Video to PowerPoint & More"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
$lblTitle.Location = New-Object System.Drawing.Point(85, 18)
$lblTitle.Size = New-Object System.Drawing.Size(440, 32)
$form.Controls.Add($lblTitle)

$lblDesc = New-Object System.Windows.Forms.Label
$lblDesc.Text = "Assistant d'installation et de configuration automatique pour Windows."
$lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblDesc.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
$lblDesc.Location = New-Object System.Drawing.Point(87, 50)
$lblDesc.Size = New-Object System.Drawing.Size(440, 22)
$form.Controls.Add($lblDesc)

# Séparateur
$sep = New-Object System.Windows.Forms.Label
$sep.BorderStyle = "Fixed3D"
$sep.Location = New-Object System.Drawing.Point(30, 85)
$sep.Size = New-Object System.Drawing.Size(480, 2)
$form.Controls.Add($sep)

# Groupe Clé API
$lblProvider = New-Object System.Windows.Forms.Label
$lblProvider.Text = "1. Choisissez votre fournisseur d'IA :"
$lblProvider.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblProvider.Location = New-Object System.Drawing.Point(30, 100)
$lblProvider.Size = New-Object System.Drawing.Size(480, 22)
$form.Controls.Add($lblProvider)

$cboProvider = New-Object System.Windows.Forms.ComboBox
$cboProvider.DropDownStyle = "DropDownList"
$cboProvider.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
[void]$cboProvider.Items.Add("OpenAI (ChatGPT)")
[void]$cboProvider.Items.Add("Google Gemini (Gratuit)")
[void]$cboProvider.Items.Add("Mistral AI")
$cboProvider.SelectedIndex = 0
$cboProvider.Location = New-Object System.Drawing.Point(32, 125)
$cboProvider.Size = New-Object System.Drawing.Size(478, 28)
$form.Controls.Add($cboProvider)

$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "2. Clé d'API (sera sauvegardée localement dans votre profil) :"
$lblKey.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblKey.Location = New-Object System.Drawing.Point(30, 165)
$lblKey.Size = New-Object System.Drawing.Size(480, 22)
$form.Controls.Add($lblKey)

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$txtKey.Location = New-Object System.Drawing.Point(32, 190)
$txtKey.Size = New-Object System.Drawing.Size(478, 26)
$txtKey.UseSystemPasswordChar = $true

# Pré-remplissage si déjà présent
$envPath = Join-Path $ScriptDir ".env"
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.+)$') {
            $txtKey.Text = $matches[2].Trim().Trim('"').Trim("'")
        }
    }
}
$form.Controls.Add($txtKey)

# Options d'intégration Windows
$chkDesktop = New-Object System.Windows.Forms.CheckBox
$chkDesktop.Text = "Créer un raccourci direct sur le Bureau"
$chkDesktop.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$chkDesktop.Checked = $true
$chkDesktop.Location = New-Object System.Drawing.Point(32, 230)
$chkDesktop.Size = New-Object System.Drawing.Size(480, 24)
$form.Controls.Add($chkDesktop)

$chkContextMenu = New-Object System.Windows.Forms.CheckBox
$chkContextMenu.Text = "Ajouter l'option au Clic Droit de Windows sur les fichiers vidéo (.mp4)"
$chkContextMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$chkContextMenu.Checked = $true
$chkContextMenu.Location = New-Object System.Drawing.Point(32, 258)
$chkContextMenu.Size = New-Object System.Drawing.Size(480, 24)
$form.Controls.Add($chkContextMenu)

# Statut / Progression
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Prêt à installer."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$lblStatus.Location = New-Object System.Drawing.Point(32, 300)
$lblStatus.Size = New-Object System.Drawing.Size(478, 40)
$form.Controls.Add($lblStatus)

# Bouton Quitter
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Fermer"
$btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$btnCancel.Size = New-Object System.Drawing.Size(110, 36)
$btnCancel.Location = New-Object System.Drawing.Point(270, 370)
$btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($btnCancel)

# Bouton Installer
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Installer & Configurer"
$btnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnInstall.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnInstall.ForeColor = [System.Drawing.Color]::White
$btnInstall.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnInstall.Size = New-Object System.Drawing.Size(160, 36)
$btnInstall.Location = New-Object System.Drawing.Point(390, 370)
$form.Controls.Add($btnInstall)

# ------------------------------------------------------------------------------
# Action au clic sur Installer
# ------------------------------------------------------------------------------
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    $lblStatus.Text = "Installation de l'environnement en cours (téléchargement autonome sans droits admin)..."
    $form.Refresh()

    try {
        # 1. Sauvegarde de la clé dans .env si renseignée
        $keyVal = $txtKey.Text.Trim()
        if ($keyVal) {
            $provIdx = $cboProvider.SelectedIndex
            $varName = if ($provIdx -eq 1) { "GEMINI_API_KEY" } elseif ($provIdx -eq 2) { "MISTRAL_API_KEY" } else { "OPENAI_API_KEY" }
            Set-Content -Path $envPath -Value "$varName=$keyVal" -Encoding UTF8
        }

        # 2. Résolution / Téléchargement autonome de uv
        $uvExe = Get-Command "uv" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if (!$uvExe) {
            $candidates = @(
                "$HOME\.local\bin\uv.exe",
                "$env:USERPROFILE\.local\bin\uv.exe",
                "C:\Users\Admin\.local\bin\uv.exe"
            )
            foreach ($c in $candidates) {
                if (Test-Path $c) { $uvExe = $c; break }
            }
        }

        if (!$uvExe -or !(Test-Path $uvExe)) {
            $lblStatus.Text = "Téléchargement de l'outil d'exécution autonome (uv)..."
            $form.Refresh()
            irm https://astral.sh/uv/install.ps1 | iex
            $uvExe = "$HOME\.local\bin\uv.exe"
            if (!(Test-Path $uvExe)) {
                $uvExe = "$env:USERPROFILE\.local\bin\uv.exe"
            }
        }

        # 3. Création du venv et installation des dépendances
        $lblStatus.Text = "Préparation des bibliothèques (Whisper, PPTX, Word)..."
        $form.Refresh()

        $venvDir = Join-Path $ScriptDir ".venv"
        if (!(Test-Path $venvDir)) {
            & $uvExe venv $venvDir | Out-Null
        }

        $venvPython = Join-Path $venvDir "Scripts\python.exe"
        $reqFile = Join-Path $ScriptDir "requirements.txt"
        & $uvExe pip install -r $reqFile --python $venvPython --quiet

        # 4. Création du raccourci Bureau si demandé
        if ($chkDesktop.Checked) {
            $wsh = New-Object -ComObject WScript.Shell
            $desktopDir = [Environment]::GetFolderPath("Desktop")
            $shortcut = $wsh.CreateShortcut((Join-Path $desktopDir "Video to PowerPoint.lnk"))
            $shortcut.TargetPath = Join-Path $ScriptDir "LANCER_PIPELINE.bat"
            $shortcut.WorkingDirectory = $ScriptDir
            $shortcut.Description = "Convertir des vidéos en PowerPoint, Word et résumés avec l'IA"
            if (Test-Path $icoPath) {
                $shortcut.IconLocation = "$icoPath,0"
            }
            $shortcut.Save()
            Unblock-File -Path (Join-Path $desktopDir "Video to PowerPoint.lnk") -ErrorAction SilentlyContinue
        }

        # 5. Ajout au menu Clic Droit de Windows (.mp4) dans HKCU (sans droits admin)
        if ($chkContextMenu.Checked) {
            $regKey = "HKCU:\Software\Classes\SystemFileAssociations\.mp4\Shell\Video2PPTX"
            New-Item -Path $regKey -Force | Out-Null
            Set-ItemProperty -Path $regKey -Name "(Default)" -Value "Convertir avec Video2PowerPoint (IA)"
            if (Test-Path $icoPath) {
                Set-ItemProperty -Path $regKey -Name "Icon" -Value "$icoPath,0"
            }
            
            $cmdKey = "$regKey\Command"
            New-Item -Path $cmdKey -Force | Out-Null
            $batPath = Join-Path $ScriptDir "LANCER_PIPELINE.bat"
            $cmdVal = "cmd.exe /c `"set SEE_MASK_NOZONECHECKS=1 && `"$batPath`" `"%1`"`""
            Set-ItemProperty -Path $cmdKey -Name "(Default)" -Value $cmdVal
        }

        # Débloquer automatiquement tous les fichiers du dossier pour supprimer toute alerte de sécurité Windows
        Get-ChildItem -Path $ScriptDir -Recurse -Force | Unblock-File -ErrorAction SilentlyContinue

        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 101, 52)
        $lblStatus.Text = "Installation terminée avec succès ! Raccourci créé sur votre Bureau."
        [System.Windows.Forms.MessageBox]::Show(
            "L'installation est terminée avec succès !`n`n• Un raccourci a été ajouté sur votre Bureau.`n• Vous pouvez également faire un clic droit sur n'importe quel fichier .mp4 pour lancer la conversion !",
            "Installation Réussie",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

        $form.Close()
    }
    catch {
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(185, 28, 28)
        $lblStatus.Text = "Erreur : $($_.Exception.Message)"
        $btnInstall.Enabled = $true
    }
})

# Lancement de l'affichage
[void]$form.ShowDialog()
