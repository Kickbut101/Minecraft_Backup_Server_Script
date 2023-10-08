## Backup Minecraft files/world with frequency options
## 1.1
## 12-3-20

$mineCraftDir = "C:\minecraft\Andy_Server\Paper"
$backupDirName = "World-Backups"
$silence = mkdir -force "$backupDirName"
$worldFolderNamesList = (Get-ChildItem -Path "$($mineCraftDir)" -Recurse -Include "Level.dat").Directoryname
$saveParameters = @{
    Daily = "1" # How many daily backups to keep
    Weekly = "1" # How many weekly backups to keep
    Monthly = "1" # How many monthly backups to keep
}

function makeBackup
    {
        param($mineCraftDir,$backupDirName,$backupType,$backupDateString)
            $DestinationPath = "$($mineCraftDir)\$($backupDirName)\$($backupType) - $($backupDateString).zip"
            Compress-Archive -Path $worldFolderNamesList -CompressionLevel Fastest -DestinationPath $DestinationPath -Force
    }

function manageAndCalculateBackups
    {
        param($saveParameters,$mineCraftDir,$backupDirName)
        $today = (Get-Date)
        $todayAsFormattedString = (Get-Date -Format MM-dd-yy).tostring()
        $stringListOfBackups = (Get-ChildItem -Path "$mineCraftDir\$backupDirName" -File).name | Out-string
        $dataAboutAllBackupFiles = $stringListOfBackups | Select-String -AllMatches -Pattern "(?<Frequency>[a-zA-Z]+).*?\-.*?(?<Timestamp>\d{1,2}\-\d{1,2}\-\d{1,4})"

        # Check for monthly
        if (($dataAboutAllBackupFiles.matches | Where {$_.groups.value -eq 'Monthly'}).count -lt 1) # Is this first backup? Or has monthly been deleted?
            {makeBackup -mineCraftDir $mineCraftDir -backupDirName $backupDirName -backupType 'Monthly' -backupDateString "$todayAsFormattedString"}
        # At least one backup for monthly? Check to see if we need to make new one based on monthly saved parameters multipied by 28 days (a month-ish)
        Else
            {
                foreach ($monthlyMatch in ($dataAboutAllBackupFiles.matches | Where {$_.groups.value -eq 'Monthly'}))
                    {
                        # Check if parameters are met
                        if (([datetime]::ParseExact("$((($monthlyMatch | Where {$_.groups.value -eq 'Monthly'}).groups | where {$_.name -eq 'Timestamp'}).value)",'MM-dd-yy',$null)).adddays(28*$($saveParameters.Monthly)) -lt $today)
                            {
                                makeBackup -mineCraftDir $mineCraftDir -backupDirName $backupDirName -backupType 'Monthly' -backupDateString "$todayAsFormattedString"
                                Remove-Item -Force -LiteralPath "$($mineCraftDir)\$($backupDirName)\Monthly - $((($monthlyMatch | Where {$_.groups.value -eq 'Monthly'}).groups | where {$_.name -eq 'Timestamp'}).value).zip" -ErrorAction SilentlyContinue
                            }
                    } # Monthly foreach end
            } # Monthly Else end

        # Check for Weekly
        if (($dataAboutAllBackupFiles.matches | Where {$_.groups.value -eq 'Weekly'}).count -lt 1) # Is this first backup? Or has weekly been deleted?
            {makeBackup -mineCraftDir $mineCraftDir -backupDirName $backupDirName -backupType 'Weekly' -backupDateString "$todayAsFormattedString"}
        # At least one backup for weekly? Check to see if we need to make new one based on weekly saved parameters multipied by 7 days
        Else
            {
                foreach ($weeklyMatch in ($dataAboutAllBackupFiles.matches | Where {$_.groups.value -eq 'Weekly'}))
                    {
                        # Check if parameters are met
                        if (([datetime]::ParseExact("$((($weeklyMatch | Where {$_.groups.value -eq 'Weekly'}).groups | where {$_.name -eq 'Timestamp'}).value)",'MM-dd-yy',$Null)).adddays(7*$($saveParameters.Weekly)) -lt $today)
                            {
                                makeBackup -mineCraftDir $mineCraftDir -backupDirName $backupDirName -backupType 'Weekly' -backupDateString "$todayAsFormattedString"
                                Remove-Item -Force -LiteralPath "$($mineCraftDir)\$($backupDirName)\Weekly - $((($weeklyMatch | Where {$_.groups.value -eq 'Weekly'}).groups | where {$_.name -eq 'Timestamp'}).value).zip" -ErrorAction SilentlyContinue
                            }
                    } # Weekly foreach end
            } # Weekly Else end

        # Check for Daily
        if (($dataAboutAllBackupFiles.matches | Where {$_.groups.value -eq 'Daily'}).count -lt 1) # Is this first backup? Or has Daily been deleted?
            {makeBackup -mineCraftDir $mineCraftDir -backupDirName $backupDirName -backupType 'Daily' -backupDateString "$todayAsFormattedString"}
        # At least one backup for Daily? Check to see if we need to make new one based on Daily saved parameters multipied by 1 day
        Else
            {
                foreach ($DailyMatch in ($dataAboutAllBackupFiles.matches | Where {$_.groups.value -eq 'Daily'}))
                    {
                        # Check if parameters are met
                        if (([datetime]::ParseExact("$((($DailyMatch | Where {$_.groups.value -eq 'Daily'}).groups | where {$_.name -eq 'Timestamp'}).value)",'MM-dd-yy',$Null)).adddays(1*$($saveParameters.Daily)) -lt $today)
                            {
                                makeBackup -mineCraftDir $mineCraftDir -backupDirName $backupDirName -backupType 'Daily' -backupDateString "$todayAsFormattedString"
                                Remove-Item -Force -LiteralPath "$($mineCraftDir)\$($backupDirName)\Daily - $((($DailyMatch | Where {$_.groups.value -eq 'Daily'}).groups | where {$_.name -eq 'Timestamp'}).value).zip" -ErrorAction SilentlyContinue
                            }
                    } # Daily foreach end
            } # Daily Else end
    }


manageAndCalculateBackups -saveParameters $saveParameters -mineCraftDir $mineCraftDir -backupDirName $backupDirName