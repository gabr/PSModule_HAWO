<#
    .Synopsis
    HAWO module

    .Description
    Contains cmdlets related to HAWO student house

    .Link
    http://www.hawo.stw.uni-erlangen.de/

    .NOTES
    Made by gabrpp
#>


<#
    .Synopsis
    Gets traffic status of Your HAWO network

    .Description
    Gets transfer status of Your HAWO network.
    You need to be connected to Your network.

    .Link
    https://useradmin.hawo.stw.uni-erlangen.de/traffic/

    .NOTES
    Made by gabrpp
#>

function Get-HawoTraffic
{
    [CmdletBinding()]
    Param()

    $trafficLimit = 10000.00
    $url = 'https://useradmin.hawo.stw.uni-erlangen.de/traffic/'

    Write-Verbose 'Starting script...'
    Write-Verbose "Source url: $url"

    Write-Verbose 'Invoking Web Request...'
    $web = Invoke-WebRequest $url

    Write-Verbose 'Parsing content...'
    $split = $web.Content.Split("`n");
    $laufendeWoche = ($split | Select-String "laufende Woche").Line

    $oneLineAbowe = ($split | Select-String "laufende Woche" -Context 1).Context.PreContext
    $oneLineAbowe = $oneLineAbowe.Replace("<td>", "").Replace("</td>", ";")
    $oneLineAbowe = $oneLineAbowe.Split(";")

    $year = $oneLineAbowe[0]
    $week = $oneLineAbowe[1]
    $traffic = $laufendeWoche.Substring($laufendeWoche.IndexOf(">") + 1).Substring(0, $laufendeWoche.IndexOf("&") - $laufendeWoche.IndexOf(">") - 1)
    $traffic = $traffic.Replace("<b>", "").Replace("</b>", "")

    Write-Verbose 'Creating output object...'
    $Output = New-Object `
        -TypeName PSObject `
        -Property @{CurrentTraffic = $traffic;
                    TrafficLimit = $trafficLimit;
                    TrafficRatio = ($traffic/$trafficLimit);
                    TrafficLeft = ($trafficLimit - $traffic);
                    Year = $year;
                    Week = $week}

    return $Output
}


<#
    .Synopsis
    Gets temperature around HAWO Student House

    .Description
    Get-HawoTemperature uses socket to connect with HAWO telnet severto obtain information about temperature around HAWO Student House.
    So internet connection is needed.

    .Link
    http://www.hawo.stw.uni-erlangen.de/

    .NOTES
    Made by gabrpp
#>

function Get-HawoTemperature
{
    [CmdletBinding()]
    Param()

    Write-Verbose 'Starting script...'

    $RemoteHost = 'ente.hawo.stw.uni-erlangen.de'
    $Port = 7337

    Write-Verbose "Host: $RemoteHost"
    Write-Verbose "Port: $Port"

    Write-Verbose 'Creating socket...'
    $Socket = New-Object System.Net.Sockets.TcpClient($RemoteHost, $Port)
    If ($Socket -eq $null)
    {
        Write-Error 'Socket creation error'
        Break
    }

    Write-Verbose 'Getting stream...'
    $Stream = $Socket.GetStream()

    Write-Verbose 'Creating buffer and encoder...'
    $Buffer = New-Object System.Byte[] 1024
    $Encoding = New-Object System.Text.AsciiEncoding
    
    $Result = ""

    Write-Verbose 'Waiting for data...'
    While ($Stream.DataAvailable -eq $false)
    {
        Start-Sleep -Milliseconds 100
    }

    Write-Verbose 'Waiting is over'
    Write-Verbose 'Reading data...'
    While ($Stream.DataAvailable)
    {
        $Read = $Stream.Read($Buffer, 0, 1024)
        $Result += ($Encoding.GetString($Buffer, 0, $Read))
    }

    $Result = $Result.Replace('?', ' ')

    Write-Verbose 'Translation...'
    $Translation = $Result.Replace('Ostseite', 'Strona wschodnia').Replace('Westseite', 'Strona zachodnia')

    Write-Verbose 'Parsing data...'
    $Temp = $Translation.Substring(0, $Translation.IndexOf('C ('))

    $Output = New-Object `
        -TypeName PSObject `
        -Property @{ReceivedData = $Result; `
                    Translation = $Translation; `
                    Temperature = $Temp; Date = (Get-Date)}

    Write-Verbose 'All done!'
    return $Output
}
