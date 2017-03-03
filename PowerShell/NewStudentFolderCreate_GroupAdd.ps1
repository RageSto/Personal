## MIM - New Students - Create Home Folder and Add to Groups
## Jordan Stoner
## jordanstoner@gmail.com
## 12/03/2015
##
## This script assists in the student account creation process by handling Home Folder creation and Security Group placement for new students.

Import-Module ActiveDirectory
Import-Module NTFSSecurity

$students = Import-Csv 'E:\StudentFiles\NewStudents.csv'

$outFile = "E:\OutputFiles\NewStudents.csv"

Try{
Remove-Item $outFile -Force
}

Catch{
}

Add-Content $outFile "Student,Item,Action,Result"



# Create folder and set permission for each new student with a valid HomeFolder path
Foreach ($student in $students)
{
    if ($student.HomePath -ne "No Home")
    {
        if (Get-ADUser $($student.Student_Number))
            {

            $homePath = $student.HomePath
            $serverPath = $homePath.Substring(0,$homePath.Length-7)

            Try{
                New-Item -Path $serverPath -Name $student.Student_Number -ItemType Directory -ErrorAction Continue
                Add-NTFSAccess -Path $homePath -Account "foo\$($student.Student_Number)" -AccessRights FullControl
                #Add ownership based on SID?
                Add-Content $outFile "$($student.Student_Number),$($homePath),Create Home,Success"
                }

            Catch{
                Add-Content $outFile "$($student.Student_Number),$($homePath),Create Home,Failed"                
                }
            }
        else
        {
            Add-Content $outFile "$($student.Student_Number),$($homePath),Create Home,Failed (No AD)"
        }
    }
}

# Add each new student to proper groups
Foreach ($student in $students)
{
    if (Get-ADUser $($student.Student_Number))
        {
        $currentStudent = Get-ADUser $student.Student_Number -Verbose
    
        Write-Output "--Adding $($student.Student_Number)--"

        # Add to Division student group
        Try{
        Add-ADGroupMember $student.Division $currentStudent -Verbose
        Add-Content $outFile "$($student.Student_Number),$($student.Division) Group,Add Group,Success"
            }

        Catch{
            $groupError = $true
            Add-Content $outFile "$($student.Student_Number),$($student.Division) Group,Add Group,Failed"
            }

        # Add to School student group
        Try{
        Add-ADGroupMember "$($student.StuOUSchool) Student Group" $currentStudent -Verbose
        Add-Content $outFile "$($student.Student_Number),$($student.StuOUSchool) Student Group,Add Group,Success"
            }

        Catch{
            $groupError = $true
            Add-Content $outFile "$($student.Student_Number),$($student.StuOUSchool) Student Group,Add Group,Failed"
            }

        #Add to Student 8e6 group
        Try{
        Add-ADGroupMember "Student 8e6" $currentStudent -Verbose
        Add-Content $outFile "$($student.Student_Number),Student 8e6 Group,Add Group,Success"
            }

        Catch{
            $groupError = $true
            Add-Content $outFile "$($student.Student_Number),Student 8e6 Group,Add Group,Failed"
            }

        # Add to Raytown C-2 Students group
        Try{
        Add-ADGroupMember "Foo Students" $currentStudent -Verbose
        Add-Content $outFile "$($student.Student_Number),Foo Students Group,Add Group,Success"
            }
    
        Catch{
            $groupError = $true
            Add-Content $outFile "$($student.Student_Number),Foo Students Group,Add Group,Failed"
            }

        # Update dbo.Students_to_AD to mark Y in SecGroup for each student if successful
        If(-not $groupError)
        {
            $sqlCommand = "UPDATE PSStuReconcile.dbo.Students_To_AD SET SecGroup='Y' WHERE Student_Number='$($student.Student_Number)'"
            Invoke-Sqlcmd -query $sqlCommand -ServerInstance "FIM-SQL\ACCTCREATIONS"
        }
    }
}

