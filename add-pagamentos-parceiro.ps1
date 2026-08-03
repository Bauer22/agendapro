# ============================================================
# add-pagamentos-parceiro.ps1
# Adiciona ao Relatorio de Parceiro (ReportsPage.tsx) uma tabela de
# Pagamentos e Recebimentos (Data, Tipo, Forma, Valor).
#
# Uso (no PowerShell, dentro de D:\sistema\agendapro-cmms):
#     powershell -ExecutionPolicy Bypass -File add-pagamentos-parceiro.ps1
# ============================================================

$arquivo = 'src\app\pages\ReportsPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host "ERRO: rode dentro de D:\sistema\agendapro-cmms" -ForegroundColor Red
    exit 1
}

# Backup
Copy-Item $arquivo "$arquivo.bakpag2" -Force
Write-Host "Backup criado: $arquivo.bakpag2"

$txt = Get-Content $arquivo -Raw

# Guarda-chuva: se ja foi aplicado, nao repete
if ($txt -match 'qRecebidoPar') {
    Write-Host "Ja parece ter sido aplicado (qRecebidoPar existe). Nada alterado." -ForegroundColor Yellow
    exit 0
}

# ---- 1) Adicionar queries logo apos a linha do qSaldo ----
$padraoSaldo = "(let qSaldo = supabase\.from\('v_saldo_conta_corrente'\)[^\r\n]*)"
$queries = @'
$1
        let qRecebidoPar = supabase.from('client_payments').select('*').ilike('client_name', parceiroNome).order('payment_date',{ascending:false})
        let qPagoPar = supabase.from('supplier_payments').select('*').ilike('supplier_name', parceiroNome).order('payment_date',{ascending:false})
        if (dateFrom) { qRecebidoPar = qRecebidoPar.gte('payment_date', dateFrom); qPagoPar = qPagoPar.gte('payment_date', dateFrom) }
        if (dateTo)   { qRecebidoPar = qRecebidoPar.lte('payment_date', dateTo);   qPagoPar = qPagoPar.lte('payment_date', dateTo) }
'@
$txt = [regex]::Replace($txt, $padraoSaldo, $queries)

# ---- 2) Incluir as 2 queries no Promise.all e capturar resultado ----
# Procura: const [ ... ] = await Promise.all([ ... ])
$mAll = [regex]::Match($txt, "const \[([^\]]+)\] = await Promise\.all\(\[([^\]]+)\]\)")
if ($mAll.Success) {
    $nomes = $mAll.Groups[1].Value.Trim()
    $qs    = $mAll.Groups[2].Value.Trim()
    $novo  = "const [$nomes, rRecebidoPar, rPagoPar] = await Promise.all([$qs, qRecebidoPar, qPagoPar])"
    $txt = $txt.Replace($mAll.Value, $novo)
} else {
    Write-Host "AVISO: nao encontrei o Promise.all — a tabela nao tera dados. Verifique manualmente." -ForegroundColor Yellow
}

# ---- 3) Inserir a tabela de pagamentos antes da secao de viagens ----
$blocoTabela = @'
        // -- Secao: Pagamentos e Recebimentos (data e valor) --
        var pagRowsPar = [];
        (rRecebidoPar && rRecebidoPar.data ? rRecebidoPar.data : []).forEach(function(p){
          pagRowsPar.push([
            p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-',
            'RECEBIMENTO',
            p.method || '-',
            'R$ ' + (Number(p.value)||0).toFixed(2)
          ]);
        });
        (rPagoPar && rPagoPar.data ? rPagoPar.data : []).forEach(function(p){
          pagRowsPar.push([
            p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-',
            'PAGAMENTO',
            p.method || '-',
            'R$ ' + (Number(p.value)||0).toFixed(2)
          ]);
        });
        if (pagRowsPar.length > 0) {
          y = (doc).lastAutoTable ? (doc).lastAutoTable.finalY + 8 : y + 8;
          doc.setFontSize(11); doc.setTextColor(0,0,0); doc.setFont('helvetica','bold');
          doc.text('Pagamentos e Recebimentos', 12, y);
          autoTable(doc, {
            startY: y + 3,
            head: [['Data','Tipo','Forma','Valor']],
            body: pagRowsPar,
            theme: 'striped',
            headStyles: { fillColor:[20,30,50], textColor:[255,255,255] },
            bodyStyles: { textColor:[20,20,20] },
            styles: { fontSize: 8 }
          });
        }

'@

# Ancora: o comentario/titulo das viagens. Tenta varios formatos.
$idx = $txt.IndexOf("Viagens por Motorista")
if ($idx -lt 0) { $idx = $txt.IndexOf("Viagens por motorista") }

if ($idx -ge 0) {
    # Recua ate o inicio da linha que contem a ancora
    $inicioLinha = $txt.LastIndexOf("`n", $idx) + 1
    # Recua mais, se a linha anterior for um comentario "// -- Secao 4" etc.
    $txt = $txt.Substring(0, $inicioLinha) + $blocoTabela + $txt.Substring($inicioLinha)
    $tabelaOk = $true
} else {
    Write-Host "AVISO: nao achei a ancora das viagens. Tabela NAO inserida." -ForegroundColor Yellow
    $tabelaOk = $false
}

# Salvar
Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ""
Write-Host "Queries adicionadas: $($txt -match 'qRecebidoPar')"
Write-Host "Promise.all atualizado: $($txt -match 'rRecebidoPar')"
Write-Host "Tabela inserida: $tabelaOk"
Write-Host ""
if (($txt -match 'qRecebidoPar') -and ($txt -match 'rRecebidoPar') -and $tabelaOk) {
    Write-Host "OK - relatorio de parceiro agora inclui Pagamentos e Recebimentos." -ForegroundColor Green
} else {
    Write-Host "ATENCAO: aplicacao incompleta. Para reverter:" -ForegroundColor Yellow
    Write-Host "   copy /Y `"$arquivo.bakpag2`" `"$arquivo`""
}
