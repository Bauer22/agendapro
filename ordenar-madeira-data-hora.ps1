$arquivo = 'src\app\pages\WoodPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakhora') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakhora')

$txt = Get-Content $arquivo -Raw

if ($txt -match "sortWoodDetalhe") {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

# Ordenacao atual (por created_at) - texto exato a ser substituido
$de = "[...rep].sort((a,b)=>((a.created_at||a.data_entrada||'')+'').localeCompare((b.created_at||b.data_entrada||'')+''))"

# Nova ordenacao: data_entrada asc; empate -> hora de descarga (unload_time, fallback arrival_time) asc
$para = "[...rep].sort(function sortWoodDetalhe(a,b){ var da=(a.data_entrada||'')+''; var db=(b.data_entrada||'')+''; if(da!==db) return da.localeCompare(db); var ha=((a.unload_time||a.arrival_time||'')+''); var hb=((b.unload_time||b.arrival_time||'')+''); return ha.localeCompare(hb); })"

$ocorrencias = ([regex]::Matches($txt, [regex]::Escape($de))).Count
Write-Host ('Ocorrencias da ancora encontradas: ' + $ocorrencias)

if ($ocorrencias -eq 1) {
    $txt = $txt.Replace($de, $para)
    Set-Content -Path $arquivo -Value $txt -NoNewline
    Write-Host 'OK - ordenacao agora por data e hora de descarga (menor para maior).'
    Write-Host ('Marcador presente: ' + ($txt -match "sortWoodDetalhe"))
} elseif ($ocorrencias -eq 0) {
    Write-Host 'ATENCAO: nao encontrei a ordenacao atual por created_at. Nada alterado.'
    Write-Host 'Me avise para ajustar a ancora.'
} else {
    Write-Host 'ATENCAO: ancora aparece mais de uma vez. Nao alterei.'
}
