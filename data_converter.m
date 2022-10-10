% init
clear; clc;

% Convert FDT data (original)
fdt_data = readtable("GFP_Data\TransferFunction_fast_tau4_new.dat");
fdt_data = table2array(fdt_data);

count_inj = unique(fdt_data(:, 2));
num_rows = sum(~isnan(count_inj));
count_inj = count_inj(~isnan(count_inj));

fdt_channels = nan(num_rows, 32);
ch_number = (0:1:31);

for i = ch_number
    fdt_single_ch = fdt_data(fdt_data(:, 4) == i, :);
    fdt_ch_single_ch = fdt_single_ch(:, 5);

    % mean by energy for a single channels
    fdt_single = nan(55, 1);
    for j = 1:100:5500
        fdt_single(round((j/100)-0.01)+1, 1) = round(mean(fdt_ch_single_ch(j:j+99)), 2);
    end
    fdt_channels(:, i+1) = fdt_single;
end

f = figure('Visible','on')
plot(count_inj, fdt_channels(:, 31))

% export fdt (channels on columns)
labels = ["Energy_IN", string(ch_number)];
data_out = array2table([count_inj, fdt_channels], 'VariableNames', labels);
writetable(data_out, 'output/fdt_data.dat', 'Delimiter', '\t')


%% prova read

data = readtable("output\fdt_data_old.dat")

%%

%f = figure('Visible', 'on');
%plot(count_inj, fdt_channels(:, 31))