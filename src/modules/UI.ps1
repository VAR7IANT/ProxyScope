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

    $colorWindow = [System.Drawing.Color]::FromArgb(246, 247, 249)
    $colorSurface = [System.Drawing.Color]::White
    $colorHeader = [System.Drawing.Color]::FromArgb(9, 17, 35)
    $colorHeaderSoft = [System.Drawing.Color]::FromArgb(30, 41, 59)
    $colorInk = [System.Drawing.Color]::FromArgb(15, 23, 42)
    $colorMuted = [System.Drawing.Color]::FromArgb(100, 116, 139)
    $colorBorder = [System.Drawing.Color]::FromArgb(226, 232, 240)
    $colorBlue = [System.Drawing.Color]::FromArgb(37, 99, 235)
    $colorBlueHover = [System.Drawing.Color]::FromArgb(29, 78, 216)
    $colorBlueSoft = [System.Drawing.Color]::FromArgb(239, 246, 255)
    $colorGreen = [System.Drawing.Color]::FromArgb(5, 150, 105)
    $colorGreenSoft = [System.Drawing.Color]::FromArgb(236, 253, 245)
    $colorAmber = [System.Drawing.Color]::FromArgb(217, 119, 6)
    $colorAmberSoft = [System.Drawing.Color]::FromArgb(255, 247, 237)
    $colorRed = [System.Drawing.Color]::FromArgb(220, 38, 38)
    $colorRedSoft = [System.Drawing.Color]::FromArgb(254, 242, 242)
    $colorLog = [System.Drawing.Color]::FromArgb(248, 250, 252)

    function Add-PanelBorder {
        param(
            [System.Windows.Forms.Panel]$Panel,
            [System.Drawing.Color]$BorderColor
        )

        $Panel.Tag = $BorderColor
        $Panel.Add_Paint({
            param($sender, $eventArgs)
            $pen = New-Object System.Drawing.Pen($sender.Tag)
            $eventArgs.Graphics.DrawRectangle(
                $pen,
                0,
                0,
                $sender.ClientSize.Width - 1,
                $sender.ClientSize.Height - 1
            )
            $pen.Dispose()
        })
    }

    function New-FlatButton {
        param(
            [string]$Text,
            [int]$X,
            [int]$Y,
            [int]$Width,
            [int]$Height,
            [bool]$Primary = $false
        )

        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Text
        $button.Location = New-Object System.Drawing.Point($X, $Y)
        $button.Size = New-Object System.Drawing.Size($Width, $Height)
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        $button.TabStop = $true

        if ($Primary) {
            $button.BackColor = $colorBlue
            $button.ForeColor = [System.Drawing.Color]::White
            $button.FlatAppearance.BorderSize = 0
            $button.Tag = [PSCustomObject]@{
                NormalBack = $colorBlue
                HoverBack = $colorBlueHover
                NormalFore = [System.Drawing.Color]::White
            }
        }
        else {
            $button.BackColor = $colorSurface
            $button.ForeColor = $colorInk
            $button.FlatAppearance.BorderSize = 1
            $button.FlatAppearance.BorderColor = $colorBorder
            $button.Tag = [PSCustomObject]@{
                NormalBack = $colorSurface
                HoverBack = $colorLog
                NormalFore = $colorInk
            }
        }

        $button.Add_MouseEnter({
            param($sender, $eventArgs)
            if ($sender.Enabled) {
                $sender.BackColor = $sender.Tag.HoverBack
            }
        })

        $button.Add_MouseLeave({
            param($sender, $eventArgs)
            if ($sender.Enabled) {
                $sender.BackColor = $sender.Tag.NormalBack
            }
        })

        $button.Add_EnabledChanged({
            param($sender, $eventArgs)
            if ($sender.Enabled) {
                $sender.BackColor = $sender.Tag.NormalBack
                $sender.ForeColor = $sender.Tag.NormalFore
            }
            else {
                $sender.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
                $sender.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
            }
        })

        return $button
    }

    function New-MetricCard {
        param(
            [string]$Title,
            [string]$Value,
            [string]$Note,
            [int]$X,
            [int]$Y,
            [int]$Width,
            [System.Drawing.Color]$AccentColor,
            [System.Drawing.Color]$SoftColor
        )

        $panel = New-Object System.Windows.Forms.Panel
        $panel.Location = New-Object System.Drawing.Point($X, $Y)
        $panel.Size = New-Object System.Drawing.Size($Width, 82)
        $panel.BackColor = $colorSurface
        Add-PanelBorder -Panel $panel -BorderColor $colorBorder

        $accent = New-Object System.Windows.Forms.Panel
        $accent.Location = New-Object System.Drawing.Point(0, 0)
        $accent.Size = New-Object System.Drawing.Size(5, 82)
        $accent.BackColor = $AccentColor
        $panel.Controls.Add($accent)

        $badge = New-Object System.Windows.Forms.Panel
        $badge.Location = New-Object System.Drawing.Point($Width - 42, 15)
        $badge.Size = New-Object System.Drawing.Size(22, 22)
        $badge.BackColor = $SoftColor
        $panel.Controls.Add($badge)

        $dot = New-Object System.Windows.Forms.Panel
        $dot.Location = New-Object System.Drawing.Point(7, 7)
        $dot.Size = New-Object System.Drawing.Size(8, 8)
        $dot.BackColor = $AccentColor
        $badge.Controls.Add($dot)

        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $Title
        $titleLabel.ForeColor = $colorMuted
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5)
        $titleLabel.AutoSize = $true
        $titleLabel.Location = New-Object System.Drawing.Point(17, 12)
        $panel.Controls.Add($titleLabel)

        $valueLabel = New-Object System.Windows.Forms.Label
        $valueLabel.Text = $Value
        $valueLabel.ForeColor = $colorInk
        $valueLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
        $valueLabel.AutoSize = $true
        $valueLabel.Location = New-Object System.Drawing.Point(16, 32)
        $panel.Controls.Add($valueLabel)

        $noteLabel = New-Object System.Windows.Forms.Label
        $noteLabel.Text = $Note
        $noteLabel.ForeColor = $colorMuted
        $noteLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $noteLabel.AutoSize = $true
        $noteLabel.Location = New-Object System.Drawing.Point(18, 60)
        $panel.Controls.Add($noteLabel)

        return [PSCustomObject]@{
            Panel = $panel
            Accent = $accent
            Badge = $badge
            Dot = $dot
            Value = $valueLabel
            Note = $noteLabel
        }
    }

    function Set-MetricCard {
        param(
            $Card,
            [string]$Value,
            [string]$Note,
            [System.Drawing.Color]$AccentColor,
            [System.Drawing.Color]$SoftColor
        )

        $Card.Value.Text = $Value
        $Card.Note.Text = $Note
        $Card.Accent.BackColor = $AccentColor
        $Card.Badge.BackColor = $SoftColor
        $Card.Dot.BackColor = $AccentColor
    }

    function Set-StatusPill {
        param(
            [System.Windows.Forms.Label]$Label,
            [string]$Text,
            [System.Drawing.Color]$BackColor,
            [System.Drawing.Color]$ForeColor
        )

        $Label.Text = $Text
        $Label.BackColor = $BackColor
        $Label.ForeColor = $ForeColor
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$($script:AppName) $($script:Version)"
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.ClientSize = New-Object System.Drawing.Size(1084, 712)
    $form.MinimumSize = New-Object System.Drawing.Size(1100, 751)
    $form.MaximumSize = New-Object System.Drawing.Size(1100, 751)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.BackColor = $colorWindow
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.KeyPreview = $true

    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = [System.Windows.Forms.DockStyle]::Top
    $header.Height = 126
    $header.BackColor = $colorHeader
    $form.Controls.Add($header)

    $headerAccent = New-Object System.Windows.Forms.Panel
    $headerAccent.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $headerAccent.Height = 3
    $headerAccent.BackColor = $colorBlue
    $header.Controls.Add($headerAccent)

    $eyebrow = New-Object System.Windows.Forms.Label
    $eyebrow.Text = "NETWORK DIAGNOSTICS"
    $eyebrow.ForeColor = [System.Drawing.Color]::FromArgb(147, 197, 253)
    $eyebrow.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5)
    $eyebrow.AutoSize = $true
    $eyebrow.Location = New-Object System.Drawing.Point(28, 19)
    $header.Controls.Add($eyebrow)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "ProxyScope"
    $title.ForeColor = [System.Drawing.Color]::White
    $title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 27)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(26, 38)
    $header.Controls.Add($title)

    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = "Understand proxy, DNS, routing, ports, and direct connectivity in one scan"
    $subtitle.ForeColor = [System.Drawing.Color]::FromArgb(203, 213, 225)
    $subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitle.AutoSize = $true
    $subtitle.Location = New-Object System.Drawing.Point(30, 88)
    $header.Controls.Add($subtitle)

    $readOnlyPill = New-Object System.Windows.Forms.Label
    $readOnlyPill.Text = "READ ONLY"
    $readOnlyPill.BackColor = [System.Drawing.Color]::FromArgb(15, 118, 110)
    $readOnlyPill.ForeColor = [System.Drawing.Color]::White
    $readOnlyPill.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
    $readOnlyPill.AutoSize = $true
    $readOnlyPill.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
    $readOnlyPill.Location = New-Object System.Drawing.Point(889, 20)
    $header.Controls.Add($readOnlyPill)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "v$($script:Version)"
    $versionLabel.BackColor = $colorHeaderSoft
    $versionLabel.ForeColor = [System.Drawing.Color]::White
    $versionLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $versionLabel.AutoSize = $true
    $versionLabel.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
    $versionLabel.Location = New-Object System.Drawing.Point(989, 20)
    $header.Controls.Add($versionLabel)

    $content = New-Object System.Windows.Forms.Panel
    $content.Dock = [System.Windows.Forms.DockStyle]::Fill
    $content.BackColor = $colorWindow
    $form.Controls.Add($content)

    $overallCard = New-MetricCard -Title "OVERALL STATUS" -Value "Ready" -Note "Waiting for a scan" -X 24 -Y 18 -Width 250 -AccentColor $colorBlue -SoftColor $colorBlueSoft
    $criticalCard = New-MetricCard -Title "CRITICAL" -Value "0" -Note "No critical findings" -X 286 -Y 18 -Width 250 -AccentColor $colorRed -SoftColor $colorRedSoft
    $warningCard = New-MetricCard -Title "WARNINGS" -Value "0" -Note "No warnings" -X 548 -Y 18 -Width 250 -AccentColor $colorAmber -SoftColor $colorAmberSoft
    $passedCard = New-MetricCard -Title "PASSED CHECKS" -Value "0" -Note "Run a scan to evaluate" -X 810 -Y 18 -Width 250 -AccentColor $colorGreen -SoftColor $colorGreenSoft

    foreach ($metric in @($overallCard, $criticalCard, $warningCard, $passedCard)) {
        $content.Controls.Add($metric.Panel)
    }

    $scanCard = New-Object System.Windows.Forms.Panel
    $scanCard.Location = New-Object System.Drawing.Point(24, 112)
    $scanCard.Size = New-Object System.Drawing.Size(662, 402)
    $scanCard.BackColor = $colorSurface
    Add-PanelBorder -Panel $scanCard -BorderColor $colorBorder
    $content.Controls.Add($scanCard)

    $scanTitle = New-Object System.Windows.Forms.Label
    $scanTitle.Text = "Run network diagnosis"
    $scanTitle.ForeColor = $colorInk
    $scanTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
    $scanTitle.AutoSize = $true
    $scanTitle.Location = New-Object System.Drawing.Point(24, 20)
    $scanCard.Controls.Add($scanTitle)

    $scanDescription = New-Object System.Windows.Forms.Label
    $scanDescription.Text = "Compare direct access with the active Windows proxy and inspect local network state"
    $scanDescription.ForeColor = $colorMuted
    $scanDescription.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $scanDescription.AutoSize = $true
    $scanDescription.Location = New-Object System.Drawing.Point(27, 52)
    $scanCard.Controls.Add($scanDescription)

    $statusPill = New-Object System.Windows.Forms.Label
    $statusPill.Text = "READY"
    $statusPill.BackColor = $colorBlueSoft
    $statusPill.ForeColor = $colorBlue
    $statusPill.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
    $statusPill.AutoSize = $true
    $statusPill.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
    $statusPill.Location = New-Object System.Drawing.Point(550, 20)
    $scanCard.Controls.Add($statusPill)

    $progressTrack = New-Object System.Windows.Forms.Panel
    $progressTrack.Location = New-Object System.Drawing.Point(28, 88)
    $progressTrack.Size = New-Object System.Drawing.Size(606, 12)
    $progressTrack.BackColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
    $scanCard.Controls.Add($progressTrack)

    $progressFill = New-Object System.Windows.Forms.Panel
    $progressFill.Location = New-Object System.Drawing.Point(0, 0)
    $progressFill.Size = New-Object System.Drawing.Size(0, 12)
    $progressFill.BackColor = $colorBlue
    $progressTrack.Controls.Add($progressFill)

    $currentStep = New-Object System.Windows.Forms.Label
    $currentStep.Text = "Ready to start"
    $currentStep.ForeColor = $colorInk
    $currentStep.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $currentStep.AutoSize = $true
    $currentStep.Location = New-Object System.Drawing.Point(27, 111)
    $scanCard.Controls.Add($currentStep)

    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Text = "0%"
    $percentLabel.ForeColor = $colorMuted
    $percentLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $percentLabel.AutoSize = $true
    $percentLabel.Location = New-Object System.Drawing.Point(604, 111)
    $scanCard.Controls.Add($percentLabel)

    $logLabel = New-Object System.Windows.Forms.Label
    $logLabel.Text = "ACTIVITY LOG"
    $logLabel.ForeColor = $colorMuted
    $logLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
    $logLabel.AutoSize = $true
    $logLabel.Location = New-Object System.Drawing.Point(27, 145)
    $scanCard.Controls.Add($logLabel)

    $logPanel = New-Object System.Windows.Forms.Panel
    $logPanel.Location = New-Object System.Drawing.Point(28, 168)
    $logPanel.Size = New-Object System.Drawing.Size(606, 207)
    $logPanel.BackColor = $colorLog
    Add-PanelBorder -Panel $logPanel -BorderColor $colorBorder
    $scanCard.Controls.Add($logPanel)

    $logBox = New-Object System.Windows.Forms.RichTextBox
    $logBox.Location = New-Object System.Drawing.Point(12, 10)
    $logBox.Size = New-Object System.Drawing.Size(582, 184)
    $logBox.ReadOnly = $true
    $logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $logBox.BackColor = $colorLog
    $logBox.ForeColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
    $logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
    $logBox.DetectUrls = $false
    $logBox.Text = "ProxyScope is ready.`r`n"
    $logPanel.Controls.Add($logBox)

    $overviewCard = New-Object System.Windows.Forms.Panel
    $overviewCard.Location = New-Object System.Drawing.Point(700, 112)
    $overviewCard.Size = New-Object System.Drawing.Size(360, 402)
    $overviewCard.BackColor = $colorSurface
    Add-PanelBorder -Panel $overviewCard -BorderColor $colorBorder
    $content.Controls.Add($overviewCard)

    $overviewTitle = New-Object System.Windows.Forms.Label
    $overviewTitle.Text = "Scan overview"
    $overviewTitle.ForeColor = $colorInk
    $overviewTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
    $overviewTitle.AutoSize = $true
    $overviewTitle.Location = New-Object System.Drawing.Point(22, 20)
    $overviewCard.Controls.Add($overviewTitle)

    $overviewDescription = New-Object System.Windows.Forms.Label
    $overviewDescription.Text = "A concise summary of the latest run"
    $overviewDescription.ForeColor = $colorMuted
    $overviewDescription.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $overviewDescription.AutoSize = $true
    $overviewDescription.Location = New-Object System.Drawing.Point(25, 52)
    $overviewCard.Controls.Add($overviewDescription)

    $summaryPanel = New-Object System.Windows.Forms.Panel
    $summaryPanel.Location = New-Object System.Drawing.Point(24, 86)
    $summaryPanel.Size = New-Object System.Drawing.Size(312, 104)
    $summaryPanel.BackColor = $colorBlueSoft
    $overviewCard.Controls.Add($summaryPanel)

    $summaryStatus = New-Object System.Windows.Forms.Label
    $summaryStatus.Text = "Ready for diagnosis"
    $summaryStatus.ForeColor = $colorBlue
    $summaryStatus.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    $summaryStatus.AutoSize = $true
    $summaryStatus.Location = New-Object System.Drawing.Point(15, 14)
    $summaryPanel.Controls.Add($summaryStatus)

    $summaryText = New-Object System.Windows.Forms.Label
    $summaryText.Text = "Run a scan to identify proxy, DNS, routing, and connectivity problems."
    $summaryText.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
    $summaryText.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $summaryText.AutoSize = $false
    $summaryText.Size = New-Object System.Drawing.Size(280, 55)
    $summaryText.Location = New-Object System.Drawing.Point(16, 40)
    $summaryPanel.Controls.Add($summaryText)

    $pathLabel = New-Object System.Windows.Forms.Label
    $pathLabel.Text = "LATEST REPORT"
    $pathLabel.ForeColor = $colorMuted
    $pathLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
    $pathLabel.AutoSize = $true
    $pathLabel.Location = New-Object System.Drawing.Point(23, 211)
    $overviewCard.Controls.Add($pathLabel)

    $pathBox = New-Object System.Windows.Forms.TextBox
    $pathBox.Location = New-Object System.Drawing.Point(24, 235)
    $pathBox.Size = New-Object System.Drawing.Size(312, 58)
    $pathBox.Multiline = $true
    $pathBox.ReadOnly = $true
    $pathBox.BackColor = $colorLog
    $pathBox.ForeColor = $colorMuted
    $pathBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pathBox.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $pathBox.Text = "No report has been created yet"
    $overviewCard.Controls.Add($pathBox)

    $copyPathButton = New-FlatButton -Text "Copy path" -X 24 -Y 309 -Width 96 -Height 38 -Primary $false
    $copyPathButton.Enabled = $false
    $overviewCard.Controls.Add($copyPathButton)

    $openReportButton = New-FlatButton -Text "Open report" -X 132 -Y 309 -Width 98 -Height 38 -Primary $false
    $openReportButton.Enabled = $false
    $overviewCard.Controls.Add($openReportButton)

    $openFolderButton = New-FlatButton -Text "Open folder" -X 242 -Y 309 -Width 94 -Height 38 -Primary $false
    $overviewCard.Controls.Add($openFolderButton)

    $privacyLine = New-Object System.Windows.Forms.Label
    $privacyLine.Text = "Reports stay on this computer"
    $privacyLine.ForeColor = $colorMuted
    $privacyLine.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $privacyLine.AutoSize = $true
    $privacyLine.Location = New-Object System.Drawing.Point(24, 365)
    $overviewCard.Controls.Add($privacyLine)

    $actionBar = New-Object System.Windows.Forms.Panel
    $actionBar.Location = New-Object System.Drawing.Point(24, 528)
    $actionBar.Size = New-Object System.Drawing.Size(1036, 66)
    $actionBar.BackColor = $colorSurface
    Add-PanelBorder -Panel $actionBar -BorderColor $colorBorder
    $content.Controls.Add($actionBar)

    $runButton = New-FlatButton -Text "Run diagnosis" -X 16 -Y 11 -Width 188 -Height 44 -Primary $true
    $actionBar.Controls.Add($runButton)

    $actionHint = New-Object System.Windows.Forms.Label
    $actionHint.Text = "Read-only scan  •  HTML + JSON output  •  Windows PowerShell 5.1 compatible"
    $actionHint.ForeColor = $colorMuted
    $actionHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $actionHint.AutoSize = $true
    $actionHint.Location = New-Object System.Drawing.Point(222, 25)
    $actionBar.Controls.Add($actionHint)

    $exitButton = New-FlatButton -Text "Exit" -X 916 -Y 11 -Width 104 -Height 44 -Primary $false
    $actionBar.Controls.Add($exitButton)

    $footer = New-Object System.Windows.Forms.Label
    $footer.Text = "Output folder: Desktop\ProxyScopeReports"
    $footer.ForeColor = $colorMuted
    $footer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $footer.AutoSize = $true
    $footer.Location = New-Object System.Drawing.Point(25, 607)
    $content.Controls.Add($footer)

    function Update-FindingSummary {
        param($Findings)

        $criticalCount = @($Findings | Where-Object { $_.Severity -eq "Critical" }).Count
        $warningCount = @($Findings | Where-Object { $_.Severity -eq "Warning" }).Count
        $okCount = @($Findings | Where-Object { $_.Severity -eq "OK" }).Count

        Set-MetricCard -Card $criticalCard -Value ([string]$criticalCount) -Note $(if ($criticalCount -eq 0) { "No critical findings" } else { "Immediate review required" }) -AccentColor $colorRed -SoftColor $colorRedSoft
        Set-MetricCard -Card $warningCard -Value ([string]$warningCount) -Note $(if ($warningCount -eq 0) { "No warnings" } else { "Review recommended" }) -AccentColor $colorAmber -SoftColor $colorAmberSoft
        Set-MetricCard -Card $passedCard -Value ([string]$okCount) -Note "Checks completed successfully" -AccentColor $colorGreen -SoftColor $colorGreenSoft

        if ($criticalCount -gt 0) {
            Set-MetricCard -Card $overallCard -Value "Action required" -Note "Critical network issue detected" -AccentColor $colorRed -SoftColor $colorRedSoft
            $summaryPanel.BackColor = $colorRedSoft
            $summaryStatus.ForeColor = $colorRed
            $summaryStatus.Text = "Action required"
            $summaryText.Text = "$criticalCount critical finding(s) and $warningCount warning(s) were detected. Open the report for details."
        }
        elseif ($warningCount -gt 0) {
            Set-MetricCard -Card $overallCard -Value "Review" -Note "Network works with warnings" -AccentColor $colorAmber -SoftColor $colorAmberSoft
            $summaryPanel.BackColor = $colorAmberSoft
            $summaryStatus.ForeColor = $colorAmber
            $summaryStatus.Text = "Review recommended"
            $summaryText.Text = "The scan completed without a critical failure, but $warningCount setting(s) should be reviewed."
        }
        else {
            Set-MetricCard -Card $overallCard -Value "Healthy" -Note "No obvious network issue" -AccentColor $colorGreen -SoftColor $colorGreenSoft
            $summaryPanel.BackColor = $colorGreenSoft
            $summaryStatus.ForeColor = $colorGreen
            $summaryStatus.Text = "Network looks healthy"
            $summaryText.Text = "No obvious proxy, DNS, route, or basic connectivity problem was detected."
        }
    }

    $runButton.Add_Click({
        $runButton.Enabled = $false
        $runButton.Text = "Scanning..."
        $openReportButton.Enabled = $false
        $copyPathButton.Enabled = $false
        $progressFill.Width = 0
        $percentLabel.Text = "0%"
        $scanTitle.Text = "Diagnosis in progress"
        $currentStep.Text = "Preparing network checks"
        $logBox.Clear()
        $logBox.AppendText("ProxyScope scan started.`r`n")
        Set-StatusPill -Label $statusPill -Text "SCANNING" -BackColor $colorBlueSoft -ForeColor $colorBlue
        Set-MetricCard -Card $overallCard -Value "Scanning" -Note "Collecting network data" -AccentColor $colorBlue -SoftColor $colorBlueSoft
        Set-MetricCard -Card $criticalCard -Value "0" -Note "Waiting for results" -AccentColor $colorRed -SoftColor $colorRedSoft
        Set-MetricCard -Card $warningCard -Value "0" -Note "Waiting for results" -AccentColor $colorAmber -SoftColor $colorAmberSoft
        Set-MetricCard -Card $passedCard -Value "0" -Note "Waiting for results" -AccentColor $colorGreen -SoftColor $colorGreenSoft
        $summaryPanel.BackColor = $colorBlueSoft
        $summaryStatus.ForeColor = $colorBlue
        $summaryStatus.Text = "Scanning local network"
        $summaryText.Text = "ProxyScope is comparing direct and proxied connectivity while collecting adapter, DNS, process, and route data."

        try {
            $result = Invoke-Diagnosis -ProgressCallback {
                param($percent, $message)

                $safePercent = [Math]::Min([Math]::Max([int]$percent, 0), 100)
                $progressFill.Width = [int](606 * $safePercent / 100)
                $percentLabel.Text = "$safePercent%"
                $currentStep.Text = $message
                $logBox.AppendText("[$safePercent%] $message`r`n")
                $logBox.SelectionStart = $logBox.TextLength
                $logBox.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }

            $script:LatestReport = $result.HtmlPath
            $scanTitle.Text = "Diagnosis complete"
            $currentStep.Text = "Reports created successfully"
            $percentLabel.Text = "100%"
            $pathBox.Text = $result.HtmlPath
            $pathBox.ForeColor = $colorInk
            $openReportButton.Enabled = $true
            $copyPathButton.Enabled = $true
            $logBox.AppendText("`r`nHTML report: $($result.HtmlPath)`r`n")
            $logBox.AppendText("JSON report: $($result.JsonPath)`r`n")
            Set-StatusPill -Label $statusPill -Text "COMPLETE" -BackColor $colorGreenSoft -ForeColor $colorGreen
            Update-FindingSummary -Findings $result.Findings
            Start-Process $result.HtmlPath
        }
        catch {
            $scanTitle.Text = "Diagnosis failed"
            $currentStep.Text = "An unexpected error stopped the scan"
            $logBox.AppendText("`r`nERROR: $($_.Exception.Message)`r`n")
            Set-StatusPill -Label $statusPill -Text "FAILED" -BackColor $colorRedSoft -ForeColor $colorRed
            Set-MetricCard -Card $overallCard -Value "Failed" -Note "Review the activity log" -AccentColor $colorRed -SoftColor $colorRedSoft
            $summaryPanel.BackColor = $colorRedSoft
            $summaryStatus.ForeColor = $colorRed
            $summaryStatus.Text = "Scan could not finish"
            $summaryText.Text = "Review the activity log. The startup syntax validator should identify source-file problems before the GUI opens."
        }
        finally {
            $runButton.Text = "Run diagnosis"
            $runButton.Enabled = $true
        }
    })

    $copyPathButton.Add_Click({
        if ($script:LatestReport -and (Test-Path -LiteralPath $script:LatestReport)) {
            [System.Windows.Forms.Clipboard]::SetText($script:LatestReport)
            $copyPathButton.Text = "Copied"

            $timer = New-Object System.Windows.Forms.Timer
            $timer.Interval = 1200
            $timer.Tag = $copyPathButton
            $timer.Add_Tick({
                param($sender, $eventArgs)
                $sender.Stop()
                $sender.Tag.Text = "Copy path"
                $sender.Dispose()
            })
            $timer.Start()
        }
    })

    $openReportButton.Add_Click({
        if ($script:LatestReport -and (Test-Path -LiteralPath $script:LatestReport)) {
            Start-Process $script:LatestReport
        }
    })

    $openFolderButton.Add_Click({
        $folder = Join-Path (Get-DesktopPath) "ProxyScopeReports"

        if (-not (Test-Path -LiteralPath $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }

        Start-Process explorer.exe -ArgumentList "`"$folder`""
    })

    $exitButton.Add_Click({
        $form.Close()
    })

    $form.Add_KeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $form.Close()
        }
    })

    $form.AcceptButton = $runButton

    [void]$form.ShowDialog()
}
