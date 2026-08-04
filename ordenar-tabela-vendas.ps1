$arquivo = 'src\app\pages\SalesPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakord') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakord')

$txt = Get-Content $arquivo -Raw

if ($txt -match "\[\.\.\.rep\]\.sort") {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

# Troca APENAS o body da tabela detalhada (azul): rep.map(o=>[String(o.romaneio_num
# por uma versao ordenada por sale_date crescente.
$de = "body: rep.map(o=>[String(o.romaneio_num"
$para = "body: [...rep].sort((a,b)=>(a.sale_date||'').localeCompare(b.sale_date||'')).map(o=>[String(o.romaneio_num"

if ($txt.Contains($de)) {
    $txt = $txt.Replace($de, $para)
    Set-Content -Path $arquivo -Value $txt -NoNewline
    Write-Host 'OK - tabela detalhada agora em ordem crescente por data.'
    Write-Host ('Marcador presente: ' + ($txt -match "\[\.\.\.rep\]\.sort"))
} else {
    Write-Host 'ATENCAO: nao encontrei a linha ancora. Nada alterado.'
}
