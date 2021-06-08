# weeb
Compilador usando flex/lex and yacc/bison transformando da linguagem weeb para C.

Foi utilizado o sistema operacional Windows 10 para a execução do bison, flex e o compilador gcc. 

## Configurando o ambiente

1. Baixe o Complete package do [Bison](http://gnuwin32.sourceforge.net/packages/bison.htm)
2. Baixe o Complete package do [Flex](http://gnuwin32.sourceforge.net/packages/flex.htm)
3. Coloque o path da instalação do GnuWin32 nas variáveis de ambiente. Aconselhável utilizar a pasta raiz. Ex.: C:\GnuWin32\bin
4. Siga esse tutorial -> [Como instalar o gcc no windows 10 de maneira fácil](https://dev.to/gamegods3/how-to-install-gcc-in-windows-10-the-easier-way-422j)
5. Coloque o path da instalação do MinGW nas variáveis de ambiente. Aconselhável utilizar a pasta raiz. Ex.: C:\MinGW\bin

## Executando o projeto

Há duas opções, caso tenha seguido os passos anteriores e seja o windows 10, já se tem um Makefile. Rode:
```shell
make -f win_make
```

Caso tenha sido de outra forma:

1. Para fazer o parser
  ```shell
  bison -d code.y
  ```
  ```shell
  flex code.l
  ```
  ```shell
  gcc y.tab.c lex.yy.c -o code
  ```
2. Para executar o parser, precisa passar para ele o arquivo de entrada e o arquivo de saída como parâmetro. O projeto já tem um arquivo de input como exemplo.
  ```shell
  code input.weeb output.c
  ```
3. Para compilar o programa em C gerado no passo anterior
  ```shell
  gcc output.c
  ```

### Importante!!! Sempre que for executar o projeto de novo, deletar os arquivos gerados durante o processo para não ter conflitos

## Linguagem weeb

### Declarações de variáveis

A linguagem aceita inteiro e ponto flutuante:

`inteiro x`

`flutuante y`

É necessário declarar as variáveis antes de atribuir valor a elas.

### Operações básicas

A linguagem weeb aceita as operações de:
1. Soma e subtração
2. Produto e divisão
3. Atribuição: `y = 10.32`

### Fluxo de controle

Uma condição simples é da forma:

```
se expressão [
  instrução]
```

Caso seja preciso uma alternativa à condição:

```
se expressão [
  instrução ]
senao[
  instrução ]
```
Sendo que uma instrução pode ser um bloco de instruções
Importante observar a localização dos colchetes. Se tentar um código como mostrado abaixo, todos estariam errados e o código em weeb não funcionará:
```
se expressão 
[
  instrução
]
senao
[ instrução 
]
```

Ou seja, o primeiro colchete está logo após a expressão, e o último, está logo após da última instrução.

#### Operações de comparação

A linguagem aceita operações de comparação
1. Maior ou igual:
`x >= y`
2. Menor ou igual:
`x <= y`
2. Igualdade:
`x =?= y`
2. Diferença:
`x =/= y`

### Estrutura de repetição

A linguagem aceita apenas um tipo de estrutura de repetição:
```
enquanto expressão[
  instrução]
```

Essa estrutura segue a mesma regra das condições quanto aos colchetes.

### Métodos de entrada e saída

Para ler uma variável, e atribuir o valor lido a ela, e escrever seu valor, seria da forma:
```
inteiro x
ler x
escrever x
```

Pode-se escrever uma string também:
```
escrever "Ola mundo"
```
