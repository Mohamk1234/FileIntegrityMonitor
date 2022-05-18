write-Host ""
write-Host "what would you like to do?"
Write-Host ""
write-Host "A) Collect new Baseline?"
write-Host "B) Begin monitoring files with saved Baseline and create new if it doesn't exist"
write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
write-Host ""
$userpath = Read-Host -Prompt "Enter the disc name or the path of the directory that you wish to monitor" 
$userPathExists = Test-Path -Path $userpath

if(!$userPathExists){
    Write-Host "The path provided does not exist" -BackgroundColor White -ForegroundColor Red
    Write-Host "Make sure you specify disc as `"D:\`" " -BackgroundColor White -ForegroundColor Red
    return
}



Function CalculateFileHash($filepath){
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}


Function EraseBaselineIfAlreadyExists(){
    $baselineExists = Test-Path -Path $userpath/baseline.txt
    if($baselineExists){
        Remove-Item -Path $userpath/baseline.txt
    }
}

Function CreateBaseline(){
    EraseBaselineIfAlreadyExists
    Write-Host "Compute Hases, make new baseline.txt" -ForegroundColor Cyan
    $files = Get-ChildItem -Recurse -File -Path $userpath
    foreach ($f in $files){
       $hash = CalculateFileHash $f.FullName
       "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath $userpath\baseline.txt -Append
    }
}


if($response -eq "A".ToUpper()){
    CreateBaseline
}

elseif($response -eq "B".ToUpper()){
    $fileHashDictionary = @{}

    $baselineExists = Test-Path -Path $userpath\baseline.txt

    if(!$baselineExists){
        #call function to create the baseline
        CreateBaseline
        Write-Host "Creating baseline.txt as the file does not exist" -BackgroundColor White -ForegroundColor Red
    }

    $filePathsAndHashes = Get-Content -Path $userpath\baseline.txt

    foreach($f in $filePathsAndHashes){
        $fileHashDictionary.add($f.split("|")[0],$f.split("|")[1])
        
    }

    

    while($true){
        
 

        $files = Get-ChildItem -File -Recurse -Path $userpath

        

        foreach ($f in $files){

            if($f.FullName -eq $userpath+"\baseline.txt"){
                continue
            }

          
            $hash = CalculateFileHash $f.FullName


            if($fileHashDictionary[$hash.Path] -eq $null){
                #A file has been created ! Notify the user
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
    
            }
            else{
                  if($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                        #the file remains the same
                    }
                  else{
                        #file has changed
                        Write-Host "$($hash.Path) has changed! " -ForegroundColor yellow
                    }
            }
          

        }

        foreach ($key in $fileHashDictionary.Keys){
            $baselineFileStillExists = Test-Path -Path $key
            if(!$baselineFileStillExists){
                Write-Host "$($key) has been deleted" -ForegroundColor Red
             
            }
        }

        Start-Sleep -Seconds 5

    }

    Write-Host "Read existing baseline.txt, start monitoring files" -ForegroundColor Cyan
}
else{
    Write-Host -BackgroundColor White -ForegroundColor Black "Please enter 'A' or 'B'"
}