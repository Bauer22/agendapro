$arquivo = 'src\app\app\page.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.baksadm') -Force
Write-Host ('Backup criado: ' + $arquivo + '.baksadm')

$txt = Get-Content $arquivo -Raw

if ($txt -match "n.id === 'superadmin' && profile") {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

$nl = [Environment]::NewLine

# Ancora: a linha que libera superadmin ver tudo
$ancora = "    if (profile?.role === 'superadmin') return true"

# Regra nova: barra o item superadmin para quem NAO e superadmin
$regra = "    if (n.id === 'superadmin' && profile?.role !== 'superadmin') return false"

if ($txt.Contains($ancora)) {
    $txt = $txt.Replace($ancora, $ancora + $nl + $regra)
    Set-Content -Path $arquivo -Value $txt -NoNewline
    Write-Host 'OK - regra adicionada.'
    Write-Host ('Marcador presente: ' + ($txt -match "n.id === 'superadmin' && profile"))
} else {
    Write-Host 'ATENCAO: nao encontrei a linha ancora. Nada alterado.'
}
