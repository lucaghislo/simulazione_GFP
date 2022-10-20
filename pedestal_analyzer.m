%% This script changes all interpreters from tex to latex. 

clear; clc;

list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end

max_tau = 7;
max_ch = 31; % cambiare in base al numero di canali testati fino ad ora
ch_step_inizio = [0, 8, 16, 24];


%% Import FDT data per channel

clearvars -except max_ch max_tau ch_step_inizio; clc;

for tau = [0:max_tau]

    fdt_pedestal_mean_inj = nan(32, 32);
    
    for channel = [0:max_ch] 

        if sum(any(ch_step_inizio(:) == channel)) > 0
            chinizio = channel;
            chfine = chinizio + 7;
        end

        data_raw = readtable("pedestal_analysis\input\ch" + string(chinizio) + "-" + string(chfine) + "\TransferFunction_ch" + string(channel) + "_tau" + string(tau) + ".dat");

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

        fdt_allch_table = array2table(fdt_allch);
        writetable(fdt_allch_table, "pedestal_analysis\output\data_transfer_function\fdt_tau" + string(tau) + "_ch" + string(channel) + "_injected.dat", "Delimiter", "\t", "WriteVariableNames", false);
    end

    fdt_pedestal_mean_inj_table = array2table(fdt_pedestal_mean_inj);
    writetable(fdt_pedestal_mean_inj_table, "pedestal_analysis\output\data_pedestal_injection\pedestal_injection_tau" + string(tau) + ".dat", "Delimiter", "\t", "WriteVariableNames", false);
end

save pedestal_analysis\output\dac_values.mat dac_values;


%% Plot FDT per channel

clearvars -except max_ch max_tau ch_step_inizio; clc;
load pedestal_analysis\output\dac_values.mat;
colors = distinguishable_colors(32, 'w');

for tau = [0:max_tau]
    for ch = [0:max_ch]
        data_ch = readtable("pedestal_analysis\output\data_transfer_function\fdt_tau" + string(tau) + "_ch" + string(ch) + "_injected.dat");
        data_ch = table2array(data_ch);
    
        f = figure("Visible", "off");
        legend_txt = cell(32,1);
        hold on
        for ch_fdt = [0:31]
            plot(dac_values, data_ch(ch_fdt+1, :), 'Color', [colors(ch_fdt + 1, 1), colors(ch_fdt + 1, 2), colors(ch_fdt + 1, 3)], 'LineWidth', 1);
            legend_txt{ch_fdt + 1} = string(ch_fdt);
        end
        hold off
        
        box on
        grid on
        xlabel('\textbf{Incoming energy [MeV]}');
        ylabel('\textbf{Channel Output [ADU]}');
        xlim([0, 53824]);
        ylim([0, 2000])
        xticks([0:10000:50000])
        xticklabels([0:10:50])
        title("\textbf{Channel " + string(ch) + " injected at \boldmath$\tau_{" + string(tau) + "}$}")

        hleg = legend(legend_txt, 'NumColumns', 2, 'Location', 'EastOutside');
        htitle = get(hleg,'Title');
        set(htitle,'String','\textbf{Channel}')

        set(gca,'FontSize', 12)
        f.Position = [10 30 1000  650];

        exportgraphics(gcf, "pedestal_analysis\output\fdt_plots\fdt_tau" + string(tau) + "_ch" + string(ch) + "_injected.pdf" , 'ContentType','vector');  
    end
end


%% Import pedestal measurements and plot comparison
% Piedistallo calcolato per ogni canale ad ogni tempo di picco
% Misura ripetuta per ogni set di canali

clearvars -except max_ch max_tau ch_step_inizio; clc;
ch_values = [0:31];
pedestal_allch_alltaus = nan(32, 8);

for tau = [0:max_tau]
    data = readtable("pedestal_analysis\input\ch0-7\Pedestals_tau" + string(tau) + ".dat");

    for channel = ch_values
        pedestal_allch_alltaus(channel + 1, tau + 1) = mean(data.Value(data.CH_ == channel));
    end
end

pedestal_allch_alltaus_table = array2table(pedestal_allch_alltaus),
writetable(pedestal_allch_alltaus_table, "pedestal_analysis\output\data_pedestal_measurement\pedestal_meas_allpt_allch.dat", "WriteVariableNames", false, "Delimiter", "\t");


%% Plot differenza piedistallo ENC/FDT

clearvars -except max_ch max_tau; clc;
colors = distinguishable_colors(3, 'w');

pedestal_meas_allpt = readtable("pedestal_analysis\output\data_pedestal_measurement\pedestal_meas_allpt_allch.dat");
pedestal_meas_allpt = table2array(pedestal_meas_allpt);

for tau = [0:max_tau]
    pedestal_fdt = readtable("pedestal_analysis\output\data_pedestal_injection\pedestal_injection_tau" + string(tau) + ".dat");
    pedestal_fdt = table2array(pedestal_fdt);
    pedestal_meas_pt = pedestal_meas_allpt(:, tau + 1);

    for ch_injected = [0:max_ch]
        pedestal_fdt_ch_inj = pedestal_fdt(:, ch_injected + 1);

        f = figure("Visible", "off");
        hold on
        plot([0:31], pedestal_meas_pt, "LineWidth", 1, "Marker", "o", "Color", [colors(1, 1), colors(1, 2), colors(1, 3)], "MarkerFaceColor", [colors(1, 1), colors(1, 2), colors(1, 3)]);
        plot([0:31], pedestal_fdt_ch_inj, "LineWidth", 1, "Marker", "o", "Color", [colors(2, 1), colors(2, 2), colors(2, 3)], "MarkerFaceColor", [colors(2, 1), colors(2, 2), colors(2, 3)]);
        plot([0:31], abs(pedestal_meas_pt - pedestal_fdt_ch_inj), "LineWidth", 1, "LineStyle", "--", "Color", [colors(3, 1), colors(3, 2), colors(3, 3)]);
        hold off

        box on
        grid on
        xlim([0 31]);
        ylim([0 300])
        xlabel("\textbf{Channel}")
        xlabel("\textbf{Channel}")
        legend("Pedestal evalueted from ENC", "Pedestal evaluated from FDT", "Pedestal difference");
        title("\textbf{Pedestal when injecting channel " + string(ch_injected) + " at \boldmath$\tau_{" + string(tau) + "}$}")

        set(gca,'FontSize', 12)
        f.Position = [10 30 1000  650];

        exportgraphics(gcf, "pedestal_analysis\output\plot_pedestal_difference\plot_pedestal_diff_tau" + string(tau) + "_ch" + string(ch_injected) + "_injected.pdf" , 'ContentType','vector');  
    end
end

