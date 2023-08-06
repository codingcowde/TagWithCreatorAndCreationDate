param($eventGridEvent, $TriggerMetadata)

#$caller = $eventGridEvent.data.claims.name
$caller = $eventGridEvent.data.claims."http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
if ($null -eq $caller) {
    if ($eventGridEvent.data.authorization.evidence.principalType -eq "ServicePrincipal") {
        $caller = (Get-AzADServicePrincipal -ObjectId $eventGridEvent.data.authorization.evidence.principalId).DisplayName
        if ($null -eq $caller) {
            Write-Host "MSI may not have permission to read the applications from the directory"
            $caller = $eventGridEvent.data.authorization.evidence.principalId
        }
    }
}

Write-Host "Caller: $caller"
$resourceId = $eventGridEvent.data.resourceUri
Write-Host "ResourceId: $resourceId"

if (($null -eq $caller) -or ($null -eq $resourceId)) {
    Write-Host "ResourceId or Caller is null"
    exit;
}

$ignore = @(
    "providers/Microsoft.Resources/deployments",
    "providers/Microsoft.Resources/tags",
    "providers/Microsoft.Network/frontdoor"
)

foreach ($case in $ignore) {
    if ($resourceId -match $case) {
        Write-Host "Skipping event as resourceId ignorelist contains: $case"
        exit;
    }
}
#Write-Host "Try add Creator tag with user: $caller"

$newTag = @{
    Creator = $caller
}

$tags = (Get-AzTag -ResourceId $resourceId)

# Check if tags are not supported
if (-not $tags) {
    Write-Host "$resourceId does not support tags"
    return
}

# Check if properties are null
if (-not $tags.properties) {
    Write-Host "WARNING! $resourceId does not support tags? (`$tags.properties is null)"
    return
}

# Check if TagsProperty is null
if (-not $tags.properties.TagsProperty) {
    Write-Host "Added Creator tag with user: $caller"
    New-AzTag -ResourceId $resourceId -Tag $newTag | Out-Null
    return
}

# Check if Creator tag already exists
if ($tags.properties.TagsProperty.ContainsKey('Creator')) {
    Write-Host "Creator tag already exists"
}
else {
    Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $newTag | Out-Null
    Write-Host "Added Creator tag with user: $caller"
}