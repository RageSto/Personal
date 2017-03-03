## Teacher & Staff Password Reset
## Jordan Stoner
## 09/03/2015
##
## This script will query AD for Staff and Teacher accounts, excluding Disabled accounts.  You can specify OU's
## to exclude from the reset as well as specific users to exclude by adding their SamAccountName to C:\PasswordResetExcludes.csv.
## It will then set the "Change Password at Login" attribute for each AD account it is fed.
##===============================================================================================================

Start-Transcript "C:\Password Reset\StaffPasswordReset.log"

Import-Module ActiveDirectory

# User exclusion CSV file
$excludedUsers = @(Import-Csv 'C:\Password Reset\PasswordResetExcludes.csv')

# Confirmation output file
$outputFile = "C:\Password Reset\ADResetOutput.csv"

# Headers for Output file
Add-Content $outputFile "Status,SamAccountName,CanonicalName,Staff#,Mail"

# OU's to exclude from AD search
$exclusion1 = "*OU=Genetec All-In-Ones,OU=Technology,OU=Staff,OU=User Accounts,DC=rqs,DC=c2"
$exclusion2 = "*OU=Google Plus,OU=Technology,OU=Staff,OU=User Accounts,DC=rqs,DC=c2"
$exclusion3 = "*OU=FIM,OU=Staff,OU=User Accounts,DC=rqs,DC=c2"
$exclusion4 = "*OU=School Board,OU=Staff,OU=User Accounts,DC=rqs,DC=c2"

#AD Properties to Pull into CSV
$ADPropSelect = @("SamAccountName","DisplayName","Department","DistinguishedName","CanonicalName","Title","PasswordLastSet","Enabled","extensionAttribute11","LastLogonDate","logonCount","mail")

##-----------------------------------------------------------------------

# Pulls from Staff OU minus exclusions from above
$staffAD = Get-ADUser -Filter {(Enabled -eq $true)} -SearchBase "OU=Staff,OU=User Accounts,DC=foo,DC=bar" -Properties $ADPropSelect | Where-Object {($_.DistinguishedName -notlike $exclusion1) `
            -and ($_.DistinguishedName -notlike $exclusion2) -and ($_.DistinguishedName -notlike $exclusion3) -and ($_.DistinguishedName -notlike $exclusion4)} | Select $ADPropSelect

# Pulls from Teacher OU
$teacherAD = Get-ADUser -Filter {(Enabled -eq $true)} -SearchBase "OU=Teachers,OU=User Accounts,DC=foo,DC=bar" -Properties $ADPropSelect | Select $ADPropSelect

# Combines the AD pulls
$allStaff = $staffAD + $teacherAD

# Exports the combined AD pull to a CSV
$allStaff | Export-Csv C:\users\rqsad\PasswordReset_10_2015\AllStaffAD_PasswordReset.csv -NoTypeInformation

##------------------------------------------------------------------------

# Combs through each account that was pulled
foreach ($account in $allStaff)
{
    # If the exclusion list contains the incoming account's SamAccountName
    if ($excludedUsers.SamAccountName -contains $account.SamAccountName.ToLower())
    {
        # Does nothing and notes the account as excluded in the output file
        Write-Host "$($account.SamAccountName) -- $($account.DisplayName) excluded."
        $result = "Excluded"
    }

    else
    {
        # Enables ChangePasswordAtLogon for the account and notes it in the output file
        Try 
        {
            Set-ADUser -Identity $account.SamAccountName -ChangePasswordAtLogon $true

            Write-Host "$($account.SamAccountName) -- $($account.DisplayName) password reset."
            $result = "Reset"
        }

        # If an error is reached trying to set the ChangePasswordAtLogon option
        Catch
        {
            Write-Host "$($account.SamAccountName) -- $($account.DisplayName) failed to set password change."
            $result = "Failed"
        }
        
    }

    Add-Content $outputFile "$($result),$($account.SamAccountName),$($account.CanonicalName),$($account.extensionAttribute11),$($account.mail)"
}



Stop-Transcript
