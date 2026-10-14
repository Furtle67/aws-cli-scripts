<#
sm-python-server
edc-migration-job
diff-migration-job
jetty
dna-platform
msg-consumer
papermill_microservice
clickhouse-data-manager
datastage
jupyter-server
dbac-gateway-backend
clinical-model-web
jupyterhub
db-migration
mockingbird
#>

# ── Step 1: Set your parameters ───────────────────────────────
$repo    = "sm-python-server"
$profile = "nphase"
$region  = "us-east-1"

# ── Step 2: Build the filter and write it to a file ───────────
# (file:// avoids all PowerShell JSON-quoting problems)
$filterJson = '{"ecrImageRepositoryName":[{"comparison":"EQUALS","value":"' + $repo + '"}]}'
$filterJson | Out-File -Encoding ascii filter.json
Write-Host "Filter written:" $filterJson

# ── Step 3: Pull the raw findings from Inspector ──────────────
$rawJson = aws inspector2 list-findings `
  --filter-criteria file://filter.json `
  --profile $profile --region $region `
  --output json

# ── Step 4: Parse the JSON ────────────────────────────────────
$parsed = $rawJson | ConvertFrom-Json

# ── Step 5: Extract just the findings array ───────────────────
$findings = $parsed.findings
Write-Host "Findings returned:" $findings.Count

# ── Step 6: Shape the fields you want ─────────────────────────
$shaped = $findings | ForEach-Object {
    [PSCustomObject]@{
        Title       = $_.title
        Severity    = $_.severity
        VulnId      = $_.packageVulnerabilityDetails.vulnerabilityId
        Description = $_.description
        Layer       = $_.resources[0].details.awsEcrContainerImage.imageHash
        Package     = $_.packageVulnerabilityDetails.vulnerablePackages[0].name
        FilePath    = $_.packageVulnerabilityDetails.vulnerablePackages[0].filePath
    }
}

# ── Step 7: Deduplicate ───────────────────────────────────────
$deduped = $shaped | Sort-Object Title, VulnId -Unique
Write-Host "After dedup:" $deduped.Count

# ── Step 8: View on screen ────────────────────────────────────
$deduped | Format-Table -AutoSize -Wrap

# ── Step 9: (optional) Export to CSV ──────────────────────────
$deduped | Export-Csv -NoTypeInformation "$repo-vulns.csv"
Write-Host "Saved to $repo-vulns.csv"