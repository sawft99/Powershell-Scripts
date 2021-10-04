#Check headers in outlook for 'reply to' and 'from' to see if they match

Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Policy.11.0.Microsoft.Office.Interop.Outlook\15.0.0.0__71e9bce111e9429c\Policy.11.0.Microsoft.Office.Interop.Outlook.dll"
$Email = Read-Host -Prompt "Enter your email address"
$Outlook = New-Object -comobject Outlook.Application
$namespace = $Outlook.GetNameSpace("MAPI")

$MyInbox = $namespace.Folders.Item("$Email").folders.item('Inbox')
$ReplyTo = $MyInbox.Items.GetLast().ReplyRecipients.Name
$From = $MyInbox.Items.GetLast().SenderEmailAddress