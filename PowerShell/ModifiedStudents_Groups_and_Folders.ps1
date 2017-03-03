## MIM - Modified Students - Move HomeFolders and Update Security Groups
## Jordan Stoner
## jordanstoner@gmail.com
## 02/29/2016
##
## This script works to update modified student security groups and move
## their HomeFolder if their Division changed

Import-Module ActiveDirectory
Import-Module NTFSSecurity

$students = Import-CSV "E:\StudentFiles\ModifiedStudents.csv"

$outFile = "E:\OutputFiles\ModifiedStudents.csv"

Try{
Remove-Item $outFile -Force
}

Catch{
}

Add-Content $outFile "Student, Item, Action, Result"

foreach ($student in $students)
{

    $studentAD = Get-ADUser $student.Student_Number

    if ($student.NewSchool -ne $student.OldSchool)
    {
        Try {
        Remove-ADGroupMember "$($student.OldSchool) Student Group" $studentAD -Confirm:$false
        Add-Content $outFile "$($student.Student_Number),$($student.OldSchool) Student Group,Remove Group,Success"
        }

        Catch {
        Add-Content $outFile "$($student.Student_Number),$($student.OldSchool) Student Group,Remove Group,Failed"
        }

        Try {
        Add-ADGroupMember "$($student.NewSchool) Student Group" $studentAD
        Add-Content $outFile "$($student.Student_Number),$($student.NewSchool) Student Group,Add Group,Success"
        }

        Catch {
        Add-Content $outFile "$($student.Student_Number),$($student.NewSchool) Student Group,Add Group,Failed"
        }
    }

    if ($student.NewDivision -ne $student.OldDivision)
    {
        Try {
        Remove-ADGroupMember "$($student.OldDivision)" $studentAD -Confirm:$false
        Add-Content $outFile "$($student.Student_Number),$($student.OldDivision),Remove Group,Success"
        }

        Catch {
        Add-Content $outFile "$($student.Student_Number),$($student.OldDivision),Remove Group,Failed"
        }

        Try {
        Add-ADGroupMember "$($student.NewDivision)" $studentAD
        Add-Content $outFile "$($student.Student_Number),$($student.NewDivision),Add Group,Success"
        }

        Catch {
        Add-Content $outFile "$($student.Student_Number),$($student.NewDivision),Add Group,Failed"
        }
    }

    if ($student.NewHome -ne $student.OldHome)
    {
        $newHomeExists = Test-Path "$($student.NewHome)"
        $oldHomeExists = Test-Path "$($student.OldHome)"

        if (-not $newHomeExists)
        {
            $homePath = $student.NewHome
            $serverPath = $homePath.Substring(0,$homePath.Length-7)

            try{
            New-Item -Path $serverPath -Name $student.Student_Number -ItemType Directory
            Add-NTFSAccess -Path $homePath -Account "foo\$($student.Student_Number)" -AccessRights FullControl 
            
            Add-Content $outFile "$($student.Student_Number),$($student.NewHome),Create New Home,Success"
            }

            catch{
            Add-Content $outFile "$($student.Student_Number),$($student.NewHome),Create New Home,Failed"
            }
        }

        if ($oldHomeExists)
        {

            $homePath = $student.NewHome
            $serverPath = $homePath.Substring(0,$homePath.Length-7)
            
            try{
            TAKEOWN /F $student.OldHome /R /D Y
            Copy-Item -Path $student.OldHome -Destination $serverPath -Recurse -ErrorAction SilentlyContinue
            Add-NTFSAccess -Path $student.NewHome -Account "foo\$($student.Student_Number)" -AccessRights FullControl
            Add-Content $outFile "$($student.Student_Number),$($student.OldHome),Copied Old Home,Success"
            Remove-Item -Path $student.OldHome -Recurse -Force
            }

            catch{
            Add-Content $outFile "$($student.Student_Number),$($student.OldHome),Copied Old Home,Failed"
            }

        }

    }

}
