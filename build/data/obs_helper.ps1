param(
    [string]$ObsHost = "127.0.0.1",
    [string]$Port = "4455",
    [string]$Password = "",
    [Parameter(Mandatory = $true)]
    [string]$RequestType,
    [string]$RequestDataJson = "",
    [string]$RequestDataFile = ""
)

$ErrorActionPreference = "Stop"

function Get-Utf8Bytes([string]$Text) {
    [System.Text.Encoding]::UTF8.GetBytes($Text)
}

function Read-WSMessage {
    param([System.Net.WebSockets.ClientWebSocket]$Socket)

    $buffer = New-Object byte[] 8192
    $ms = New-Object System.IO.MemoryStream

    do {
        $segment = [ArraySegment[byte]]::new($buffer)
        $result = $Socket.ReceiveAsync($segment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()

        if ($result.Count -gt 0) {
            $ms.Write($buffer, 0, $result.Count)
        }
    } while (-not $result.EndOfMessage)

    $text = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
    $ms.Dispose()
    return $text
}

function Send-WSMessage {
    param(
        [System.Net.WebSockets.ClientWebSocket]$Socket,
        [string]$Text
    )

    $bytes = Get-Utf8Bytes $Text
    $segment = [ArraySegment[byte]]::new($bytes)

    $Socket.SendAsync(
        $segment,
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        [Threading.CancellationToken]::None
    ).GetAwaiter().GetResult() | Out-Null
}

function Get-ObsAuthString {
    param(
        [string]$Password,
        [string]$Salt,
        [string]$Challenge
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()

    $secretBytes = $sha.ComputeHash((Get-Utf8Bytes ($Password + $Salt)))
    $secretBase64 = [Convert]::ToBase64String($secretBytes)

    $authBytes = $sha.ComputeHash((Get-Utf8Bytes ($secretBase64 + $Challenge)))
    $authBase64 = [Convert]::ToBase64String($authBytes)

    $sha.Dispose()
    return $authBase64
}

$uri = "ws://$ObsHost`:$Port"

$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$ws.Options.AddSubProtocol("obswebsocket.json")
$ws.ConnectAsync([Uri]$uri, [Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null

$helloRaw = Read-WSMessage -Socket $ws
$hello = $helloRaw | ConvertFrom-Json

$identify = @{
    op = 1
    d  = @{
        rpcVersion = 1
    }
}

if ($hello.d.authentication) {
    if ([string]::IsNullOrEmpty($Password)) {
        throw "OBS requires a websocket password, but no password was provided."
    }

    $auth = Get-ObsAuthString -Password $Password -Salt $hello.d.authentication.salt -Challenge $hello.d.authentication.challenge
    $identify.d.authentication = $auth
}

Send-WSMessage -Socket $ws -Text ($identify | ConvertTo-Json -Compress)

$identifiedRaw = Read-WSMessage -Socket $ws
$identified = $identifiedRaw | ConvertFrom-Json

if ($identified.op -ne 2) {
    throw "OBS identification failed. Response: $identifiedRaw"
}

$requestId = [guid]::NewGuid().ToString()
$requestData = @{}

if (-not [string]::IsNullOrWhiteSpace($RequestDataFile)) {
    $RequestDataJson = Get-Content -LiteralPath $RequestDataFile -Raw
}

if (-not [string]::IsNullOrWhiteSpace($RequestDataJson)) {
    $requestData = $RequestDataJson | ConvertFrom-Json
}

$request = @{
    op = 6
    d  = @{
        requestType = $RequestType
        requestId   = $requestId
        requestData = $requestData
    }
}

Send-WSMessage -Socket $ws -Text ($request | ConvertTo-Json -Compress)

$responseRaw = Read-WSMessage -Socket $ws
$response = $responseRaw | ConvertFrom-Json

if ($response.op -ne 7) {
    throw "Unexpected OBS response: $responseRaw"
}

if (-not $response.d.requestStatus.result) {
    $comment = $response.d.requestStatus.comment
    $code = $response.d.requestStatus.code
    throw "OBS request failed: $RequestType (code $code). $comment"
}

$ws.CloseAsync(
    [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
    "Done",
    [Threading.CancellationToken]::None
).GetAwaiter().GetResult() | Out-Null

$ws.Dispose()