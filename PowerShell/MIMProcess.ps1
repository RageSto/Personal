## MIM Process Script
## 02/11/2016
## Jordan Stoner
## jordanstoner@gmail.com
#
#
## This script takes care of running MIM, running the various folder creation, group managment PowerShell scripts, and emailing the final report
## Because Microsoft's version control between SQL, Visual Studio, and SSDT sucks.

# Initialize Variables
$mimError = $null
$newStudentsError = $null
$existingStudentsError = $null
$returningStudentsError = $null
$accountsCreated = 0


# Delete Previous Report CSV's
Remove-Item E:\OutputFiles\*.csv -Force 

# Execute MIM Management Agent Run Profiles
<#Try{
    Start-Process -FilePath C:\PsExec.exe -ArgumentList "\\FIM\ C:\MIMFiles\run_MIM_provisioning.cmd"
    #&C:\PsExec.exe \\FIM\ C:\MIMFiles\run_MIM_provisioning.cmd
    }

Catch{
    $mimError = $true
    }
    #>

Start-Sleep -s 600 #10 minutes

# Execute New Student Folder and Group Add Script

if ($mimError -ne $true)
{
    Try{
    Invoke-Expression -Command "& ""E:\Powershell Scripts\NewStudentFolderCreate_GroupAdd.ps1"""
    }
    

    Catch{
    $newStudentsError = $true
    }
}


# Execute Existing Student Group Modify Script
try{
Invoke-Expression -Command "& ""E:\Powershell Scripts\ModifiedStudents_Groups_and_Folders.ps1"""
}

catch{
$modifiedStudentsError = $true
}


# Email Report
if (($mimError -eq $true) -or ($newStudentsError -eq $true) -or ($modifiedStudentsError -eq $true))
{
    $errorLevel = "FAILED"
}

else{
    $errorLevel = "SUCCEEDED"
    }

# Determine Accounts Created
$newStudents = Import-Csv 'E:\StudentFiles\NewStudents.csv'

foreach ($student in $newStudents)
{

    if (Get-ADUser $($student.Student_Number))
        {
        $accountsCreated = $accountsCreated + 1
        }
}

# Delete Original StudentFiles
Remove-Item E:\StudentFiles\*.csv -Force

$accounts = $null

$newStudentFile = "E:\OutputFiles\NewStudents.csv"
$modifiedStudentFile = "E:\OutputFiles\ModifiedStudents.csv"

$emailTo = "serverteam@foo.bar"
$emailFrom = "Student_MIM@foo.bar"
$emailSubject = "$($errorLevel): Student Account Provisioning"
$emailBody = "The student account provisioning process $($errorLevel). $($accountsCreated) accounts were created.  Output files are attached. `r`n MIM error is $($mimError) `r`n New Student error is $($newStudentsError) `r`n Modified Students error is $($modifiedStudentsError)"
$emailSMTP = "smtp.foo.bar"
$emailAttach = $newStudentFile,$modifiedStudentFile


Send-MailMessage -To $emailTo -From $emailFrom -Subject $emailSubject -Body $emailBody -SmtpServer $emailSMTP -Attachments $emailAttach
