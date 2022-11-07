% This script changes all interpreters from tex to latex. 
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
warning('off','all')
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end

% Fattore di conversion DAC_inj_code to keV
conv_factor = 0.841;
% Range canali di interesse
ch_start = 0;
ch_finish = 31;
ch_values = [ch_start:ch_finish];

% Compute fdt data for each channel
dac_values_raw = readtable(fdt_data + "/Row0Module0Ch0.txt");
dac_values = unique(dac_values_raw.Cal_V);


fdt_data_allch = nan(length(dac_values), 32);
fdt_CAL10_allch = nan(32, 1);

% FDT calcolata solo sui canali di interesse
ch_count = 0;
for ch = ch_values
    filename = fdt_data + "/Row" + string(row) + "Module" + string(module) + "Ch" + string(ch) + ".txt";
    if isfile(filename)
        fdt_data_raw = readtable(filename);
        fdt_data_allch(:, ch_count + 1) = fdt_data_raw.ADC;
        fdt_CAL10_allch(ch+1, 1) = fdt_data_raw.ADC(fdt_data_raw.Cal_V == 10);
        ch_count = ch_count + 1;
    else
        ch_values = ch_values(ch_values~=ch);
        fdt_data_allch(:, ch_count + 1) = nan;
    end
end