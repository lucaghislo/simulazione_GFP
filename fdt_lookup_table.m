%% This script changes all interpreters from tex to latex. 
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end

clear; clc;

max_tau = 7;
max_ch = 31; % cambiare in base al numero di canali testati fino ad ora
ch_step_inizio = [0, 8, 16, 24];


%% Build fdt for all channels and PTs
% Funzione di trasferimento valutata sull'intero range di energie per ogni
% tempo di picco considerando uno alla volta i canali su cui avviene
% l'iniezione

clearvars -except max_ch max_tau ch_step_inizio; clc;
load fdt_lookup_table\dac_values.mat

for tau = [0:max_tau] % max_tau

    fdt_allch_tau = nan(length(dac_values), 32);

    for channel = [0:max_ch] % max_ch 

        if sum(any(ch_step_inizio(:) == channel)) > 0
            chinizio = channel;
            chfine = chinizio + 7;
        end

        data_raw = readtable("pedestal_analysis\input\ch" + string(chinizio) + "-" + string(chfine) + "\TransferFunction_ch" + string(channel) + "_tau" + string(tau) + ".dat");
        dac_values = unique(data_raw.DAC);
        dac_values = dac_values(~isnan(dac_values))';
        ch_values = [0:31];

        fdt_allenergies = nan(length(dac_values), 1);
        dac_counter = 0;

        for dac = dac_values
            data_dac_ch = data_raw.Value(data_raw.DAC == dac & data_raw.CH_ == channel);
            fdt_allenergies(dac_counter+1, 1) = mean(data_dac_ch);
        
            dac_counter = dac_counter + 1;
        end

        fdt_allch_tau(:, channel + 1) = fdt_allenergies;
    end
        
    fdt_allch_tau_table = array2table(fdt_allch_tau);
    writetable(fdt_allch_tau_table, "fdt_lookup_table\fdt_allpts\fdt_allch_pt" + string(tau) + ".dat", "Delimiter", "\t");
    save fdt_lookup_table\dac_values.mat dac_values
end