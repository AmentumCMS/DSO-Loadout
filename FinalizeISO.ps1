Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Prompt for ISO File
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*"
$FileBrowser.Title = "Select an ISO file to burn"

if ($FileBrowser.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }
$SelectedISO = $FileBrowser.FileName

# --- Smart Renaming Logic ---
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($SelectedISO)

# Step A: Strip leading numbers and symbols (e.g., "10Example" -> "Example")
$NoLeadingNumbers = $BaseName -replace '^[0-9\s_\-]+', ''

# Step B: Split by Capitals (Pascal/Camel), Underscores, or Hyphens
$SplitPattern = "([a-z])([A-Z])|[_ -]+"
$Cleaned = [regex]::Replace($NoLeadingNumbers, $SplitPattern, '$1 $2').Trim()

# Step C: Convert to Title Case
$TextInfo = (Get-Culture).TextInfo
$SuggestedLabel = $TextInfo.ToTitleCase($Cleaned.ToLower())

# ISO Volume Labels are limited to 32 chars
if ($SuggestedLabel.Length -gt 32) { $SuggestedLabel = $SuggestedLabel.Substring(0, 32) }
# -----------------------------

# 2. Detect Optical Drives
$DiskMaster = New-Object -ComObject IMAPI2.MsftDiscMaster2
$DriveList = foreach ($Id in $DiskMaster) {
    $Recorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2
    $Recorder.InitializeDiscRecorder($Id)
    [PSCustomObject]@{
        Name = "$($Recorder.VolumePathNames) ($($Recorder.VendorId) $($Recorder.ProductId))"
        Id   = $Id
    }
}

if ($DriveList.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("No CD/DVD drives detected.")
    exit
}

# 3. GUI for Customization
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO Burner & Finalizer"
$Form.Size = New-Object System.Drawing.Size(380,240)
$Form.StartPosition = "CenterScreen"
$Form.Topmost = $true

$LabelFile = New-Object System.Windows.Forms.Label
$LabelFile.Text = "File: $(Split-Path $SelectedISO -Leaf)"
$LabelFile.Location = New-Object System.Drawing.Point(15,10)
$LabelFile.AutoSize = $true
$Form.Controls.Add($LabelFile)

$LabelName = New-Object System.Windows.Forms.Label
$LabelName.Text = "Disc Name (Volume Label):"
$LabelName.Location = New-Object System.Drawing.Point(15,40)
$LabelName.AutoSize = $true
$Form.Controls.Add($LabelName)

$NameInput = New-Object System.Windows.Forms.TextBox
$NameInput.Text = $SuggestedLabel
$NameInput.Location = New-Object System.Drawing.Point(15,60)
$NameInput.Size = New-Object System.Drawing.Size(330,30)
$Form.Controls.Add($NameInput)

$LabelDrive = New-Object System.Windows.Forms.Label
$LabelDrive.Text = "Choose Drive:"
$LabelDrive.Location = New-Object System.Drawing.Point(15,100)
$LabelDrive.AutoSize = $true
$Form.Controls.Add($LabelDrive)

$DropDown = New-Object System.Windows.Forms.ComboBox
$DropDown.Location = New-Object System.Drawing.Point(15,120)
$DropDown.Size = New-Object System.Drawing.Size(330,30)
$DropDown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
foreach ($Drive in $DriveList) { [void]$DropDown.Items.Add($Drive.Name) }
$DropDown.SelectedIndex = 0
$Form.Controls.Add($DropDown)

$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Burn & Finalize"
$Button.Location = New-Object System.Drawing.Point(130,160)
$Button.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.AcceptButton = $Button
$Form.Controls.Add($Button)

# 4. Final Execution
if ($Form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $FinalLabel = $NameInput.Text
    $Confirm = [System.Windows.Forms.MessageBox]::Show("Start burning to $($DriveList[$DropDown.SelectedIndex].Name)?`n`nLabel: '$FinalLabel'", "Confirm Burn", "YesNo", "Question")
    
    if ($Confirm -eq "Yes") {
        $TargetId = $DriveList[$DropDown.SelectedIndex].Id
        
        try {
            $DiscRecorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2
            $DiscRecorder.InitializeDiscRecorder($TargetId)

            $DiscFormatData = New-Object -ComObject IMAPI2.MsftDiscFormat2Data
            $DiscFormatData.Recorder = $DiscRecorder
            $DiscFormatData.ClientName = "PowerShell_ISO_Burner"
            $DiscFormatData.ForceMediaToBeClosed = $true

            # Stream the ISO
            $IStream = New-Object -ComObject ADODB.Stream
            $IStream.Type = 1 # Binary
            $IStream.Open()
            $IStream.LoadFromFile($SelectedISO)

            Write-Host "Burning '$FinalLabel' and Finalizing..."
            
            # The burn operation
            $DiscFormatData.Write($IStream)
            
            [System.Windows.Forms.MessageBox]::Show("Success! Disc '$FinalLabel' is finalized.", "Done")
            $DiscRecorder.Eject() 
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Operation Failed")
        } finally {
            if ($IStream) { $IStream.Close() }
        }
    }
}