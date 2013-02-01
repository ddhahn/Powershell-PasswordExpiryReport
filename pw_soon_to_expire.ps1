#David Hahn  - 12/5/2010
#Find users that password will expire in 3 days or less
import-module ActiveDirectory

##Define new export-csv function that allows for appending to CSV files, the 
##native export-csv does not do this.
<#
  This Export-CSV behaves exactly like native Export-CSV
  However it has one optional switch -Append
  Which lets you append new data to existing CSV file: e.g.
  Get-Process | Select ProcessName, CPU | Export-CSV processes.csv -Append

  For details, see

http://dmitrysotnikov.wordpress.com/2010/01/19/export-csv-append/

  (c) Dmitry Sotnikov
#>
function Export-CSV2 {
[CmdletBinding(DefaultParameterSetName='Delimiter',
  SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
 [Parameter(Mandatory=$true, ValueFromPipeline=$true,
           ValueFromPipelineByPropertyName=$true)]
 [System.Management.Automation.PSObject]
 ${InputObject},

 [Parameter(Mandatory=$true, Position=0)]
 [Alias('PSPath')]
 [System.String]
 ${Path},

 #region -Append (added by Dmitry Sotnikov)
 [Switch]
 ${Append},
 #endregion 

 [Switch]
 ${Force},

 [Switch]
 ${NoClobber},

 [ValidateSet('Unicode','UTF7','UTF8','ASCII','UTF32',
                  'BigEndianUnicode','Default','OEM')]
 [System.String]
 ${Encoding},

 [Parameter(ParameterSetName='Delimiter', Position=1)]
 [ValidateNotNull()]
 [System.Char]
 ${Delimiter},

 [Parameter(ParameterSetName='UseCulture')]
 [Switch]
 ${UseCulture},

 [Alias('NTI')]
 [Switch]
 ${NoTypeInformation})

begin
{
 # This variable will tell us whether we actually need to append
 # to existing file
 $AppendMode = $false

 try {
  $outBuffer = $null
  if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
  {
      $PSBoundParameters['OutBuffer'] = 1
  }
  $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Export-Csv',
    [System.Management.Automation.CommandTypes]::Cmdlet)

 #String variable to become the target command line
 $scriptCmdPipeline = ''

 # Add new parameter handling
 #region Dmitry: Process and remove the Append parameter if it is present
 if ($Append) {

  $PSBoundParameters.Remove('Append') | Out-Null

  if ($Path) {
   if (Test-Path $Path) {
    # Need to construct new command line
    $AppendMode = $true

    if ($Encoding.Length -eq 0) {
     # ASCII is default encoding for Export-CSV
     $Encoding = 'ASCII'
    }

    # For Append we use ConvertTo-CSV instead of Export
    $scriptCmdPipeline += 'ConvertTo-Csv -NoTypeInformation '

    # Inherit other CSV convertion parameters
    if ( $UseCulture ) {
     $scriptCmdPipeline += ' -UseCulture '
    }
    if ( $Delimiter ) {
     $scriptCmdPipeline += " -Delimiter '$Delimiter' "
    } 

    # Skip the first line (the one with the property names) 
    $scriptCmdPipeline += ' | Foreach-Object {$start=$true}'
    $scriptCmdPipeline += '{if ($start) {$start=$false} else {$_}} '

    # Add file output
    $scriptCmdPipeline += " | Out-File -FilePath '$Path'"
    $scriptCmdPipeline += " -Encoding '$Encoding' -Append "

    if ($Force) {
     $scriptCmdPipeline += ' -Force'
    }

    if ($NoClobber) {
     $scriptCmdPipeline += ' -NoClobber'
    }
   }
  }
 } 

 $scriptCmd = {& $wrappedCmd @PSBoundParameters }

 if ( $AppendMode ) {
  # redefine command line
  $scriptCmd = $ExecutionContext.InvokeCommand.NewScriptBlock(
      $scriptCmdPipeline
    )
 } else {
  # execute Export-CSV as we got it because
  # either -Append is missing or file does not exist
  $scriptCmd = $ExecutionContext.InvokeCommand.NewScriptBlock(
      [string]$scriptCmd
    )
 }

 # standard pipeline initialization
 $steppablePipeline = $scriptCmd.GetSteppablePipeline(
        $myInvocation.CommandOrigin)
 $steppablePipeline.Begin($PSCmdlet)

 } catch {
   throw
 }

}

process
{
  try {
      $steppablePipeline.Process($_)
  } catch {
      throw
  }
}

end
{
  try {
      $steppablePipeline.End()
  } catch {
      throw
  }
}
<#

.ForwardHelpTargetName Export-Csv
.ForwardHelpCategory Cmdlet

#>

}

##Here are the bitmasks for decoding the UserAccessControl value
#		{($uac -bor 0x0002) -eq $uac} {$flags += "ACCOUNTDISABLE"}
#		{($uac -bor 0x0008) -eq $uac} {$flags += "HOMEDIR_REQUIRED"}
#		{($uac -bor 0x0010) -eq $uac} {$flags += "LOCKOUT"}
#		{($uac -bor 0x0020) -eq $uac} {$flags += "PASSWD_NOTREQD"}
#		{($uac -bor 0x0040) -eq $uac} {$flags += "PASSWD_CANT_CHANGE"}
#		{($uac -bor 0x0080) -eq $uac} {$flags += "ENCRYPTED_TEXT_PWD_ALLOWED"}
#		{($uac -bor 0x0100) -eq $uac} {$flags += "TEMP_DUPLICATE_ACCOUNT"}
#		{($uac -bor 0x0200) -eq $uac} {$flags += "NORMAL_ACCOUNT"}
#		{($uac -bor 0x0800) -eq $uac} {$flags += "INTERDOMAIN_TRUST_ACCOUNT"}
#		{($uac -bor 0x1000) -eq $uac} {$flags += "WORKSTATION_TRUST_ACCOUNT"}
#		{($uac -bor 0x2000) -eq $uac} {$flags += "SERVER_TRUST_ACCOUNT"}
#		{($uac -bor 0x10000) -eq $uac} {$flags += "DONT_EXPIRE_PASSWORD"}
#		{($uac -bor 0x20000) -eq $uac} {$flags += "MNS_LOGON_ACCOUNT"}
#		{($uac -bor 0x40000) -eq $uac} {$flags += "SMARTCARD_REQUIRED"}
#		{($uac -bor 0x80000) -eq $uac} {$flags += "TRUSTED_FOR_DELEGATION"}
#		{($uac -bor 0x100000) -eq $uac} {$flags += "NOT_DELEGATED"}
#		{($uac -bor 0x200000) -eq $uac} {$flags += "USE_DES_KEY_ONLY"}
#		{($uac -bor 0x400000) -eq $uac} {$flags += "DONT_REQ_PREAUTH"}
#		{($uac -bor 0x800000) -eq $uac} {$flags += "PASSWORD_EXPIRED"}
#		{($uac -bor 0x1000000) -eq $uac} {$flags += "TRUSTED_TO_AUTH_FOR_DELEGATION"}


##define where in AD to begin the search
$searchroot = 'DC=contoso,DC=com'

##Get the date three weeks ago
$threeweeksago = (Get-Date).adddays(-21)

##path to the output log file.
$reportfile = "c:\temp\oldusers.csv" 

##what's the max password age, in days?
$maxpasswordage = 90

##how many days old should the password be before it appears on the report?
$daystillwarning = 3

#delete the report file
del $reportfile

#get users that have passwords that will expire in 3 days and have been created more than three weeks ago.
#this assumes the password policy says to change every 90 days.
#users who's accounts are disabled, set to not change the password or set so the password can't change shouuld be excluded.
#we also exclude users who's passwords have never been changed...
$oldpasswords = get-aduser -Properties description,pwdlastset,userprincipalname,useraccountcontrol,whencreated -searchbase "$searchroot" -ldapfilter "(&(!useraccountcontrol:1.2.840.113556.1.4.804:=65602)(!pwdlastset=0))" | 
Where-Object {([datetime]::fromfiletime($_.pwdlastset) -lt (get-date).AddDays($daystillwarning - $maxpasswordage)) -and ($_.whencreated -lt $threeweeksago)}

foreach ($oldpassword in $oldpasswords) {
    
	select -input $oldpassword -property name,userPrincipalName,@{n="OU";e={$_.DistinguishedName.Split(",")[3]}},description,whencreated,@{n="Password Last Set";e={[datetime]::fromfiletime($_.pwdlastset)}},@{n="Days Since Password Last Changed";e={((get-date)- ([datetime]::fromfiletime($_.pwdlastset))).days}}, @{n="Days Until Password Expires";e={$maxpasswordage - ((get-date) - ([datetime]::fromfiletime($_.pwdlastset))).days}} | 
	Export-CSV2 "$reportfile" -append
}
	