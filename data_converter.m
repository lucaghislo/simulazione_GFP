% init
clear; clc;

% Convert FDT data (original)
fdt_data = readtable("GFP_Data\TransferFunction_fast_tau4.dat");
fdt_data = table2array(fdt_data);

count_inj = unique(fdt_data(:, 2))
num_rows = sum(~isnan(count_inj))

fdt_channels = nan(num_rows, 32);