%{ if system_type == "linux" }#!/bin/bash -x %{ endif } 
%{ if system_type == "linux" }
exec > /tmp/terraform_bootstrap_script.log 2>&1

function set_tmp_path() {
  if [[ ! -d ${tmp_path} ]]; then
    mkdir -p ${tmp_path}
  fi
}

function install_azure_agent() {
  pushd /home/${user_name}
  mkdir agent
  pushd agent

  #AGENTRELEASE="$(curl -s https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest | grep -oP '"tag_name": "v\K(.*)(?=")')"
  AGENTRELEASE="${azure_agent_version}"
  AGENTURL="https://vstsagentpackage.azureedge.net/agent/$${AGENTRELEASE}/vsts-agent-linux-x64-$${AGENTRELEASE}.tar.gz"
  echo "Release "$${AGENTRELEASE}" appears to be latest" 
  echo "Downloading..."
  wget -O agent.tar.gz $AGENTURL
  tar zxvf agent.tar.gz
  chmod -R 777 .
  echo "extracted"
  ./bin/installdependencies.sh
  echo "dependencies installed"
  sudo -u ${user_name} ./config.sh --unattended --url https://dev.azure.com/${azure_agent_org} --auth pat --token ${azure_agent_pat} --pool ${azure_agent_pool} --agent $(hostname -i|sed 's/\./-/g') --acceptTeeEula --work ./_work --runAsService
  echo "configuration done"
  ./svc.sh install
  echo "service installed"
  ./svc.sh start
  echo "service started"
  echo "config done"

  sudo debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
  sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
  sudo apt-get install --assume-yes postfix
  systemctl enable postfix --now 

  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  
    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"
    sudo apt-get update -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
    sudo usermod -a -G docker ${user_name}
    sudo systemctl enable docker --now
    curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash 
    sudo apt-get install jq -y
  popd
  popd
}

function install_chef() {
  echo "nslookup"
  nslookup ${chef_product_install_url}
  echo "ping"
  ping www.chef.io -c 5
  echo "sleeping for 60s"
  sleep 60
  echo "nslookup"
  nslookup ${chef_product_install_url}
  echo "ping"
  ping www.chef.io -c 5
  if ! hash curl; then
    wget -O ${tmp_path}/install.sh ${chef_product_install_url}
  else
    curl -L -o ${tmp_path}/install.sh ${chef_product_install_url}
  fi
  bash ${tmp_path}/install.sh -P $${1} -v $${2}
  case $${1} in
    inspec)
      echo "export PATH=\"$${PATH}:/opt/chef/bin:/opt/chef/embedded/bin\"" >> /root/.bash_profile
      echo "export PATH=\"$${PATH}:/opt/chef/bin:/opt/chef/embedded/bin\"" >> /home/${user_name}/.bash_profile
      ;;
    chef-workstation)
      echo "export PATH=\"$${PATH}:/opt/chef-workstation/bin:/opt/chef-workstation/embedded/bin:/opt/chef-workstation/gitbin/\"" >> /root/.bash_profile
      echo "export PATH=\"$${PATH}:/opt/chef-workstation/bin:/opt/chef-workstation/embedded/bin:/opt/chef-workstation/gitbin/\"" >> /home/${user_name}/.bash_profile
      ;;
    chefdk)
      echo "export PATH=\"$${PATH}:/opt/chefdk/bin:/opt/chefdk/embedded/bin:/opt/chefdk/gitbin/\"" >> /root/.bash_profile
      echo "export PATH=\"$${PATH}:/opt/chefdk/bin:/opt/chefdk/embedded/bin:/opt/chefdk/gitbin/\"" >> /home/${user_name}/.bash_profile
      ;;
    inspec)
      echo "export PATH=\"$${PATH}:/opt/inspec/bin:/opt/inspec/embedded/bin\"" >> /root/.bash_profile
      echo "export PATH=\"$${PATH}:/opt/inspec/bin:/opt/inspec/embedded/bin\"" >> /home/${user_name}/.bash_profile
      ;;

  esac
}

function install_hab() {
  if ! hash curl; then
    wget -O ${tmp_path}/install_hab.sh ${hab_install_url}
  else
    curl -L -o ${tmp_path}/install_hab.sh ${hab_install_url}
  fi
  if [[ "$${1}" == "latest" ]]; then
    bash ${tmp_path}/install_hab.sh
  else
    bash ${tmp_path}/install_hab.sh -v $${1}
  fi
  hab license accept
  su - ${user_name} -c 'hab license accept'
}

%{ if set_hostname }
DOM=$(awk '/search/{print $2}' /etc/resolv.conf)
%{ if ip_hostname }
HNAME="${hostname}-$(hostname -i | sed 's/\./-/g').$${DOM}"
%{ else }
HNAME="${hostname}.$${DOM}"
%{ endif }
if hash hostnamectl &>/dev/null; then
  hostnamectl set-hostname $${HNAME}
fi
%{ endif }

%{ if install_workstation_tools }
  if hash yum &>/dev/null; then
    yum install -y vim git
  elif hash apt &>/dev/null; then
    apt get install -y vim
  elif hash zypper &>/dev/null; then
    zypper install -y vim
  fi
%{ endif }

%{ if create_user }
if sed 's/"//g' /etc/os-release |grep -e '^NAME=CentOS' -e '^NAME=Fedora' -e '^NAME=Red'; then
  if ! id -u ${user_name}; then
    useradd ${user_name}
    usermod -a -G wheel ${user_name}
  fi
  %{ if user_pass != "" }
  echo "${user_pass}" | passwd --stdin ${user_name}
  %{ endif }
elif sed 's/"//g' /etc/os-release |grep -e '^NAME=Mint' -e '^NAME=Ubuntu' -e '^NAME=Debian'; then
  apt-get clean
  apt-get update
  if ! id -u ${user_name}; then
    useradd ${user_name} -s /bin/bash -m
    usermod -a -G sudo ${user_name}
  fi
  %{ if user_pass != "" }
  echo -e "${user_pass}\n${user_pass}" | passwd ${user_name}
  %{ endif }
elif sed 's/"//g' /etc/os-release |grep -e '^NAME=SLES'; then
  if ! grep $(hostname) /etc/hosts; then
    echo "127.0.0.1 $(hostname)" >> /etc/hosts
  fi
  %{ if user_pass != "" }
  pass=$(perl -e 'print crypt($ARGV[0], "password")' ${user_pass})
  useradd -U -m -p $pass ${user_name}
  %{ else }
  useradd -U -m ${user_name}
  %{ endif }
fi

printf >"/etc/sudoers.d/${user_name}" '%s    ALL= NOPASSWD: ALL\n' "${user_name}"

%{ if user_public_key != "" }
mkdir -p /home/${user_name}/.ssh
chmod 700  /home/${user_name}/.ssh
cat << EOF >>/home/${user_name}/.ssh/authorized_keys
${user_public_key}
EOF
chmod 600 /home/${user_name}/.ssh/authorized_keys
chown -R ${user_name}:${user_name} /home/${user_name}/.ssh
%{ else }
sed -i  's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
%{ endif }
%{ endif }

%{ if azure_agent }
  install_azure_agent
%{ endif }

%{ if workstation_chef }
  set_tmp_path
  install_chef ${chef_product_name} ${chef_product_version}
%{ endif }

%{ if workstation_hab }
  set_tmp_path
  install_hab ${hab_version}
%{ endif }

%{ if populate_hosts }
if ! grep "$(hostname -i) $(hostname)" /etc/hosts; then
  echo "$(hostname -i) $(hostname)" >> /etc/hosts
fi
%{ endif }

(umask 002; touch /setup.lock)

%{ endif }
%{ if system_type == "windows" }
Set-MpPreference -DisableRealtimeMonitoring $true
%{ if create_user }
%{ if user_name == "Administrator" || user_name == "administrator" }
$MySecureString = ConvertTo-SecureString -String "${user_pass}" -AsPlainText -Force
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password $MySecureString
%{ endif }

net user ${user_name} '${user_pass}' /add /y
net localgroup administrators ${user_name} /add
%{ endif }

$Logfile = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.log'
Start-Transcript -Path $Logfile

winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'

winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

net stop winrm
sc.exe config winrm start=auto
net start winrm

function install_choco {
  if( -Not (Test-Path -Path "$env:ProgramData\Chocolatey")) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('${choco_install_url}'))
  }
}

function update_path {
  Param
  (
    [Parameter(Mandatory=$true, Position=0)]
    [string] $path_entry
  )
  $newpath = "$env:Path;$path_entry"
  [System.Environment]::SetEnvironmentVariable('Path',$newpath,[System.EnvironmentVariableTarget]::User)
}

%{ if docker_engine }
Install-Module DockerMsftProvider -Force
Install-Package Docker -ProviderName DockerMsftProvider -Force
%{ endif }

%{ if hyperv }
install_choco
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
%{ endif }

%{ if vbox }
install_choco
choco install virtualbox -y
%{ endif }

%{ if vagrant }
install_choco
choco install vagrant -y
%{ endif }

%{ if install_workstation_tools }
install_choco
choco install git -y
choco install googlechrome -y
update_path 'C:\Program Files (x86)\Google\Chrome\Application\'
choco install vscode -y
update_path 'C:\Program Files\Microsoft VS Code\'
%{ endif }

%{ if docker }
choco install docker-desktop -y
Add-LocalGroupMember -Group 'Administrators' -Member ('docker-users') -Verbose
Add-LocalGroupMember -Group 'docker-users' -Member ('${user_name}','Administrators') -Verbose
%{ endif }

%{ if terraform }
choco install terraform -y
%{ endif }

%{ if workstation_hab }
install_choco
  %{ if hab_version == "latest" }
choco install habitat -y
  %{ else }
choco install habitat --version ${hab_version} -y
  %{ endif }
hab license accept

%{ for p in hab_pkgs }
hab pkg install ${p}
%{ endfor}

%{ if hab_pkg_export != ""}
hab pkg export docker ${hab_pkg_export}
%{ endif }

%{ endif }

%{ if workstation_chef }
install_choco

%{ if chef_product_version == "latest" }
choco install ${chef_product_name} -y
%{ else }
choco install ${chef_product_name} --version ${chef_product_version} -y
%{ endif }

%{ if chef_product_name == "chef-workstation" }
update_path 'C:\opscode\chef-workstation\bin;C:\opscode\chef-workstation\embedded\bin\'
%{ endif }

%{ if chef_product_name == "chef" }
update_path 'C:\opscode\chef\bin;C:\opscode\chef\embedded\bin\'
%{ endif }

%{ if chef_product_name == "chefdk" }
update_path 'C:\opscode\chefdk\bin\;C:\opscode\chefdk\embedded\bin\'
%{ endif }

%{ if chef_product_name == "inspec" }
update_path 'C:\opscode\inspec\bin;C:\opscode\inspec\embedded\bin\'
%{ endif }

%{ endif }

%{ for k in jsondecode(helper_files) }
$helper_file = @"
${join("\n", k.script)}
"@
$dtp = [Environment]::GetFolderPath("CommonDesktopDirectory")
Set-Content -Path $dtp\\${k.name} -Value $helper_file
%{ endfor}

%{ if kb_uk }
Set-WinUserLanguageList -LanguageList en-GB -Force
%{ endif }

%{ if wsl }
if ((Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux').State -ne 'Enabled') {
  $ProgressPreference = 'SilentlyContinue'
  cd C:\
  Push-Location $(Get-Location)
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
  curl.exe -L -o C:\ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804
  Rename-Item C:\ubuntu-1804.appx C:\Ubuntu.zip
  Expand-Archive C:\Ubuntu.zip

  $wsl_user_bash = @"
#!/bin/bash -x
exec > /tmp/wsl_user_script.log 2>&1

useradd -m -s /bin/bash ${user_name}
echo -e "${user_pass}\n${user_pass}" | passwd ${user_name}
usermod -a -G sudo ${user_name}
printf >"/etc/sudoers.d/${user_name}" '%s    ALL= NOPASSWD: ALL\n' "${user_name}"
chmod 644 /etc/sudoers.d/${user_name}
"@

  sc C:\wsl_user_bash.sh ([byte[]][char[]] "$wsl_user_bash") -Encoding Byte

  $wsl = @'
Start-Transcript -Path C:\wsl_job.log
C:\Ubuntu\ubuntu1804.exe install --root

C:\Ubuntu\ubuntu1804.exe run "apt-get update && apt-get install dos2unix -y"
C:\Ubuntu\ubuntu1804.exe run "dos2unix -n /mnt/c/wsl_user_bash.sh /mnt/c/wsl_user_bash.sh"

C:\Ubuntu\ubuntu1804.exe run "bash /mnt/c/wsl_user_bash.sh"

C:\Ubuntu\ubuntu1804.exe config --default-user ${user_name}

Set-Content -Path C:\wsl_setup.lock -Value "$(Get-Date)"
Unregister-ScheduledTask -TaskName WSL_Setup -Confirm:$false
Stop-Transcript
'@

  Set-Content -Path C:\wsl_setup.ps1 -Value $wsl
  $Trigger = New-ScheduledTaskTrigger -AtStartup
  $User = "$env:USERDOMAIN\${user_name}"
  $Password = '${user_pass}'

  $Action = New-ScheduledTaskAction -Execute "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-ExecutionPolicy Unrestricted -File "C:\wsl_setup.ps1"'
  Register-ScheduledTask -TaskName "WSL_Setup" -Trigger $Trigger -User $User -Password $Password -Action $Action -RunLevel Highest -Force
  Pop-Location
}
%{ endif }

Set-MpPreference -DisableRealtimeMonitoring $false
# writing lock file

$loc = @"
lock created: $(Get-Date)
"@

Set-Content -Path C:\setup.lock -Value $loc
Stop-Transcript
%{ endif }
