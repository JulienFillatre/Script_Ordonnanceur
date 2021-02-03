
#$nomsql = Read-Host "Entrez le nom du serveur SQL"
$nomsql = 'SQL Server (SQL2019TEST)'
Write-Output $nomsql
#$nomnoeud1 = Read-Host "Entrez le nom du noeud 1"
$nomnoeud1 = 'SLHTESTDBT01'
Write-Output $nomnoeud1
#$nomnoeud2 = Read-Host "Entrez le nom du noeud 2"
$nomnoeud2 = 'SLHTESTDBT02'
Write-Output $nomnoeud2
$testmaj = $true

#Start-Sleep -Seconds 2

#Invoke-Command -ComputerName $nomnoeud2 -ScriptBlock {gpupdate /target:computer}

$s = new-pssession -computername $nomnoeud2 #session créée sur le noeud 2
$sql = Invoke-Command -Session $s -ScriptBlock {Get-ClusterGroup -Name $Using:nomsql}
$noeud1 = Invoke-Command -Session $s -ScriptBlock {Get-ClusterNode -Name $Using:nomnoeud1}
$noeud2 = Invoke-Command -Session $s -ScriptBlock {Get-ClusterNode -Name $Using:nomnoeud2}
Write-Output $sql
Write-Output $sql.State
Write-Output $noeud1
Write-Output $noeud1.State
Write-Output $noeud2
Write-Output $noeud2.State




#Get-ClusterGroup 'SQL Server (SQL2019TEST)'


if($sql.state -eq "Online" ) #si le serveur sql tourne
{
Write-Output "Le service SQL est en cours d'execution `n"
    if ($sql.OwnerNode -eq $nomnoeud2)#si le serveur sql tourne sur le noeud 2
    {
        
        Write-Output "Le serveur SQL va s'éteindre et passer sur $nomnoeud1 `n"
        Invoke-Command -Session $s -ScriptBlock {Move-ClusterGroup -Name $Using:nomsql -Node $Using:nomnoeud1}# déplace le serveur sql sur le noeud 1

            do{
                Start-Sleep -Milliseconds 200 #vérification toutes les 200ms
                $sql1 = Invoke-Command -Session $s -ScriptBlock {Get-ClusterGroup -Name $Using:nomsql}
                }until ($sql1.OwnerNode -eq $nomnoeud1 -And $sql1.State -eq "Online")
             Write-Output "Le serveur SQL est maintenant en ligne sur $nomnoeud1 `n"

     }
     else #si le serveur sql est déjà sur le noeud 1
     {
     Write-Output "Le serveur SQL est déjà sur $nomnoeud1 `n"
     }
}
else 
{
	Write-Output "Le serveur n'est pas en cours d'execution `n"
}  

#if(Get-WUIsPendingReboot)
if($testmaj)
{
Write-Output "Mise a jour, l'ordinateur va redemarrer `n"
#Invoke-Command -ComputerName $nomnoeud2 -ScriptBlock {Restart-Computer -Force -Wait } #force pour obliger le redémarrage quand un utilisateur est co dessus
Restart-Computer -ComputerName $nomnoeud2 -Force -Wait -For PowerShell

}
else
{
Write-Output "Pas de mise à jour `n"
}

