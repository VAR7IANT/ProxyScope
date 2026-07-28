function Start-CliMode {
    Write-Host ""
    Write-Host "$($script:AppName) $($script:Version)"
    Write-Host "Read-only Windows network diagnostics"
    Write-Host ""

    $result = Invoke-Diagnosis -ProgressCallback {
        param($percent, $message)
        Write-Progress -Activity $script:AppName -Status $message -PercentComplete $percent
    }

    Write-Progress -Activity $script:AppName -Completed
    Write-Host ""
    Write-Host "Report created:"
    Write-Host $result.HtmlPath
    Write-Host ""

    Start-Process $result.HtmlPath
}

function Start-GuiMode {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$($script:AppName) $($script:Version)"
    $form.StartPosition = "CenterScreen"
    $form.Size = New-Object System.Drawing.Size(820, 600)
    $form.MinimumSize = New-Object System.Drawing.Size(820, 600)
    $form.BackColor = [System.Drawing.Color]::FromArgb(244, 246, 248)
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.MaximizeBox = $false

    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = "Top"
    $header.Height = 126
    $header.BackColor = [System.Drawing.Color]::FromArgb(17, 24, 39)
    $form.Controls.Add($header)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "ProxyScope"
    $title.ForeColor = [System.Drawing.Color]::White
    $title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 22)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(28, 22)
    $header.Controls.Add($title)

    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = "Read-only checks for Windows proxy, DNS, routes, ports, and connectivity"
    $subtitle.ForeColor = [System.Drawing.Color]::FromArgb(209, 213, 219)
    $subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitle.AutoSize = $true
    $subtitle.Location = New-Object System.Drawing.Point(31, 70)
    $header.Controls.Add($subtitle)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "v$($script:Version)"
    $versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(209, 213, 219)
    $versionLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $versionLabel.AutoSize = $true
    $versionLabel.Location = New-Object System.Drawing.Point(727, 31)
    $header.Controls.Add($versionLabel)

    $content = New-Object System.Windows.Forms.Panel
    $content.Dock = "Fill"
    $content.Padding = New-Object System.Windows.Forms.Padding(28)
    $content.BackColor = [System.Drawing.Color]::FromArgb(244, 246, 248)
    $form.Controls.Add($content)

    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point(28, 26)
    $card.Size = New-Object System.Drawing.Size(748, 315)
    $card.BackColor = [System.Drawing.Color]::White
    $card.BorderStyle = "FixedSingle"
    $content.Controls.Add($card)

    $statusTitle = New-Object System.Windows.Forms.Label
    $statusTitle.Text = "Ready to scan"
    $statusTitle.ForeColor = [System.Drawing.Color]::FromArgb(17, 24, 39)
    $statusTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
    $statusTitle.AutoSize = $true
    $statusTitle.Location = New-Object System.Drawing.Point(24, 22)
    $card.Controls.Add($statusTitle)

    $statusText = New-Object System.Windows.Forms.Label
    $statusText.Text = "The scan does not change proxy, DNS, route, adapter, or firewall settings."
    $statusText.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $statusText.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $statusText.AutoSize = $true
    $statusText.Location = New-Object System.Drawing.Point(27, 58)
    $card.Controls.Add($statusText)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(28, 96)
    $progress.Size = New-Object System.Drawing.Size(690, 18)
    $progress.Minimum = 0
    $progress.Maximum = 100
    $progress.Value = 0
    $progress.Style = "Continuous"
    $card.Controls.Add($progress)

    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Location = New-Object System.Drawing.Point(28, 132)
    $logBox.Size = New-Object System.Drawing.Size(690, 150)
    $logBox.Multiline = $true
    $logBox.ReadOnly = $true
    $logBox.ScrollBars = "Vertical"
    $logBox.BackColor = [System.Drawing.Color]::FromArgb(249, 250, 251)
    $logBox.ForeColor = [System.Drawing.Color]::FromArgb(55, 65, 81)
    $logBox.BorderStyle = "FixedSingle"
    $logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $logBox.Text = "Ready.`r`n"
    $card.Controls.Add($logBox)

    $runButton = New-Object System.Windows.Forms.Button
    $runButton.Text = "Run diagnosis"
    $runButton.Location = New-Object System.Drawing.Point(28, 365)
    $runButton.Size = New-Object System.Drawing.Size(175, 44)
    $runButton.BackColor = [System.Drawing.Color]::FromArgb(17, 24, 39)
    $runButton.ForeColor = [System.Drawing.Color]::White
    $runButton.FlatStyle = "Flat"
    $runButton.FlatAppearance.BorderSize = 0
    $runButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $content.Controls.Add($runButton)

    $openReportButton = New-Object System.Windows.Forms.Button
    $openReportButton.Text = "Open latest report"
    $openReportButton.Location = New-Object System.Drawing.Point(215, 365)
    $openReportButton.Size = New-Object System.Drawing.Size(175, 44)
    $openReportButton.BackColor = [System.Drawing.Color]::White
    $openReportButton.ForeColor = [System.Drawing.Color]::FromArgb(17, 24, 39)
    $openReportButton.FlatStyle = "Flat"
    $openReportButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(209, 213, 219)
    $openReportButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $openReportButton.Enabled = $false
    $content.Controls.Add($openReportButton)

    $openFolderButton = New-Object System.Windows.Forms.Button
    $openFolderButton.Text = "Open report folder"
    $openFolderButton.Location = New-Object System.Drawing.Point(402, 365)
    $openFolderButton.Size = New-Object System.Drawing.Size(175, 44)
    $openFolderButton.BackColor = [System.Drawing.Color]::White
    $openFolderButton.ForeColor = [System.Drawing.Color]::FromArgb(17, 24, 39)
    $openFolderButton.FlatStyle = "Flat"
    $openFolderButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(209, 213, 219)
    $openFolderButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $content.Controls.Add($openFolderButton)

    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "Exit"
    $exitButton.Location = New-Object System.Drawing.Point(589, 365)
    $exitButton.Size = New-Object System.Drawing.Size(175, 44)
    $exitButton.BackColor = [System.Drawing.Color]::White
    $exitButton.ForeColor = [System.Drawing.Color]::FromArgb(17, 24, 39)
    $exitButton.FlatStyle = "Flat"
    $exitButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(209, 213, 219)
    $exitButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $content.Controls.Add($exitButton)

    $privacy = New-Object System.Windows.Forms.Label
    $privacy.Text = "Reports are saved locally to Desktop\ProxyScopeReports"
    $privacy.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $privacy.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $privacy.AutoSize = $true
    $privacy.Location = New-Object System.Drawing.Point(29, 432)
    $content.Controls.Add($privacy)

    $runButton.Add_Click({
        $runButton.Enabled = $false
        $openReportButton.Enabled = $false
        $statusTitle.Text = "Scanning"
        $statusText.Text = "Collecting network and proxy information"
        $progress.Value = 0
        $logBox.Clear()

        try {
            $result = Invoke-Diagnosis -ProgressCallback {
                param($percent, $message)

                $progress.Value = [Math]::Min([Math]::Max($percent, 0), 100)
                $statusText.Text = $message
                $logBox.AppendText("[$percent%] $message`r`n")
                $logBox.SelectionStart = $logBox.TextLength
                $logBox.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }

            $script:LatestReport = $result.HtmlPath
            $statusTitle.Text = "Diagnosis complete"
            $statusText.Text = "The HTML and JSON reports were created successfully"
            $openReportButton.Enabled = $true
            $logBox.AppendText("`r`nReport: $($result.HtmlPath)`r`n")

            Start-Process $result.HtmlPath
        }
        catch {
            $statusTitle.Text = "Diagnosis failed"
            $statusText.Text = $_.Exception.Message
            $logBox.AppendText("`r`nERROR: $($_.Exception.Message)`r`n")
        }
        finally {
            $runButton.Enabled = $true
        }
    })

    $openReportButton.Add_Click({
        if ($script:LatestReport -and (Test-Path $script:LatestReport)) {
            Start-Process $script:LatestReport
        }
    })

    $openFolderButton.Add_Click({
        $folder = Join-Path (Get-DesktopPath) "ProxyScopeReports"

        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }

        Start-Process explorer.exe -ArgumentList "`"$folder`""
    })

    $exitButton.Add_Click({
        $form.Close()
    })

    [void]$form.ShowDialog()
}
