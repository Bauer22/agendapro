$arquivo = 'src\app\pages\SalesPage.tsx'

if (-not (Test-Path $arquivo)) { Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'; exit 1 }

Copy-Item $arquivo ($arquivo + '.bakexcl') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakexcl')

$txt = Get-Content $arquivo -Raw
$nl = [Environment]::NewLine

$c1 = $false; $c2 = $false

# 1) podeExcluir por origem (inclui ajustes account_adjustments)
$de1 = "const podeExcluir = l.tipo==='RECEBIMENTO' || l.tipo==='PAGAMENTO'"
$para1 = "const podeExcluir = ['client_payments','supplier_payments','account_adjustments'].includes(l.origem)"
if ($txt.Contains($de1)) { $txt = $txt.Replace($de1, $para1); $c1 = $true }

# 2) Trava de seguranca na deleteLancamento
$de2 = "  async function deleteLancamento(origem: string, id: string) {"
$para2 = $de2 + $nl + "    if (!['client_payments','supplier_payments','account_adjustments'].includes(origem)) { toast.error('Este lancamento so pode ser alterado na tela de origem'); return }"
if ($txt.Contains($de2)) { $txt = $txt.Replace($de2, $para2); $c2 = $true }

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('1) podeExcluir por origem: ' + $c1)
Write-Host ('2) trava de seguranca: ' + $c2)
Write-Host ''
if ($c1 -and $c2) {
    Write-Host 'OK - exclusao habilitada para recebimento, pagamento e ajuste (com trava de seguranca).'
} else {
    Write-Host 'ATENCAO: nem tudo aplicado. Reverta com:'
    Write-Host ('   Copy-Item ' + $arquivo + '.bakexcl ' + $arquivo + ' -Force')
}
