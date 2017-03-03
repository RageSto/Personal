## Security Video Cleanup
## 07/12/2016
## Jordan Stoner
## jordanstoner@gmail.com
#
#
## This script takes in a list of filenames which should be retained (Video_Do_Not_Delete.csv), scans each
## security video archive directory for all video files older than 30 days and deletes them if they are not
## listed in the Video_Do_Not_Delete.csv file.  It then outputs a list of the deleted files, their directory,
## and file size in MB to a CSV file

$dontDelete = Import-Csv C:\1-Misc\Video_Do_Not_Delete.csv

$today = Get-Date

$outputFile = "C:\1-Misc\VideoDeleted-$($today.Day)-$($today.Month)-$($today.Year)-$($today.Hour)-$($today.Minute).csv"

Add-Content $outputFile "Archiver,Folder,File,Result"

$achivers = @("1","2","3","4","5","6","7","8","9")

foreach ($archiver in $achivers)
{
    $arch = $null

    $arch = Get-ChildItem "\\foo.bar.foo\archiver$($archiver)\VideoArchives\arch$($archiver)" -File -Recurse | Where {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Select `
    Name,Directory, @{Name="Mbytes";Expression={$_.Length / 1MB}} | Sort Directory

    Foreach ($video in $arch)
    {
    if ($dontDelete.FileName -notcontains $video.Name)
        {
            Try
            {
                Remove-Item "$($video.Directory)\$($video.Name)" -Force -Verbose
                Add-Content $outputFile "Archiver$($archiver),$($video.Directory),$($video.Name),Success,$($video.Mbytes)"
            }

            Catch
            {
                Add-Content $outputFile "Archiver$($archiver),$($video.Directory),$($video.Name),Failed,$($video.Mbytes)"
            }
        }
    }
}

