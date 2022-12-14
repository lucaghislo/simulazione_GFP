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
save fdt_lookup_table\range.mat range;
writetable(array2table(range), "fdt_lookup_table\range.dat", "Delimiter", "\t");
ch_values = [0:31];

for pt = [0:7]
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

    spline_allchs_pt_table = array2table(spline_allchs_pt);
    writetable(spline_allchs_pt_table, "fdt_lookup_table\output\lookup_tables\lookup_table_allch_pt" + string(pt) + ".dat", "Delimiter", "\t");
end


%% Plot FDT with pedestal

clear; clc;

min_DACinj = 0;
max_DACinj = 64000;
step_DACinj = 1;
range = [min_DACinj:step_DACinj:max_DACinj]';
ch_values = [0:31];

spline_allchs_pt4 = readtable("fdt_lookup_table\output\lookup_tables\lookup_table_allch_pt4.dat");
spline_allchs_pt4 = table2array(spline_allchs_pt4);

f = figure("Visible", "on")
hold on
for ch = [0:31]
    plot(range.*0.841, spline_allchs_pt4(:, ch+1).*0.841);
end
hold off

box on
grid on
xlabel('\textbf{Incoming energy [MeV]}');
ylabel('\textbf{Channel Output [ADU]}');
ylim([0 1400])
xlim([0, 53824]);
xticks([0:10000:50000])
xticklabels([0:10:50])
yticks([0:200:1400])
set(gcf, 'Color', 'w');
title("\textbf{Transfer function without pedestal subtracted}")

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf,"fdt_lookup_table\output\fdt_allch_pt4.pdf",'ContentType','vector');


%% Convert muon data (ADU -> keV) [all events, no landau fit]

clearvars -except spline_allchs_pt range;

load fdt_lookup_table\range.mat;
muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");
spline_allchs_pt = readtable("fdt_lookup_table\output\lookup_tables\lookup_table_allch_pt4.dat");
spline_allchs_pt = table2array(spline_allchs_pt);

muon_allch = nan(9528, 32);

for ch = [0:31]
    muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch);
    events_kev = interp1(spline_allchs_pt(:, ch + 1), range, muon_data_ch_ADU, 'cubic') * 0.841;
    muon_allch(:, ch+1) = events_kev;
end

muon_allch = reshape(muon_allch', [], 1);

f = figure("Visible", "on");
histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1);

box on
grid on
set(gca, 'YScale', 'log')
xlim([0, 6000])
ylabel("\textbf{Counts}")
xlabel("\textbf{Incoming energy [keV]}")
title("\textbf{Incoming energy spectrum after conversion without pedestal subtraction}")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];

exportgraphics(gcf,"fdt_lookup_table\output\muon_detection_self_trigger_1hr_pt4.pdf",'ContentType','vector');


%% Convert muon data (ADU -> keV) [landau fit]

clear; clc;

load fdt_lookup_table\range.mat;
muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");
spline_allchs_pt = readtable("fdt_lookup_table\output\lookup_tables\lookup_table_allch_pt4.dat");
spline_allchs_pt = table2array(spline_allchs_pt);

muon_allch = nan(9528, 32);

for ch = [0:31]
    muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch);
    events_kev = interp1(spline_allchs_pt(:, ch + 1), range, muon_data_ch_ADU, 'cubic') * 0.841;
    muon_allch(:, ch+1) = events_kev;
end

muon_allch = reshape(muon_allch', [], 1);

f = figure("Visible", "on");
histfitlandau(muon_allch(muon_allch>100), 20, 0, 6000, 1)

box on
grid on
xlim([0, 6000])
ylabel("\textbf{Counts}")
xlabel("\textbf{Incoming energy [keV]}")
title("\textbf{Energy spectrum without pedestal subtraction}")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];

exportgraphics(gcf,"fdt_lookup_table\output\muon_detection_self_trigger_1hr_pt4_landau.pdf",'ContentType','vector');


%% Read fdt for all PTs and interpolate spline
% Con sottrazione del pedestal

clearvars -except max_ch max_tau; clc;
load fdt_lookup_table\dac_values.mat
dac_values = dac_values';
dac_values = array2table(dac_values);
writetable(dac_values, "fdt_lookup_table\dac_values.dat");

pedestal_allch_allpt = readtable("fdt_lookup_table\pedestal_no_injection\pedestal_meas_allpt_allch.dat");
pedestal_allch_allpt = table2array(pedestal_allch_allpt);
muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");

min_DACinj = 0;
max_DACinj = 64000;
step_DACinj = 1;
range = [min_DACinj:step_DACinj:max_DACinj]';
ch_values = [0:31];

for pt = [4]
    spline_allchs_pt = nan(length(range), 32);

    for ch = [0:31]
        fdt_data = readtable("fdt_lookup_table\fdt_allpts\fdt_allch_pt" + string(pt) + ".dat");
        fdt_data_ch = fdt_data(:, ch + 1);
        fdt_data_ch = table2array(fdt_data_ch);
        fdt_data_ch = fdt_data_ch - pedestal_allch_allpt(ch+1, pt+1);

        spline_allchs_pt(:, ch + 1) = interp1(dac_values, fdt_data_ch, range, 'spline');

        [val, idx] = unique(spline_allchs_pt(:, ch + 1));

        for i = 1:length(spline_allchs_pt(:, ch + 1))
            if isempty(find(idx==i))
               spline_allchs_pt(i, ch + 1) = spline_allchs_pt(i, ch + 1) + step_DACinj/2;
            end
        end
    end

    spline_allchs_pt_table = array2table(spline_allchs_pt);
    writetable(spline_allchs_pt_table, "fdt_lookup_table\output\lookup_tables_no-ped\lookup_table_no-ped_allch_pt" + string(pt) + ".dat", "Delimiter", "\t");
end


%% Plot FDT with no pedestal

clear; clc;

min_DACinj = 0;
max_DACinj = 64000;
step_DACinj = 1;
range = [min_DACinj:step_DACinj:max_DACinj]';
ch_values = [0:31];

spline_allchs_pt4 = readtable("fdt_lookup_table\output\lookup_tables_no-ped\lookup_table_no-ped_allch_pt4.dat");
spline_allchs_pt4 = table2array(spline_allchs_pt4);

f = figure("Visible", "on")
hold on
for ch = [0:31]
    plot(range.*0.841, spline_allchs_pt4(:, ch+1).*0.841);
end
hold off

box on
grid on
xlabel('\textbf{Incoming energy [MeV]}');
ylabel('\textbf{Channel Output [ADU]}');
ylim([0 1400])
xlim([0, 53824]);
xticks([0:10000:50000])
xticklabels([0:10:50])
yticks([0:200:1400])
set(gcf, 'Color', 'w');
title("\textbf{Transfer function with pedestal subtracted}")

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf,"fdt_lookup_table\output\fdt_allch_pt4_no-pedestal.pdf",'ContentType','vector');



%% Convert muon data (ADU -> keV) [all events, no landau fit] (FDT sottratta del pedestal)

clearvars -except spline_allchs_pt range;

load fdt_lookup_table\range.mat;
muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");
spline_allchs_pt = readtable("fdt_lookup_table\output\lookup_tables_no-ped\lookup_table_no-ped_allch_pt4.dat");
spline_allchs_pt = table2array(spline_allchs_pt);

pedestal_allch_allpt = readtable("fdt_lookup_table\pedestal_no_injection\pedestal_meas_allpt_allch.dat");
pedestal_allch_allpt = table2array(pedestal_allch_allpt);

muon_allch = nan(9528, 32);

for ch = [0:31]
    muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch) - pedestal_allch_allpt(ch+1, 4+1);
    events_kev = interp1(spline_allchs_pt(:, ch + 1), range, muon_data_ch_ADU, 'cubic') * 0.841;
    muon_allch(:, ch+1) = events_kev;
end

muon_allch = reshape(muon_allch', [], 1);

f = figure("Visible", "on");
histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1);

box on
grid on
set(gca, 'YScale', 'log')
xlim([0, 6000])
ylabel("\textbf{Counts}")
xlabel("\textbf{Incoming energy [keV]}")
title("\textbf{Energy spectrum after conversion with pedestal subtraction}")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];

exportgraphics(gcf,"fdt_lookup_table\output\muon_detection_self_trigger_1hr_pt4_no-ped.pdf",'ContentType','vector');


%% Convert muon data (ADU -> keV) [landau fit] (FDT sottratta del pedestal)

clear; clc;

load fdt_lookup_table\range.mat;
muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");
spline_allchs_pt = readtable("fdt_lookup_table\output\lookup_tables_no-ped\lookup_table_no-ped_allch_pt4.dat");
spline_allchs_pt = table2array(spline_allchs_pt);

pedestal_allch_allpt = readtable("fdt_lookup_table\pedestal_no_injection\pedestal_meas_allpt_allch.dat");
pedestal_allch_allpt = table2array(pedestal_allch_allpt);

muon_allch = nan(9528, 32);

for ch = [0:31]
    muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch) - pedestal_allch_allpt(ch+1, 4+1);
    events_kev = interp1(spline_allchs_pt(:, ch + 1), range, muon_data_ch_ADU, 'cubic') * 0.841;
    muon_allch(:, ch+1) = events_kev;
end

muon_allch = reshape(muon_allch', [], 1);

f = figure("Visible", "on");
histfitlandau(muon_allch(muon_allch>100), 20, 0, 6000, 1)

box on
grid on
xlim([0, 6000])
ylabel("\textbf{Counts}")
xlabel("\textbf{Incoming energy [keV]}")
title("\textbf{Energy spectrum with pedestal subtraction}")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];

exportgraphics(gcf,"fdt_lookup_table\output\muon_detection_self_trigger_1hr_pt4_landau_no-ped.pdf",'ContentType','vector');


%% Istogramma eventi muoni in ADU prima della conversione

clear; clc;

muon_data = readtable("fdt_lookup_table\muon_data\self_trigger_1hr_THR_130_pt4_34.txt");

muon_allch = nan(9528, 32);

for ch = [0:31]
    muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch);
    muon_allch(:, ch+1) = muon_data_ch_ADU;
end

f = figure("Visible", "on");
histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1);

box on
grid on
set(gca, 'YScale', 'log')
xlim([0, 2047])
ylabel("\textbf{Counts}")
xlabel("\textbf{Incoming energy [ADU]}")
title("\textbf{Incoming energy spectrum before conversion}")

set(gca,'FontSize', 12)
f.Position = [10 30 1000  650];
exportgraphics(gcf,"fdt_lookup_table\output\muon_detection_self_trigger_1hr_pt4_ADU.pdf",'ContentType','vector');
