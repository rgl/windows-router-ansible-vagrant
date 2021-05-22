param(
    $routerIpAddress = '10.100.100.254'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$adapters = Get-NetAdapter -Physical
$vagrantAdapter = $adapters | Where-Object {($_ | Get-NetIPInterface).Dhcp -eq 'Enabled'}
$routerAdapter = $adapters | Where-Object {$_ -ne $vagrantAdapter}

# configure the default gateway.
$ipConfiguration = $routerAdapter | Get-NetIPAddress -AddressFamily IPv4
# NB New-NetIPAddress cmdlet is very odd because it cannot just override the
#    existing settings, we would have to first Remove it, which is too much
#    trouble, so, we just use netsh.
# $routerAdapter | New-NetIPAddress `
#     -AddressFamily IPv4 `
#     -IPAddress $ipConfiguration.IPAddress `
#     -PrefixLength $ipConfiguration.PrefixLength `
#     -DefaultGateway $routerIpAddress
if (!((netsh interface ip show addresses $routerAdapter.Name) -match "\s+Default Gateway:\s+$([Regex]::Escape($routerIpAddress))")) {
    netsh interface ip set address `
        "name=$($routerAdapter.Name)" `
        'source=static' `
        "address=$($ipConfiguration.IPAddress)/$($ipConfiguration.PrefixLength)" `
        "gateway=$routerIpAddress"
    $Ansible.Changed = $true
}

# make sure windows uses the router interface default gateway.
# NB there is apparent way to prevent windows DHCP client from requesting the
#    routers/default-gateway, so, windows will always set the DHCP interface
#    gateway. To indirectly force windows to use our router interface, we must
#    make sure the DHCP interface as a higher metric (less priority) than the
#    router interface.
if (!(($vagrantAdapter | Get-NetIPInterface).InterfaceMetric -eq 1000)) {
    $vagrantAdapter | Set-NetIPInterface -InterfaceMetric 1000
    $Ansible.Changed = $true
}

# wait until the configuration change works.
if ($Ansible.Changed) {
    Write-Output 'Traceroute to google.com...'
    while ($true) {
        $result = Test-NetConnection google.com -TraceRoute
        if ($result.PingSucceeded) {
            Write-Output $result
            if ($result.TraceRoute[0] -ne $routerIpAddress) {
                throw "for some reason the first hop is not the router IP address $routerIpAddress and it should!"
            }
            break
        }
        Start-Sleep -Seconds 1
    }
}
