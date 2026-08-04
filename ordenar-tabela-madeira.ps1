$arquivo = 'src\app\pages\WoodPage.tsx'

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

# Ancora: o body da tabela detalhada de madeira.
# O padrao unico e "body: rep.map(e=>[" seguido (na proxima linha) de fmtD(e.data_entrada)
$de = "body: rep.map(e=>["
$para = "body: [...rep].sort((a,b)=>(a.data_entrada||'').localeCompare(b.data_entrada||'')).map(e=>["

# Garante que so existe UMA ocorrencia dessa ancora (evita trocar a errada)
$ocorrencias = ([regex]::Matches($txt, [regex]::Escape($de))).Count
Write-Host ('Ocorrencias da ancora encontradas: ' + $ocorrencias)

if ($ocorrencias -eq 1) {
    $txt = $txt.Replace($de, $para)
    Set-Content -Path $arquivo -Value $txt -NoNewline
    Write-Host 'OK - tabela detalhada de madeira agora em ordem crescente por data.'
    Write-Host ('Marcador presente: ' + ($txt -match "\[\.\.\.rep\]\.sort"))
} elseif ($ocorrencias -eq 0) {
    Write-Host 'ATENCAO: nao encontrei a ancora. Nada alterado.'
} else {
    Write-Host 'ATENCAO: a ancora aparece mais de uma vez. Nao alterei para evitar erro.'
    Write-Host 'Me avise para ajustar a ancora com mais precisao.'
}
