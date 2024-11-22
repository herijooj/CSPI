#include "c_ctl.h"
#include "func.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc != 4) {
        printf("Uso: %s <arquivo.ctl> <N_MESES_SPI> <distribuicao>\n", argv[0]);
        printf("Distribuição: 'gamma' ou 'pearson'\n");
        return 1;
    }

    char *ctl_file = argv[1];
    int n_meses_spi = atoi(argv[2]);
    char *distrib = argv[3];

    printf("Arquivo .ctl: %s\n", ctl_file);
    printf("Número de meses para SPI: %d\n", n_meses_spi);
    printf("Distribuição escolhida: %s\n", distrib);

    // Carrega os dados do arquivo .ctl de entrada
    binary_data *input_data = open_bin_ctl(ctl_file);
    if (!input_data) {
        fprintf(stderr, "Erro ao abrir o arquivo .ctl de entrada.\n");
        return 1;
    }
    printf("Arquivo .ctl de entrada carregado com sucesso.\n");

    // Cria um novo CTL para saída
    binary_data *output_data = aloca_bin(input_data->info.x.def, 
                                        input_data->info.y.def, 
                                        input_data->info.tdef);
    if (!output_data) {
        fprintf(stderr, "Erro ao alocar memória para dados de saída.\n");
        free_bin(input_data);
        return 1;
    }

    // Copia as informações do CTL de entrada para o de saída
    cp_ctl(&output_data->info, &input_data->info);

    // Inicializa os dados de saída com UNDEF
    for (size_t i = 0; i < output_data->info.x.def * output_data->info.y.def * output_data->info.tdef; i++) {
        output_data->data[i] = output_data->info.undef;
    }

    // Verifica a distribuição escolhida
    int dist_flag = 0; // 0 para Gamma, 1 para Pearson
    if (strcmp(distrib, "gamma") == 0) {
        dist_flag = 0;
    } else if (strcmp(distrib, "pearson") == 0) {
        dist_flag = 1;
    } else {
        fprintf(stderr, "Distribuição inválida. Escolha 'gamma' ou 'pearson'.\n");
        free_bin(input_data);
        free_bin(output_data);
        return 1;
    }

    // Calcula o SPI
    printf("Iniciando cálculo do SPI usando distribuição %s...\n", distrib);
    calculo_spi(input_data, output_data, n_meses_spi, dist_flag);
    printf("Cálculo do SPI concluído.\n");

    // Cria o nome do arquivo de saída
    printf("Gerando nome do arquivo de saída...\n");
    char output_filename[256];
    char *base_name = strrchr(ctl_file, '/');
    base_name = base_name ? base_name + 1 : ctl_file;
    char *dot = strrchr(base_name, '.');
    if (dot) *dot = '\0';
    snprintf(output_filename, sizeof(output_filename), "%s_SPI%d_%s", base_name, n_meses_spi, distrib);
    printf("Arquivo de saída: %s\n", output_filename);

    // Salva os resultados
    printf("Salvando os resultados...\n");
    write_files(output_data, output_filename, "SPI");
    printf("Resultados salvos com sucesso.\n");

    // Libera a memória
    free_bin(input_data);
    free_bin(output_data);
    printf("Memória liberada. Execução concluída.\n");

    return 0;
}
