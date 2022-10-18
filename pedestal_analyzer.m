%% This script changes all interpreters from tex to latex. 
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end


%% Import FDT data per channel

clear; clc;

for tau = [0:7]

    fdt_pedestal_mean_inj = nan(32, 32);
    
    for channel = [0:7] % cambiare in base al numero di canali testati fino ad ora
        data_raw = readtable("pedestal_analysis\ch0-7\TransferFunction_ch" + string(channel) + "_tau" + string(tau) + ".dat");

        dac_values = unique(data_raw.DAC);
        dac_values = dac_values(~isnan(dac_values))';
        ch_values = [0:31];
        
        fdt_allch = nan(length(ch_values), length(dac_values));
        dac_counter = 0;
        
        for dac = dac_values
            for ch = ch_values
                data_dac_ch = data_raw.Value(data_raw.DAC == dac & data_raw.CH_ == ch);
                fdt_allch(ch+1, dac_counter+1) = mean(data_dac_ch);
            end
            dac_counter = dac_counter + 1;
        end
        
        fdt_pedestal_mean_inj(:, channel + 1) = mean(fdt_allch, 2);
        fdt_pedestal_mean_inj(channel + 1, channel + 1) = nan;
    end

    fdt_pedestal_mean_inj_table = array2table(fdt_pedestal_mean_inj, "VariableNames", string(ch_values));
    writetable(fdt_pedestal_mean_inj_table, "pedestal_analysis\output\data_pedestal_injection\pedestal_injection_tau" + string(tau)".dat", "Delimiter", "\t");
end


%% Plot FDT per channel

f = figure("Visible", "on");
hold on
for ch = ch_values
    plot(dac_values(1:150), fdt_allch(ch+1, 1:150))
end
legend
hold off


%% Import pedestal

data = readtable("pedestal_analysis\Pedestals_tau0.dat");
ch_values = [0:31];

pedestal_allch = nan(32, 1);

for ch = ch_values
    pedestal_allch(ch+1) = mean(data.Value(data.CH_ == ch));
end

f = figure("Visible", "on");
hold on
plot(ch_values, pedestal_allch)
plot(ch_values(2:32), fdt_pedestal_mean(2:32))
plot(ch_values(2:32), abs(pedestal_allch(2:32) - fdt_pedestal_mean(2:32)))

disp(mean(abs(pedestal_allch(2:32) - fdt_pedestal_mean(2:32))))
disp(std(abs(pedestal_allch(2:32) - fdt_pedestal_mean(2:32))))
