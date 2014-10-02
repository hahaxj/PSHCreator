﻿<# 
 
.DESCRIPTION 
   AZure AutoScript AddOn
 
.NOTES 
    Author: Freist Li
    Last Updated: 10/2/2014   
#> 
Add-Type -AssemblyName System.Windows.Forms 

#import the Azure PowerShell modules
function ImportAzureModules
{
    #import the Azure PowerShell modules
    Write-Host "`n[WORKITEM] - Importing Azure PowerShell module" -ForegroundColor Cyan

    If ($ENV:Processor_Architecture -eq "x86")
    {
            $ModulePath = "$Env:ProgramFiles\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"

    }
    Else
    {
            $ModulePath = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
    }

    Try
    {
            If (-not(Get-Module -name "Azure")) 
            { 
                   If (Test-Path $ModulePath) 
                   { 
                           Import-Module -Name $ModulePath
                   }
                   Else
                   {
                           #show module not found interaction and bail out
                           Write-Host "[ERROR] - Azure PowerShell module not found. Exiting." -ForegroundColor Red
                           Exit
                   }
            }

            Write-Host "`tSuccess"
    }
    Catch [Exception]
    {
            #show module not found interaction and bail out
            Write-Host "[ERROR] - PowerShell module not found. Exiting." -ForegroundColor Red
            Exit
    }
}
#Check the Azure PowerShell module version
Function CheckAZurePSVersion
{
    #Check the Azure PowerShell module version
    Write-Host "`n[WORKITEM] - Checking Azure PowerShell module verion" -ForegroundColor Cyan
    $PSMajor =(Get-Module azure).version.Major
    $PSMinor =(Get-Module azure).version.Minor
    $PSBuild =(Get-Module azure).version.Build
    $PSVersion =("$PSMajor.$PSMinor.$PSBuild")

    If ($PSVersion -ge 0.8.8)
    {
        Write-Host "`tSuccess"
        Write-Host "`tVersion" $PSVersion 
    }
    Else
    {
       Write-Host "[ERROR] - Azure PowerShell module must be version 0.8.8 or higher. Exiting." -ForegroundColor Red
    }
}
# Process Bar

Function PBStart {
Param ($name)
    $x = Get-Random -minimum 1 -maximum 50

    write-progress -activity "PowerShell AutoScript"  -CurrentOperation $name -PercentComplete $x
}
Function PBStop{
    write-progress -activity "PowerShell AutoScript" -status "Completed" -PercentComplete 100
    write-progress -activity "PowerShell AutoScript" -status "Completed" -Completed
}
#Use Add-AzureAccount
Function SignInAZureAccount
{
    #Sign In Azure Account
    Write-Host "`n[INFO] - Authenticating Azure account."  -ForegroundColor Cyan
    Add-AzureAccount |Out-Null
    #Check to make sure authentication occured
    If ($?)
    {
	    Write-Host "`tSuccess"
        Get-AzureSubscription |ForEach-Object {write-host "`tDefault Account is: " $_.DefaultAccount}
    }
    Else
    {
	    Write-Host "`tFailed authentication" -ForegroundColor Red	 
    }    
}


#Get Current AZure Account
Function GetCurrentAccount
{
   Get-AzureSubscription |ForEach-Object {return $_.DefaultAccount}
}

#Get Certain Azure WebSites
Function GetCertainWAWS
{ Param ($sitename)
    #Get Certain Azure WebSites
    Write-host "["$sitename"]" Status -ForegroundColor Cyan
    Get-AzureWebsite $sitename 
}


#Get Running Azure WebSites
Function GetRunningWAWS
{
   #Get Running Azure WebSites
   Get-AzureWebsite | ForEach-Object {if ($_.State -match "^Running") `
                                        {
                                           Write-host "["$_.Name"]" Running Status -ForegroundColor Cyan
                                              Get-AzureWebsite $_.Name
                                         }
                                   }
}

#Get Stopped Azure WebSites
Function GetStoppedWAWS
{
   #Get Stopped Azure WebSites
   Get-AzureWebsite | ForEach-Object {if ($_.State -match "^Stopped") `
                                        {
                                           Write-host "["$_.Name"]" Stopped Status -ForegroundColor Cyan
                                              Get-AzureWebsite $_.Name
                                         }
                                   }
}


#Get All Azure WebSites
Function GetWAWS
{
    #Get All Azure WebSites
    Get-AzureWebsite | ForEach-Object {  
                                              Write-host "["$_.Name"]" Status -ForegroundColor Cyan
                                              Get-AzureWebsite $_.Name
                                           }
}


#Get WAWS Name List
Function GetWAWSList
{
    $list = New-Object 'System.Collections.Generic.List[string]'
    Get-AzureWebsite | ForEach-Object {  
                                            $list.add($_.Name)
                                        }
    $list.Sort()
    return $list
}


#Get All Azure StorageInfo and Keys
Function GetStorageAccount
{
  Get-AzureStorageAccount | ForEach-Object {
                                           Storage Write-host $_.StorageAccountName PropertiesInfo -ForegroundColor Cyan
                                           $_|Format-List -Property *
                                           Write-host $_.StorageAccountName KeyInfo -ForegroundColor Cyan
                                           Get-AzureStorageKey -StorageAccountName $_.StorageAccountName   
                                          }
}

#AutoScript WAWS Query
Function GenerateWAWSQueryCode {
Param (
        $Signin = 0,
        $CheckVersion = 0,
        $Sitename = ‘All'        
      )

    if ($Signin -eq 1)
    {
            $samplecode = (Get-Command SignInAZureAccount).Definition
    }
    if ($CheckVersion -eq 1)
    {
            $samplecode = $samplecode + "`r`n" + (Get-Command CheckAZurePSVersion).Definition
    }
    if ($Sitename -match 'All')
    {
            $samplecode = $samplecode + "`r`n" +  (Get-Command GetWAWS).Definition
    }
    elseif ($Sitename -match 'Running')
    {
            $samplecode = $samplecode + "`r`n" +  (Get-Command GetRunningWAWS).Definition
    }
    elseif ($Sitename -match 'Stopped')
    {
            $samplecode = $samplecode + "`r`n" +  (Get-Command GetStoppedWAWS).Definition
    }
    else
    {       $samplecode = $samplecode + "`r`n" +"Function GetCertainWAWS {"
            $samplecode = $samplecode + "`r`n" +  (Get-Command GetCertainWAWS).Definition +"}"
            $samplecode = $samplecode + "`r`n" + "GetCertainWAWS "+$Sitename
    }
    return $samplecode  
}

#AZure WAWS Autoscript Launch Form
Function AZureWAWSASLaunchForm{

        $Form = New-Object system.Windows.Forms.Form

        $Form.Text = "AZure WAWS Query AutoScript in PowerShell"
        $Form.MinimizeBox = $False
        $Form.MaximizeBox = $False
        $Form.width = 450

        $Labe1 = New-Object System.Windows.Forms.Label
        $Labe1.AutoSize = $True
        $Labe1.Text = "Not Known"
        $Labe1.Location = New-Object System.Drawing.Size(140,15)
        $Form.Controls.Add($Labe1)

        $CurrentButton = New-Object System.Windows.Forms.Button
        $CurrentButton.Text = "Get Current Account"
        $CurrentButton.AutoSize = $True
        $CurrentButton.Location = New-Object System.Drawing.Size(20,10)
        $CurrentButton.Add_Click({ pbstart "Get CurrentAccount"
                                   $Labe1.Text = GetCurrentAccount
                                   pbstop})
        $Form.Controls.Add($CurrentButton)

        
        $SigninButton = New-Object System.Windows.Forms.Button
        $SigninButton.Location = New-Object System.Drawing.Size(20,40)
        $SigninButton.Size = New-Object System.Drawing.Size(130,23)
        $SigninButton.Text = "Sign In AZure Account"
        $SigninButton.Add_Click({pbstart "Signin AZure Account"
                                 SignInAZureAccount
                                 pbstop})
        $Form.Controls.Add($SigninButton)


        $Labe2 = New-Object System.Windows.Forms.Label
        $Labe2.Text = "WAWS Filter"
        $Labe2.AutoSize = $True
        $Labe2.Location = New-Object System.Drawing.Size(20,70)
        $Form.Controls.Add($Labe2)

        $WAWSlist = New-Object 'System.Collections.Generic.List[string]'

        $comboBox1 = New-Object System.Windows.Forms.ComboBox
        $comboBox1.Location = New-Object System.Drawing.Point(20, 90)
        $comboBox1.Size = New-Object System.Drawing.Size(150, 310)
        $comboBox1.Items.add("All")
        $comboBox1.Items.add("Running")
        $comboBox1.Items.add("Stopped")
        $Form.Controls.Add($comboBox1)
        $comboBox1.SelectedIndex = 0

        $WAWSButton = New-Object System.Windows.Forms.Button
        $WAWSButton.Location = New-Object System.Drawing.Size(200,90)
        $WAWSButton.AutoSize = $True
        $WAWSButton.Text = "Fill WAWS List"
        $WAWSButton.Add_Click({
                                $comboBox1.Items.Clear()
                                $comboBox1.Items.add("All")
                                $comboBox1.Items.add("Running")
                                $comboBox1.Items.add("Stopped")
                                pbstart "Get WAWS List"
                                $WAWSlist=GetWAWSList
                                pbstart "Adding to List"
                                foreach($WAWSName in $WAWSlist)
                                {
                                  $comboBox1.Items.add($WAWSName)
                                }
                                pbstop
                                
                                if($comboBox1.items.count -gt 3)
                                {
                                   
                                    $comboBox1.SelectedIndex = 3
                                }                          
                            })
        $Form.Controls.Add($WAWSButton)


        $SignInFunctionCheckBox = New-Object System.Windows.Forms.CheckBox
        $SignInFunctionCheckBox.Text = "Include SignIn Function"
        $SignInFunctionCheckBox.AutoSize = $True
        $SignInFunctionCheckBox.Location = New-Object System.Drawing.Size(20,130)
        $Form.Controls.Add($SignInFunctionCheckBox)

        $CheckVersionCheckBox = New-Object System.Windows.Forms.CheckBox
        $CheckVersionCheckBox.Text = "Include Module Check"
        $CheckVersionCheckBox.AutoSize = $True
        $CheckVersionCheckBox.Location = New-Object System.Drawing.Size(20,150)
        $Form.Controls.Add($CheckVersionCheckBox)

        $CodeButton = New-Object System.Windows.Forms.Button
        $CodeButton.Location = New-Object System.Drawing.Size(200,130)
        $CodeButton.AutoSize = $True
        $CodeButton.Text = "AutoScript"
        $CodeButton.Add_Click({
                                  $richTextBox1.Text=  GenerateWAWSQueryCode   $SignInFunctionCheckBox.Checked $CheckVersionCheckBox.Checked $comboBox1.Text
                            })
        $Form.Controls.Add($CodeButton)

        $richTextBox1 = New-Object System.Windows.Forms.RichTextBox
        $richTextBox1.Text = ""
        $richTextBox1.Width = 390
        $richTextBox1.Height = 240
        $richTextBox1.Location = New-Object System.Drawing.Size(20,170)

        $Form.Controls.Add($richTextBox1)

        $OKButton = New-Object System.Windows.Forms.Button
        $OKButton.Location = New-Object System.Drawing.Size(130,420)

        $OKButton.Size = New-Object System.Drawing.Size(75,23)
        $OKButton.Text = "Quit"
        $OKButton.Add_Click({$Form.Close()})
        $Form.Controls.Add($OKButton)

        $InsertButton = New-Object System.Windows.Forms.Button

        $InsertButton.Location = New-Object System.Drawing.Size(20,420)
        $InsertButton.Size = New-Object System.Drawing.Size(100,23)
        $InsertButton.Text = "Insert Script"
        $InsertButton.Add_Click({$psise.CurrentFile.Editor.InsertText($richTextBox1.Text)})
        $Form.Controls.Add($InsertButton)

        $RunButton = New-Object System.Windows.Forms.Button

        $RunButton.Location = New-Object System.Drawing.Size(215,420)
        $RunButton.Size = New-Object System.Drawing.Size(75,23)
        $RunButton.Text = "Run"
        $RunButton.Add_Click({
        pbstart "Execute AutoScripted Code"
        $Label4.Text = "Starting"
        Invoke-Expression -Command $richTextBox1.Text|Out-Host
        $Label4.Text = "Finish"
        pbstop
        })
        $Form.Controls.Add($RunButton)

        $Label4 = New-Object System.Windows.Forms.Label
        $Label4.AutoSize = $False
        $Label4.Size = New-Object System.Drawing.Size(200,23)
        $Label4.Location = New-Object System.Drawing.Size(20,450)
        $Label4.Text = "Status"
        $Form.Controls.Add($Label4)

        $Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")

        $Form.Icon = $Icon

        $Form.AutoSize = $True
        $Form.StartPosition = "CenterScreen"
        $Form.ShowDialog()

}

#AZure WAWS AutoScript Initialize
Function AZureWAWSASInitialize
{
  ImportAzureModules
  CheckAZurePSVersion
}

Function AZureWAWSASLaunchMain
{
    AZureWAWSASInitialize
    AZureWAWSASLaunchForm |out-Null
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("AZure AutoScript", `
{AZureWAWSASLaunchMain},"ALT+F5") | out-Null

 