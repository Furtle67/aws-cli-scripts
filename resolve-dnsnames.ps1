function Resolve-DnsNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string[]]$Name,

        [ValidateSet('A', 'AAAA', 'Both')]
        [string]$Type = 'Both',

        [string]$Server
    )

    process {
        foreach ($n in $Name) {
            $types = if ($Type -eq 'Both') { @('A', 'AAAA') } else { @($Type) }
            $found = $false

            foreach ($t in $types) {
                $params = @{
                    Name        = $n
                    Type        = $t
                    DnsOnly     = $true
                    ErrorAction = 'SilentlyContinue'
                }
                if ($Server) { $params.Server = $Server }

                $results = Resolve-DnsName @params |
                    Where-Object { $_.Type -in @('A', 'AAAA') }

                foreach ($r in $results) {
                    $found = $true
                    [pscustomobject]@{
                        Name      = $n
                        Type      = $r.Type
                        Address   = $r.IPAddress
                        TTL       = $r.TTL
                        Resolved  = $true
                    }
                }
            }

            if (-not $found) {
                [pscustomobject]@{
                    Name      = $n
                    Type      = $null
                    Address   = $null
                    TTL       = $null
                    Resolved  = $false
                }
            }
        }
    }
}

# Example usage
$hosts = @(
'api-int.rccokd-dev.redcapcloud.com'
'api.rccokd-dev.redcapcloud.com'
'*.apps.rccokd-dev.redcapcloud.com'
'console.apps.rccokd-dev.redcapcloud.com'
'console.rccokd-dev'
'csv-reader-ipaas-extentions-local.apps.rccokd-dev.redcapcloud.com'
'hawkular-metrics.apps.rccokd-dev.redcapcloud.com'
'internal-ipaas-dev.apps.rccokd-dev.redcapcloud.com'
'rccokd-dev.redcapcloud.com'
'redcap-academic-ipaas-dev.apps.rccokd-dev.redcapcloud.com'
'server-test-ipaas-dev.apps.rccokd-dev.redcapcloud.com'
'validation-app-ipaas-extentions.apps.rccokd-dev.redcapcloud.com'
'visual-flow.apps.rccokd-dev.redcapcloud.com'
'atlas.redcapcloud.com'
'ipaas-datalink-dev.redcapcloud.com'
'ipaas-research-dev.redcapcloud.com'
'iwrs-demo.redcapcloud.com'
'jupyterhub-dev.redcapcloud.com'
'omrs.redcapcloud.com'
'oof.redcapcloud.com'
'openmrs2.redcapcloud.com'
'papermill-dev.redcapcloud.com'
'pgrest-dev.redcapcloud.com'
'reportsesadmin.redcapcloud.com'
'webapi.redcapcloud.com'

)

Resolve-DnsNames -Name $hosts | Format-Table -AutoSize
