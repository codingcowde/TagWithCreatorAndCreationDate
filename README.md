# TagWithCreatorAndCreationData

Based on Blog posted at [Premier Field Engineering Tech Community](https://aka.ms/AnthonyWatherston) and Anthony's repository

## Purpose

This PowerShell script is designed to be triggered by Azure Event Grid events. Its primary purpose is to automatically add two tags, Creator and CreatedAt, to Azure resources whenever they are created.

The script captures the UPN or service principal of the user who created a resource, and adds a tag "Creator" to the resource. It skips adding tags to resources of specific types defined in the $ignore array. If a "Creator" tag already exists, it doesn't overwrite it. If the resource doesn't support tags or the tags properties are null, it just prints a warning and exits.

## How it works

When the function is triggered it goes through the follwing steps: 

1. The script retrieves the User Principal Name (UPN) of the user (the Creator) who triggered the event, which is assumed to be the creation of an Azure resource.

2. If the Creator is a service principal rather than a user, the script attempts to get the service principal's display name instead.

3. The script retrieves the ResourceId of the resource that was created.

4. If either the Creator or the ResourceId is null, the script logs an error message and exits.

5. The script checks whether the ResourceId matches any of a list of resource types that should be ignored. If there's a match, the script logs a message and exits.

6. If the resource supports tagging and doesn't already have a Creator tag, the script creates two new tags: Creator (with the value of the Creator) and CreatedAt (with the value of the event's timestamp). The script then attaches these tags to the resource.

### Disclaimer:

The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.