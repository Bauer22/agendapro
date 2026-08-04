$arquivo = 'src\app\pages\WoodPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakseq') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakseq')

$txt = Get-Content $arquivo -Raw

if ($txt -match "a\.created_at\|\|a\.data_entrada") {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

# Troca a comparacao por data_entrada pela comparacao por created_at (com fallback data_entrada)
$de = "(a.data_entrada||'').localeCompare(b.data_entrada||'')"
$para = "((a.created_at||a.data_entrada||'')+'').localeCompare((b.created_at||b.data_entrada||'')+'')"

$ocorrencias = ([regex]::Matches($txt, [regex]::Escape($de))).Count
Write-Host ('Ocorrencias da ancora encontradas: ' + $ocorrencias)

if ($ocorrencias -eq 1) {
    $txt = $txt.Replace($de, $para)
    Set-Content -Path $arquivo -Value $txt -NoNewline
    Write-Host 'OK - tabela detalhada de madeira agora em ordem de lancamento (created_at).'
    Write-Host ('Marcador presente: ' + ($txt -match "a\.created_at\|\|a\.data_entrada"))
} elseif ($ocorrencias -eq 0) {
    Write-Host 'ATENCAO: nao encontrei a ancora (a ordenacao por data_entrada). Nada alterado.'
    Write-Host 'Talvez o script anterior nao tenha sido aplicado. Me avise.'
} else {
    Write-Host 'ATENCAO: a ancora aparece mais de uma vez. Nao alterei para evitar erro.'
}
