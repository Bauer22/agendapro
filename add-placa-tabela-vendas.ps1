$arquivo = 'src\app\pages\SalesPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakplaca') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakplaca')

$txt = Get-Content $arquivo -Raw

if ($txt -match "'Motorista','Placa','Produto'") {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

$c1 = $false; $c2 = $false

# 1) Cabecalho: adiciona 'Placa' depois de 'Motorista'
$de1 = "'Cliente','Motorista','Produto','Ton'"
$para1 = "'Cliente','Motorista','Placa','Produto','Ton'"
if ($txt.Contains($de1)) { $txt = $txt.Replace($de1, $para1); $c1 = $true }

# 2) Corpo: adiciona o.plate depois de o.driver
$de2 = "o.driver||'" + [char]0x2014 + "', o.product_name||'" + [char]0x2014 + "',"
$para2 = "o.driver||'" + [char]0x2014 + "', o.plate||'" + [char]0x2014 + "', o.product_name||'" + [char]0x2014 + "',"
if ($txt.Contains($de2)) {
    $txt = $txt.Replace($de2, $para2); $c2 = $true
} else {
    # fallback via regex, sem depender do travessao exato
    $rx = "o\.driver\|\|'.{1,3}', o\.product_name\|\|'(.{1,3})',"
    $m = [regex]::Match($txt, $rx)
    if ($m.Success) {
        $trav = $m.Groups[1].Value
        $novo = "o.driver||'" + $trav + "', o.plate||'" + $trav + "', o.product_name||'" + $trav + "',"
        $txt = $txt.Replace($m.Value, $novo); $c2 = $true
    }
}

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('1) Cabecalho: ' + $c1)
Write-Host ('2) Corpo (o.plate): ' + $c2)
Write-Host ''
if ($c1 -and $c2) {
    Write-Host 'OK - coluna Placa adicionada na tabela detalhada de vendas.'
} else {
    Write-Host 'ATENCAO: nem tudo aplicado. Reverta com:'
    Write-Host ('   Copy-Item ' + $arquivo + '.bakplaca ' + $arquivo + ' -Force')
}
