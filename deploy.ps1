Write-Host "1/4 -> Compilando o Flutter para Web..." -ForegroundColor Cyan
flutter build web --base-href "/controle-de-ponto/"

Write-Host "2/4 -> Copiando arquivos compilados para a raiz..." -ForegroundColor Cyan
Copy-Item -Path ".\build\web\*" -Destination ".\" -Recurse -Force

Write-Host "3/4 -> Adicionando arquivos ao Git..." -ForegroundColor Cyan
git add .
git commit -m "Deploy automatico: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"

Write-Host "4/4 -> Enviando para o GitHub Pages..." -ForegroundColor Cyan
git push origin main

Write-Host "Concluido! Seu site sera atualizado em instantes no GitHub Pages." -ForegroundColor Green