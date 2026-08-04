$arquivo = 'src\app\pages\SalesPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakmot') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakmot')

$txt = Get-Content $arquivo -Raw

if ($txt -match "'Cliente','Motorista','Produto'") {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

$c1 = $false; $c2 = $false

# 1) Cabecalho: adiciona 'Motorista' depois de 'Cliente'
$de1 = "head: [['Romaneio','NF','Data','Cliente','Produto','Ton'"
$para1 = "head: [['Romaneio','NF','Data','Cliente','Motorista','Produto','Ton'"
if ($txt.Contains($de1)) { $txt = $txt.Replace($de1, $para1); $c1 = $true }

# 2) Corpo: adiciona o.driver depois de o.client_name
$de2 = "fmtD(o.sale_date), o.client_name||'" + [char]0x2014 + "', o.product_name||'" + [char]0x2014 + "',"
$para2 = "fmtD(o.sale_date), o.client_name||'" + [char]0x2014 + "', o.driver||'" + [char]0x2014 + "', o.product_name||'" + [char]0x2014 + "',"
if ($txt.Contains($de2)) {
    $txt = $txt.Replace($de2, $para2); $c2 = $true
} else {
    # fallback via regex, sem depender do caractere travessao exato
    $rx = "fmtD\(o\.sale_date\), o\.client_name\|\|'.{1,3}', o\.product_name\|\|'(.{1,3})',"
    $m = [regex]::Match($txt, $rx)
    if ($m.Success) {
        $trav = $m.Groups[1].Value
        $novo = "fmtD(o.sale_date), o.client_name||'" + $trav + "', o.driver||'" + $trav + "', o.product_name||'" + $trav + "',"
        $txt = $txt.Replace($m.Value, $novo); $c2 = $true
    }
}

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('1) Cabecalho: ' + $c1)
Write-Host ('2) Corpo (o.driver): ' + $c2)
Write-Host ''
if ($c1 -and $c2) {
    Write-Host 'OK - coluna Motorista adicionada na tabela detalhada de vendas.'
} else {
    Write-Host 'ATENCAO: nem tudo aplicado. Reverta com:'
    Write-Host ('   Copy-Item ' + $arquivo + '.bakmot ' + $arquivo + ' -Force')
}
