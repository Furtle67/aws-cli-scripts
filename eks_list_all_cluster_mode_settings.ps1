$region  = "us-east-1"
$profile = "nphase"

$clusters = aws eks list-clusters --region $region --profile $profile --query "clusters[]" --output text

"{0,-45} {1,-14} {2}" -f "CLUSTER", "K8S VERSION", "MODE"
"{0,-45} {1,-14} {2}" -f "-------", "-----------", "----"

foreach ($c in $clusters -split "\s+") {
    if ([string]::IsNullOrWhiteSpace($c)) { continue }

    $info = aws eks describe-cluster --name $c --region $region --profile $profile `
        --query "cluster.[version,computeConfig.enabled]" --output text
    $parts = $info -split "\s+"
    $ver     = $parts[0]
    $enabled = $parts[1]

    $mode = if ($enabled -eq "True") { "Auto Mode" } else { "Standard EKS" }

    "{0,-45} {1,-14} {2}" -f $c, $ver, $mode
}