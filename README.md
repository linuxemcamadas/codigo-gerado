# Planta Cenário:

Para plantar o cenário que precisamos:

Na máquina virtual que usaremos para fazer as análises Forense, siga os seguintes passos:

Baixe o script plantar_cenario.sh

Abra o terminal no mesmo diretório em que está o arquivo e digite: 

sudo chmod +x plantar_cenario.sh

Execute no terminal da seguinte forma:

./plantar_cenario.sh


Saída esperada (trecho):
[*] Iniciando plantio do cenário investigativo...
[*] Verificando dependências...
[+] Dependências verificadas.
[*] Ativando journal persistente...
[+] Journal persistente ativado, logs sobreviverão ao reboot.
[*] Criando usuário 'maria'...
[+] Usuário 'maria' criado.
...
[+] Cenário plantado com sucesso!

  Usuário vítima : maria (senha: SenhaForte2026!)
  Documentos     : /home/maria/Documentos
  Downloads      : /home/maria/Downloads
  Imagens        : /home/maria/Imagens
  Histórico      : /home/maria/.mozilla/firefox/abc123.default
  Serviço        : update-service.service
