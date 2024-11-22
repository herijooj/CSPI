#include "c_ctl.h"
#include <stdio.h>
#include <stdlib.h>
#include "func.h"
#include <math.h>
#include <gsl/gsl_cdf.h>
#include <gsl/gsl_sf_psi.h>
#include <gsl/gsl_sf_gamma.h>

void estima_parametros_gamma(datatype *dados, size_t n, datatype *alpha, datatype *beta) {
    // Calcular a média dos dados
    datatype soma = 0.0;
    for (size_t i = 0; i < n; i++) {
        soma += dados[i];
    }
    datatype media = soma / n;

    // Calcular o logaritmo dos dados
    datatype soma_log = 0.0;
    int count = 0;
    for (size_t i = 0; i < n; i++) {
        if (dados[i] > 0) {
            soma_log += log(dados[i]);
            count++;
        }
    }

    if (count == 0) {
        // Caso não haja dados positivos, definir alpha e beta como valores mínimos positivos
        *alpha = 0.1;
        *beta = 0.1;
        return;
    }

    datatype media_log = soma_log / count;

    // Estimar alpha usando o método dos momentos modificado
    datatype numerador = media - media_log;
    if (numerador == 0) {
        numerador = 0.0001; // Evitar divisão por zero
    }

    *alpha = (0.5) / numerador;

    if (*alpha <= 0) {
        *alpha = 0.1; // Definir um valor mínimo positivo
    }

    // Estimar beta
    *beta = media / (*alpha);
    if (*beta <= 0) {
        *beta = 0.1; // Definir um valor mínimo positivo
    }
}

void estima_parametros_pearson(datatype *dados, size_t n, datatype *alpha, datatype *beta) {
    // Calcular a média dos dados
    datatype soma = 0.0;
    for (size_t i = 0; i < n; i++) {
        soma += dados[i];
    }
    datatype media = soma / n;

    // Calcular o desvio padrão
    datatype soma_quadrado = 0.0;
    for (size_t i = 0; i < n; i++) {
        soma_quadrado += pow(dados[i] - media, 2);
    }
    datatype desvio_padrao = sqrt(soma_quadrado / (n - 1));

    // Calcular o coeficiente de assimetria
    datatype soma_cubo = 0.0;
    for (size_t i = 0; i < n; i++) {
        soma_cubo += pow(dados[i] - media, 3);
    }
    datatype coeficiente_assimetria = (soma_cubo / n) / pow(desvio_padrao, 3);

    // Estimar alpha e beta
    if (coeficiente_assimetria == 0.0 || isnan(coeficiente_assimetria)) {
        // Caso o coeficiente de assimetria seja zero ou indefinido,
        // atribuir valores mínimos positivos para evitar divisão por zero
        *alpha = 0.1;
        *beta = desvio_padrao > 0 ? desvio_padrao : 0.1;
    } else {
        *alpha = (4.0) / (coeficiente_assimetria * coeficiente_assimetria);
        *beta = desvio_padrao * coeficiente_assimetria / 2.0;
    }

    // Ajustar alpha e beta caso sejam zero ou negativos
    if (*alpha <= 0.0 || isnan(*alpha)) {
        *alpha = 0.1;
    }
    if (*beta == 0.0 || isnan(*beta)) {
        *beta = 0.0001;
    } else if (*beta < 0.0) {
        *beta = fabs(*beta);
    }
}

void calculo_spi(binary_data *input_data, binary_data *output_data, int n_meses_spi, int dist_flag) {
    size_t nx = input_data->info.x.def;
    size_t ny = input_data->info.y.def;
    size_t nt = input_data->info.tdef;

    // Para cada ponto da grade
    for (size_t ix = 0; ix < nx; ix++) {
        for (size_t iy = 0; iy < ny; iy++) {
            // Série temporal de precipitação acumulada
            size_t serie_size = nt - n_meses_spi + 1;
            datatype *serie_acumulada = malloc(serie_size * sizeof(datatype));

            // Calcular a precipitação acumulada
            for (size_t it = 0; it < serie_size; it++) {
                datatype soma = 0.0;
                for (int k = 0; k < n_meses_spi; k++) {
                    size_t pos = get_pos(&input_data->info, ix, iy, it + k);
                    soma += input_data->data[pos];
                }
                serie_acumulada[it] = soma;
            }

            // Estimar os parâmetros da distribuição escolhida
            datatype alpha = 0.0, beta = 0.0;
            if (dist_flag == 0) {
                // Distribuição Gamma
                estima_parametros_gamma(serie_acumulada, serie_size, &alpha, &beta);
            } else {
                // Distribuição de Pearson Tipo III
                estima_parametros_pearson(serie_acumulada, serie_size, &alpha, &beta);
            }

            // Calcular o SPI
            for (size_t it = 0; it < serie_size; it++) {
                datatype x = serie_acumulada[it];
                if (x < 0) {
                    x = 0.0; // Garantir que x não seja negativo
                }

                datatype prob = 0.0;
                if (dist_flag == 0) {
                    // Usando distribuição Gamma
                    prob = gsl_cdf_gamma_P(x, alpha, beta);
                } else {
                    // Usando distribuição de Pearson Tipo III
                    // Converter para distribuição Gamma equivalente
                    datatype z = (x - alpha) / beta;

                    // Garantir que z não seja negativo
                    if (z < 0.0 || isnan(z)) {
                        z = 0.0;
                    }

                    prob = gsl_sf_gamma_inc_P(alpha, z);
                }

                // Evitar valores extremos
                if (prob > 0.999999)
                    prob = 0.999999;
                else if (prob < 0.000001)
                    prob = 0.000001;

                // Converter para SPI
                datatype spi = gsl_cdf_ugaussian_Pinv(prob);

                // Armazenar o valor no output_data
                size_t pos = get_pos(&output_data->info, ix, iy, it + n_meses_spi - 1);
                output_data->data[pos] = spi;
            }

            free(serie_acumulada);
        }
    }
}