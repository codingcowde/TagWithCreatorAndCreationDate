# Input parameters to the script: Event Grid Event data and trigger metadata.
param($eventGridEvent, $TriggerMetadata)




# At this point, we know it's a 'Created' event. Do your work here.

# Send a response back to acknowledge receipt of the event
Out-PutHttpResponse -StatusCode OK -ReasonPhrase "OK"
With this modification, the function will terminate early if the eventType is not 'Microsoft.Resources.ResourceWriteSuccess' or if the status is not 'Created', sending back an HTTP response that describes why it's not proceeding further.

Remember to replace the Out-PutHttpResponse function with the correct function




# Retrieve the caller's User Principal Name (UPN) from event data claims. 
$caller = $eventGridEvent.data.claims."http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"

# If you are fine with just the name change the above line to:
# $caller = $eventGridEvent.data.claims.name
# This also works if no AD is present or the app has no rights to access it.


# If caller's UPN is not found and the principal type is a Service Principal,
# then get the display name of the Service Principal as the caller.
if ($null -eq $caller) {
    if ($eventGridEvent.data.authorization.evidence.principalType -eq "ServicePrincipal") {
        $caller = (Get-AzADServicePrincipal -ObjectId $eventGridEvent.data.authorization.evidence.principalId).DisplayName
        
        # If display name of the Service Principal is not found,
        # use the principal Id as the caller.
        if ($null -eq $caller) {
            Write-Host "MSI may not have permission to read the applications from the directory"
            $caller = $eventGridEvent.data.authorization.evidence.principalId
        }
    }
}

# Log the caller.
Write-Host "Caller: $caller"

# Get the Resource Id from the event data.
$resourceId = $eventGridEvent.data.resourceUri

# Log the Resource Id.
Write-Host "ResourceId: $resourceId"

# If either the caller or the Resource Id is null, log the issue and exit.
if (($null -eq $caller) -or ($null -eq $resourceId)) {
    Write-Host "ResourceId or Caller is null"
    exit;
}

# Define a list of resource types to be ignored for tagging.
$ignore = @(
    "providers/Microsoft.Resources/deployments",
    "providers/Microsoft.Resources/tags",
    "providers/Microsoft.Network/frontdoor"
)

# If the Resource Id matches any in the ignore list, skip tagging and exit.
foreach ($case in $ignore) {
    if ($resourceId -match $case) {
        Write-Host "Skipping event as resourceId ignorelist contains: $case"
        exit;
    }
}

# Get the creation date from the event or set now as creation date
$creationTime = $eventGridEvent.data.eventTime
if ($null -eq $creationTime) {
    $creationTime = Get-Date -Format s # get current time in ISO 8601 format
}


# Define a hashtable for new tags: Creator and CreatedAt.
$newTag = @{
    Creator = $caller
    CreatedAt = $creationTime # This is assumed to be the creation time.
}

# Get existing tags of the resource.
$tags = (Get-AzTag -ResourceId $resourceId)

# If tags are not supported for the resource, log the issue and return.
if (-not $tags) {
    Write-Host "$resourceId does not support tags"
    return
}

# If tag properties are null, log the issue and return.
if (-not $tags.properties) {
    Write-Host "WARNING! $resourceId does not support tags? (`$tags.properties is null)"
    return
}

# If tag properties are null, create new tags and return.
if (-not $tags.properties.TagsProperty) {
    Write-Host "Added Creator and CreatedAt tags with user: $caller"
    New-AzTag -ResourceId $resourceId -Tag $newTag | Out-Null
    return
}

# If Creator tag already exists, log it.
if ($tags.properties.TagsProperty.ContainsKey('Creator')) {
    Write-Host "Creator tag already exists"
}
# If Creator tag does not exist, add new tags and log the operation.
else {
    Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $newTag | Out-Null
    Write-Host "Added Creator and CreatedAt tags with user: $caller"
}

Out-PutHttpResponse -StatusCode OK -ReasonPhrase "Created Tags"
