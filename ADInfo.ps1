#Basic AD tool to fetch info on user, group, or computer. Allows basic tasks related to each such as add/remove from group or resetting a password

Clear-Host
Import-Module ActiveDirectory
Write-Host
Write-Host 'Enter selection'
Write-Host
Write-Host '[1] User'
Write-Host '[2] Group'
Write-Host '[3] Computer'
#Begining, chose search for user, group, or computer
Write-Host
choice /n /c 123 /m "Seach for User, Group, or Computer: "
if ($LASTEXITCODE -eq 1) {
    Write-Host
    #Will search for user based off username or name. Will exit if search returns nothing or is blank.
    $ADUserSearch = Read-Host -Prompt 'Enter any part of a username or name to search for'
    if ($ADUserSearch.Length -eq 0) {
        Write-Host "You must enter something to search by"
        Exit
    }
    $ADUserSearchResults = Get-ADUser -Properties * -Filter "Name -like '*$ADUserSearch*'" | Where-Object -Property ObjectClass -eq user
    if ($ADUserSearchResults.Length -eq 0) {
        $ADUserSearchResults = Get-ADUser -Properties * -Filter "SamAccountName -like '*$ADUserSearch*'" | Where-Object -Property ObjectClass -eq user
        if ($ADUserSearchResults -eq 0) {
            Write-Host "No person or username with that input exists..."
            Exit
        }
    }
    #Sort list by name before numbering
    $ADUserSearchResultsSorted = $ADUserSearchResults | Sort-Object -Property Name
    $ADUserSearchResultsCount = 1
    $ADUserSearchResultsSorted | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name Line -Value $ADUserSearchResultsCount -Force
    $ADUserSearchResultsCount++}
    
    #List user sees fully sorted
    Clear-Host
    $ADUserSearchResultsSorted | Format-Table Line,Name,SamAccountName
    #insert check for if it is a valid number!
    $UserLineSelect = Read-Host -Prompt 'Select user by line number'
    $UserSelect = $ADUserSearchResultsSorted | Where-Object -Property Line -EQ $UserLineSelect
    Clear-Host
    Write-Host
    Write-Host 'User selected:'
    $UserSelect | Format-Table Name, SamAccountName
    Write-Host 'Tasks:'
    Write-Host
    Write-Host '[1] Get basic AD info'
    Write-Host '[2] Get group membership'
    Write-Host '[3] Disable/Enable user'
    Write-Host '[4] Add/Remove from group'
    Write-Host '[5] Reset password {Gone until secure method available}'
    Write-Host
    choice /n /c 1234 /m "Select task: "
        if ($LASTEXITCODE -eq 1) {
            $UserSelect | Format-Table Name, SamAccountName, Description, Mail, DistinguishedName, PasswordExpired, LastBadPasswordAttempt, LockedOut, Enabled
            Exit
        }
        if ($LASTEXITCODE -eq 2) {
            Write-Host
            Write-Host $UserSelect.Name is a member of these groups:
            $UserSelect.memberof | Get-ADGroup | Select-Object Name, SamAccountName, GroupCategory | Sort-Object -Property Name
            Exit
        }
        if ($LASTEXITCODE -eq 3) {
            if ($UserSelect.Enabled -eq '$True') {
                Write-Host
                Write-Host 'User account is enabled. Confirm you want to disable.'
                Write-Host
                $UserSelect.DistinguishedName | Disable-ADAccount -Confirm
                Exit
            }
            elseif ($UserSelect.Enabled -eq '$False') {
                    Write-Host
                    Write-Host 'User account is disabled. Confirm you want to enable'
                    Write-Host
                    $UserSelect.DistinguishedName | Enable-ADAccount -Confirm
                    Exit
            }
        }
        if ($LASTEXITCODE -eq 4) {
            $UserGroupMembership = $UserSelect.memberof | Get-ADGroup | Select-Object Name | Sort-Object -Property Name
            $UserGroupMembershipCount = 1
            $UserGroupMembership | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name Line -Value $UserGroupMembershipCount -Force
            $UserGroupMembershipCount++}
            Clear-Host
            Write-Host
            Write-Host "[1] Add user to group"
            Write-Host "[2] Remove user from group"
            Write-Host
            choice /n /c 12 /m "Add or remove user from group?: "
                if ($LASTEXITCODE -eq 1) {
                    Write-Host
                    $GroupAddSearch = Read-Host -Prompt "Enter group to add to"
                    $GroupAdd = Get-ADGroup -Filter "Name -like '*$GroupAddSearch*'" -Properties *
                        if ($null -eq $GroupAdd) {
                            Write-Host "No group matching your search"
                            Exit
                        }
                    $GroupAddList = $GroupAdd | Select-Object Name, SamAccountName, GroupCategory | Sort-Object -Property Name
                    $GroupAddListCount = 1
                    $GroupAddList | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name Line -Value $GroupAddListCount -Force
                    $GroupAddListCount++}
                    $GroupAddList | Format-Table Line, Name, SamAccountName, GroupCategory
                    Write-Host
                    $GroupAddListLine = Read-Host -Prompt "Pick a group to add"
                    $GroupAddSelect = $GroupAddList | Where-Object -Property Line -EQ $GroupAddListLine
                    Add-ADGroupMember $GroupAddSelect.SamAccountName -Members $UserSelect.SamAccountName
                    Write-Host
                    Write-Host $UserSelect.Name added to group $GroupAddSelect.Name
                    Write-Host  
                }
                if ($LASTEXITCODE -eq 2) {
                    Write-Host 'User is in the following groups'
                    $UserGroupMembership | Format-Table Line, name
                    Write-Host
                    $GroupRemoveLine = Read-Host -Prompt 'Enter Line # of group you want to remove user from'
                    $GroupRemovePick = $UserGroupMembership | Where-Object -Property Line -EQ  $GroupRemoveLine 
                    $GroupRemovePick.Name | Remove-ADGroupMember -Members $UserSelect.SamAccountName -Confirm:$false
                    Write-Host
                    Write-Host ""$UserSelect.Name"removed from group"$GroupRemovePick.Name""
                    Write-Host
                }
        }
}
if ($LASTEXITCODE -eq 2) {
    Clear-Host
    $GroupSearch = Read-Host -Prompt "Enter Group to search for"
    $GroupSearchResults = Get-ADGroup -Filter * | Where-Object -Property DistinguishedName -Like "*$GroupSearch*"
    $GroupSearchResultsSorted = $GroupSearchResults | Sort-Object Name
    $GroupSearchCount = 1
    $GroupSearchResultsSorted | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name Line -Value $GroupSearchCount -Force
    $GroupSearchCount++}
    Clear-Host
    $GroupSearchResultsSorted | Format-Table Line, Name, SamAccountName, DistinguishedName, GroupCategory
    #insert check for if it is a valid number!
    $GroupLineSelect = Read-Host -Prompt 'Select group by line number'
    $GroupSelect = $GroupSearchResultsSorted | Where-Object -Property Line -EQ $GroupLineSelect
    Clear-Host
    Write-Host
    Write-Host 'Group selected:'
    $GroupSelect | Format-Table Line, Name, SamAccountName, DistinguishedName, GroupCategory
}