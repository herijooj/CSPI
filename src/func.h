#ifndef FUNC_H
#define FUNC_H

#include "c_ctl.h"

void calculo_spi(binary_data *input_data, binary_data *output_data, int n_meses_spi, int dist_flag);

void estima_parametros_gamma(datatype *dados, size_t n, datatype *alpha, datatype *beta);

void estima_parametros_pearson(datatype *dados, size_t n, datatype *alpha, datatype *beta);

#endif // FUNC_H