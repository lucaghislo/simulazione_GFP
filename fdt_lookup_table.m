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


%% Spline interpolazione cubica per un  singolo canale (ch. 10, PT4)
% Senza sottrazione del pedestal

clear; clc;
load fdt_lookup_table\dac_values.mat

% X data
load fdt_lookup_table\dac_values.mat
muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");
muon_events_ch10 = muon_data.Energy_ADC_(muon_data.Channel == 10);

% Y data
fdt_data = readtable("fdt_lookup_table\fdt_allpts\fdt_allch_pt4.dat");
ch10_data = fdt_data(:, 10+1);
ch10_data = table2array(ch10_data);

spline_res = spline(dac_values, ch10_data, [0:0.01:64000]);
events_kev = interp1(spline_res, [0:0.01:64000], muon_events_ch10, 'cubic') * 0.841;

f = figure("Visible", "on");
hold on
h1 = histogram(muon_events_ch10, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1)
h2 = histogram(events_kev, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1)

box on
grid on
set(gca, 'YScale', 'log')
xlim([0, 3000])
legend([h1, h2], "Events in ADU", "Events in keV")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];

exportgraphics(gcf, "fdt_lookup_table\output\muon_energy_deposition_ch10_pt4.pdf", 'ContentType', 'vector');  


%% Read fdt for all PTs and interpolate spline
% Senza sottrazione del pedestal

clearvars -except max_ch max_tau; clc;
load fdt_lookup_table\dac_values.mat
dac_values = dac_values';

muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");

min_DACinj = 0;
max_DACinj = 64000;
step_DACinj = 1;
range = [min_DACinj:step_DACinj:max_DACinj]';
ch_values = [0:31];

for pt = 4
    
    spline_allchs_pt = nan(length(range), 32);

    for ch = [0:31]
        fdt_data = readtable("fdt_lookup_table\fdt_allpts\fdt_allch_pt" + string(pt) + ".dat");
        fdt_data_ch = fdt_data(:, ch + 1);
        fdt_data_ch = table2array(fdt_data_ch);

        spline_allchs_pt(:, ch + 1) = interp1(dac_values, fdt_data_ch, range, 'spline');

        [val, idx] = unique(spline_allchs_pt(:, ch + 1));

        for i = 1:length(spline_allchs_pt(:, ch + 1))
            if isempty(find(idx==i))
               spline_allchs_pt(i, ch + 1) = spline_allchs_pt(i, ch + 1) + step_DACinj/2;
            end
        end
    end
end


%% Convert muon data (ADU -> keV)

clearvars -except spline_allchs_pt range;

muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");

muon_allch = nan(9528, 32);

for ch = [0:31]
    muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch);
    events_kev = interp1(spline_allchs_pt(:, ch + 1), range, muon_data_ch_ADU, 'cubic') * 0.841;
    muon_allch(:, ch+1) = events_kev;
end

muon_allch = reshape(muon_allch', [], 1);

f = figure("Visible", "on");
histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1);
%histfitlandau(muon_allch(muon_allch>100), 15, 0, 6000, 1)

box on
grid on
set(gca, 'YScale', 'log')
xlim([0, 6000])
ylabel("\textbf{Counts}")
xlabel("\textbf{Incoming energy [keV]}")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];

exportgraphics(gcf,"fdt_lookup_table\output\muon_detection_self_trigger_1hr_pt4.pdf",'ContentType','vector');