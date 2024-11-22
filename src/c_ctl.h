// Biblioteca para Ler arquivos binários de chuva
// Para matrizes alocadas dinamicamente

#ifndef _CCTL_
#define _CCTL_

#include <stdlib.h>
#include <time.h>
#include <stdio.h>  // Adicionado para as declarações de impressão


// tipo do dado que será lido (usar `gcc -DDATATYPE=double` ao compilar para mudar tipo)
#ifndef DATATYPE
#define DATATYPE float
#endif

// https://stackoverflow.com/questions/40591312/c-macro-how-to-get-an-integer-value-into-a-string-literal
#define STR_IMPL_(x) #x      //stringify argument
#define STR(x) STR_IMPL_(x)  //indirection to expand argument macros


// Tamanho de vetores
#define STR_SIZE    256
#define BUFF_SIZE   512

// Cálculo de areas
#define MIN_X     0
#define MAX_X   360
#define MIN_Y   -90
#define MAX_Y    90


//      T_TYPE      // tipo de arquivo
#define T_YEAR  1   // dados anuais
#define T_MONTH 2   // dados mensais
#define T_DAY   3   // dados diários


#define safeFree(p) saferFree((void**)&(p))
// tipo de dado pode ser float ou double
typedef DATATYPE datatype;
typedef float coordtype;


// Armazena informações de coordenadas
typedef struct info_coord_struct{
    size_t def;     // tamanho
    coordtype i;    // ponto inicial
    coordtype f;    // ponto final
    coordtype size; // distancia até o proximo ponto
} info_coord;

// Armazena informações dos arquivos .ctl
typedef struct info_ctl_struct{
    char bin_filename[STR_SIZE];

    datatype undef;         // valor usado como indefinido
    
    info_coord x;           // informações de coordenada x
    info_coord y;           // informações de coordenada y

    size_t zdef;            // z level  (quantidade)
    size_t tdef;            // tempo    (quantidade)

    char ttype;             // Tipo     (mensal, diário, etc)

    struct tm date_i;       // data inicial
    int t_from_date_i;      // quantidade de passos t desde 01/01/0001

    char tdesc[STR_SIZE];   // tempo    (descrição)
    
    char dump[BUFF_SIZE];   // restante do arquivo 
} info_ctl;

// Armazena todas as informações de um arquivo de dados binários
typedef struct binary_data_struct{
    datatype* data;
    info_ctl info;
} binary_data;

int check_dim(binary_data *f1, binary_data *f2);

void saferFree(void **pp);
/* Abre o arquivo ctl 'name' e salva as informações em 'info_field'
 * retorna 1 em sucesso ou 0 em erro
**/
int open_ctl(info_ctl* info_field, char* name);

/* Escreve um arquivo ctl 'name' com as informações em 'info_field'
 * retorna 1 em sucesso ou 0 em erro
**/
int write_ctl(info_ctl* info_field, char* name, char* title);

/* Abre um arquivo .bin com as informações do arquivo .ctl 'name'
 * Retorna o ponteiro para a struct de dado, ou NULL em erro
**/
binary_data* open_bin_ctl(char* name);

/* Abre um arquivo .bin com as informações contidas na struct 'info'
 * Retorna o ponteiro para a struct de dado, ou NULL em erro
**/
binary_data* open_bin_info(info_ctl* info);

/* Abre um arquivo o .bin 'name' com as informações passadas por parametro
 * Retorna o ponteiro para a struct de dado, ou NULL em erro
**/
binary_data* open_bin(char* name, size_t x, size_t y, size_t t);

// Libera a alocação de 'bin_data'
binary_data* free_bin(binary_data* bin_data);

// Aloca a struct e a matriz de dado
binary_data* aloca_bin(size_t x, size_t y, size_t t);

// Imprime a matriz tridimensional na tela
void print_bin(binary_data* bin_data);

// Escreve um arquivo binário para a matriz 'bin_data'
int write_bin(binary_data* bin_data);

// Escreve um arquivo binário para a matriz 'bin_data' e arquivo ctl de nome 'name'
int write_files(binary_data* bin_data, char* name, char* title);

// Retorna o indice do vetor equivalente a posição da matriz (x,y,t)
size_t get_pos(info_ctl* info_field, size_t x, size_t y, size_t t);

// Converte a coordenada (x,y,t) da matriz de 'ref' para a quadrícula equivalente de 'src',
// Retorna o valor da quadrícula de 'src'. Retorna UNDEF de 'ref' se não existe equivalência.
datatype get_data_val(binary_data* ref, binary_data* src, size_t x, size_t y, size_t t);

// O valor de dest->data na posição (x,y,t) recebe 'value'
// Retorna o valor atribuído ou 'dest->info.undef' se (x,y,t) está fora da matriz
datatype set_data_val(binary_data* dest, int x, int y, int t, datatype value);

// Copia as informações de 'src' para 'dest'
void cp_coord(info_coord* dest, info_coord* src);

// Copia as informações de 'src' para 'dest'
void cp_ctl(info_ctl* dest, info_ctl* src);

// Copia as informações de data de 'src' para 'dest'
// ajusta demais valores
void cp_date_ctl(info_ctl* dest, info_ctl* src);

/* Copia o valor de 'src' para 'dest', recebendo a posição (x,y,t) de 'dest'
 * Se a coordenada convertida de 'dest' estiver fora da matriz de dados de 'src'
 * ou se o valor de src for indefinido
 * o valor copiado é 'dest->info.undef'.
 * Retorna o valor copiado.
**/
datatype cp_data_val(binary_data* dest, binary_data* src, int x, int y, int t);

/* Retorna 1 se a coordenada (x,y,t) está dentro dos limites de 'bin_data'
 * Retorna 0 caso contrário.
**/
int contains(binary_data* bin_data, size_t x, size_t y, size_t t);


// Retorna a quantidade de t's desde 01/01/0001 até a data inicial da estação (ctl->date_i)
int date_to_t(info_ctl* ctl);


/* Verifica se dois grids são compatíveis.
 * Retorna 1 se os dois são compatíveis, retorna 0 caso contrário.
**/
int compat_grid(info_ctl* a, info_ctl* b);


// Retorna o valor entre "limites circulares" (não sei o nome disso)
coordtype wrap_val(coordtype val, coordtype min, coordtype max);

/* Funções para cálculos utilizando datas
 * Feitas com ajuda do nosso querido ChatGPT
 * (que vai roubar nossos empregos no futuro)
=============================================
**/
//retorna 1 se ano eh bissexto, 0 caso contrario
int eh_bissexto(long int ano);

//retorna quantidade de dias desde o inicio do ano ate fim do mes anterior ao mes
//passado por argumento
int sum_days_till_month(int mes);

//retorna quantidade de dias passados desde o 01/01/0001 ate dia/mes/ano
int date_to_days(int dia, int mes, long int ano);

#endif
