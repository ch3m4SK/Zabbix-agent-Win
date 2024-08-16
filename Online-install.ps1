$version500ssl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.0/zabbix_agent-7.0.0-windows-amd64-openssl.zip"



#Gets the server host name
$serverHostname =  Invoke-Command -ScriptBlock {hostname}


# Asks the user for the IP address of their Zabbix server
$ServerIP = Read-Host -Prompt 'What is your Zabbix server/proxy IP?'
$Equipment = Read-Host -Prompt 'Que equipo quieres registrar?'

# Creates Zabbix DIR
mkdir c:\zabbix


# Downloads the version you want. Links are up. This script currently as standard downloads version 7.0.0 with SSL option
Invoke-WebRequest "$version500ssl" -outfile c:\zabbix\zabbix.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Unzipping file to c:\zabbix
Unzip "c:\Zabbix\zabbix.zip" "c:\zabbix"      

# Sorts files in c:\zabbix
Move-Item c:\zabbix\bin\zabbix_agentd.exe -Destination c:\zabbix

# Sorts files in c:\zabbix
Move-Item c:\zabbix\conf\zabbix_agentd.conf -Destination c:\zabbix

#Rename the original .conf file
Rename-Item -Path "C:\zabbix\zabbix_agentd.conf" -NewName "zabbix_agentd.default.conf"

#Move the modified config file
Move-Item ./zabbix_agentd.conf -Destination c:\zabbix

# Replaces 127.0.0.1 with your Zabbix server IP in the config file
(Get-Content -Path c:\zabbix\zabbix_agentd.conf) | ForEach-Object {$_ -Replace '127.0.0.1', "$ServerIP"} | Set-Content -Path c:\zabbix\zabbix_agentd.conf

# Add host metadata for autoregistration
(Get-Content -Path c:\zabbix\zabbix_agentd.conf) | ForEach-Object {$_ -Replace '# HostMetadata=', "HostMetadata=$Equipment"} | Set-Content -Path c:\zabbix\zabbix_agentd.conf

# Replaces hostname in the config file
(Get-Content -Path c:\zabbix\zabbix_agentd.conf) | ForEach-Object {$_ -Replace 'Windows host', "$ServerHostname"} | Set-Content -Path c:\zabbix\zabbix_agentd.conf

# Attempts to install the agent with the config in c:\zabbix
c:\zabbix\zabbix_agentd.exe --config c:\zabbix\zabbix_agentd.conf --install

# Attempts to start the agent
c:\zabbix\zabbix_agentd.exe --start

# Creates a firewall rule for the Zabbix server
New-NetFirewallRule -DisplayName "Allow Zabbix communication" -Direction Inbound -Program "c:\zabbix\zabbix_agentd.exe" -RemoteAddress LocalSubnet -Action Allow

# Permit 1433 TCP for SQL
New-NetFirewallRule -Name "Allow SQL Server" -DisplayName "Allow SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow