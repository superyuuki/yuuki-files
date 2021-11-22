#!/bin/bash
HostName="http://panel.superyuuki.com"
Organization="64d286aa-9bb0-45b0-b8e2-5bd132acdc4b"
GUID=$(cat /proc/sys/kernel/random/uuid)
UpdatePackagePath=""


Args=( "$@" )
ArgLength=${#Args[@]}

for (( i=0; i<${ArgLength}; i+=2 ));
do
    if [ "${Args[$i]}" = "--uninstall" ]; then
        systemctl stop remotely-agent
        rm -r -f /usr/local/bin/Remotely
        rm -f /etc/systemd/system/remotely-agent.service
        systemctl daemon-reload
        exit
    elif [ "${Args[$i]}" = "--path" ]; then
        UpdatePackagePath="${Args[$i+1}"
    fi
done

yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

dnf install aspnetcore-runtime-5.0 -y
dnf install libX11 -y
dnf install unzip -y
dnf install glibc -y
dnf install curl -y
dnf install libgdiplus -y
dnf install libXtst -y
dnf install xclip -y
dnf install jq -y


if [ -f "/usr/local/bin/Remotely/ConnectionInfo.json" ]; then
    SavedGUID=`cat "/usr/local/bin/Remotely/ConnectionInfo.json" | jq -r '.DeviceID'`
    if [[ "$SavedGUID" != "null" && -n "$SavedGUID" ]]; then
        GUID="$SavedGUID"
    fi
fi

rm -r -f /usr/local/bin/Remotely
rm -f /etc/systemd/system/remotely-agent.service

mkdir -p /usr/local/bin/Remotely/
cd /usr/local/bin/Remotely/

if [ -z "$UpdatePackagePath" ]; then
    echo  "Downloading client..." >> /tmp/Remotely_Install.log
    wget $HostName/Content/Remotely-Linux.zip
else
    echo  "Copying install files..." >> /tmp/Remotely_Install.log
    cp "$UpdatePackagePath" /usr/local/bin/Remotely/Remotely-Linux.zip
    rm -f "$UpdatePackagePath"
fi

unzip ./Remotely-Linux.zip
rm -f ./Remotely-Linux.zip
chmod +x ./Remotely_Agent
chmod +x ./Desktop/Remotely_Desktop


connectionInfo="{
    \"DeviceID\":\"$GUID\", 
    \"Host\":\"$HostName\",
    \"OrganizationID\": \"$Organization\",
    \"ServerVerificationToken\":\"\"
}"

echo "$connectionInfo" > ./ConnectionInfo.json

curl --head $HostName/Content/Remotely-Linux.zip | grep -i "etag" | cut -d' ' -f 2 > ./etag.txt

echo Creating service... >> /tmp/Remotely_Install.log

serviceConfig="[Unit]
Description=The Remotely agent used for remote access.

[Service]
WorkingDirectory=/usr/local/bin/Remotely/
ExecStart=/usr/local/bin/Remotely/Remotely_Agent
Restart=always
StartLimitIntervalSec=0
RestartSec=10

[Install]
WantedBy=graphical.target"

echo "$serviceConfig" > /etc/systemd/system/remotely-agent.service

systemctl enable remotely-agent
systemctl restart remotely-agent

echo Install complete. >> /tmp/Remotely_Install.log
