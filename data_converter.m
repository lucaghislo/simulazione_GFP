%% This script changes all interpreters from tex to latex.
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end


%% Convert FDT data (un file per ogni canale di ogni modulo)

clear; clc;

fdt_cal10 = nan(32, 36);
module_counter = 1;

for row = 0:5
    for mod = 0:5
        f = figure("Visible", "off");
        hold on
        for ch = 0:31
            if isfile("GFP_Data\transfer_functions\Row"+ string(row) +"Module" + string(mod) + "Ch" + string(ch) + ".txt")
                fdt_ch_data = readtable("GFP_Data\transfer_functions\Row"+ string(row) +"Module" + string(mod) + "Ch" + string(ch) + ".txt");
                plot(fdt_ch_data.Cal_V, fdt_ch_data.ADC);
                fdt_cal10(ch+1, module_counter) = fdt_ch_data.ADC(1);
            end
        end
        module_counter = module_counter + 1;
        hold off
        
        if isfile("GFP_Data\transfer_functions\Row"+ string(row) +"Module" + string(mod) + "Ch" + string(ch) + ".txt")
            box on
            grid on
            xlabel('\textbf{Incoming energy [MeV]}');
            ylabel('\textbf{Channel Output [ADU]}');
            xlim([0, 53824]);
            ylim([0 2000])
            xticks([0:10000:50000])
            xticklabels([0:10:50])
            yticks([0:200:2000])
            set(gcf, 'Color', 'w');
            title("\textbf{Transfer Function Module " + string(mod) + " Row " + string(row) + "}")
            
            ax = gca; 
            fontsize = 12;
            ax.XAxis.FontSize = fontsize; 
            ax.YAxis.FontSize = fontsize;
            ax.Title.FontSize = fontsize + 4;
            f.Position = [0 0 1200 800];
            
            exportgraphics(gcf,"output/plots/transfer_functions/fdt_row" + string(row) + "_mod" + string(mod) + "_allch.pdf",'ContentType','vector');
        end
    end
end

save GFP_Data/pedestal/computed/fdt_cal10_pedestal.mat fdt_cal10;
close all;


%% Istogrammi eventi (all channels together for all rows and modules) in ADU

clear; clc;

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/ADU/row" + string(row) + "_mod" + string(mod) + "_allch_ADU.dat", "ReadVariableNames", false);
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);
        
        f = figure('Visible','off');
        hold on
        for ch = 1:size(data, 2)-1
            chdata = data([1:end-1], ch);
            chdata_stringcell = string(chdata);
            chdata_mat = str2double(chdata_stringcell);
            histogram(chdata_mat, "BinWidth", 15, "FaceAlpha", 0.5, "DisplayStyle", "bar")
        end
        hold off
        
        box on
        grid on
        xlim([0, 2000])
        xticks([0:100:2000])
        xlabel("\textbf{[ADU]}")
        ylabel("\textbf{Counts}")
        title("\textbf{Incoming energy spectrum for all channels of module " + string(mod) + " on row " + string(row) + "}")
        
        ax = gca;
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize; 
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1920 1080];
        
        exportgraphics(gcf,"output/plots/energy_deposition/ADU/allchannels_allmodules/energy_ADU_row" + string(row) + "_mod" + string(mod) + "_allch_ADU.pdf",'ContentType','vector');
    end
end


%% Istogrammi eventi (all channels together for all rows and modules): energy deposition in MeV

clear; clc;

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/EDEP/row" + string(row) + "_mod" + string(mod) + "_allch_EDEP.dat", "ReadVariableNames", false);
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);
        
        f = figure('Visible','off');
        hold on
        for ch = 1:size(data, 2)-1
            chdata = data([1:end-1], ch);
            chdata_stringcell = string(chdata);
            chdata_mat = str2double(chdata_stringcell);
            histogram(chdata_mat, "BinWidth", 0.02, "FaceAlpha", 0.5, "DisplayStyle", "bar")
        end
        hold off
        
        box on
        grid on
        xlim([0, 6])
        xticks([0:0.5:6])
        xlabel("\textbf{Incoming Energy [MeV]}")
        ylabel("\textbf{Counts}")
        title("\textbf{Incoming energy spectrum for all channels of module " + string(mod) + " on row " + string(row) + "}")
        
        ax = gca;
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize; 
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1920 1080];
        
        exportgraphics(gcf,"output/plots/energy_deposition/EDEP/allchannels_allmodules/energy_EDEP_row" + string(row) + "_mod" + string(mod) + "_allch_EDEP.pdf",'ContentType','vector');
    end
end


%% ADU: landau eventi (all channels together for all rows and modules): energy deposition in ADU

clear; clc;

landau_fit_infos = nan(36, 5);
module_counter = 1;

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/ADU/row" + string(row) + "_mod" + string(mod) + "_allch_ADU.dat", "ReadVariableNames", false);
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);

        data_landau = nan(5000, 32);
        
        f = figure('Visible', 'off')
        hold on
        for ch = 1:size(data, 2) - 1
            chdata = data([1:end-1], ch);
            chdata_stringcell = string(chdata);
            chdata_mat = str2double(chdata_stringcell);
            chdata_mat_padded = padarray(chdata_mat, abs(length(data_landau) - length(chdata_mat)), nan, "post");
            data_landau(:, ch) = chdata_mat_padded;
        end
        hold off
        data_landau = reshape(data_landau', [], 1);
        data_landau = data_landau(~isnan(data_landau));

        if(~isempty(data_landau))
            [vpp, sig, mv, bound] = histfitlandau(data_landau, 3, 0, 2047, 1);
            landau_fit_infos(module_counter, :) = [row, mod, round(vpp, 2), round(sig, 2), round(mv, 2)];
        else
            landau_fit_infos(module_counter, :) = [row, mod, nan, nan, nan];
        end

        module_counter = module_counter + 1;
        
        box on
        grid on
        xlim([0, 2047])
        xlabel("\textbf{Incoming Energy [ADU]}")
        ylabel("\textbf{Counts}")
        title("\textbf{Incoming energy spectrum for all channels of module " + string(mod) + " on row " + string(row) + "}")
        
        ax = gca;
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize; 
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1920 1080];
        
        exportgraphics(gcf,"output/plots/energy_deposition/ADU_landau_fit/allchannels_allmodules/landau_ADU_row" + string(row) + "_mod" + string(mod) + "_allch_ADU.pdf",'ContentType','vector');
    end
end

landau_fit_infos_table = array2table(landau_fit_infos, "VariableNames", ["row", "module", "vpp", "sig", "mean"]);
writetable(landau_fit_infos_table, "output/plots/energy_deposition/ADU_landau_fit/allchannels_allmodules/landau_fit_infos.dat", 'Delimiter', "\t");


%% Plot landau fit infos for all modules (ADU)

clear; clc;

data = readtable("output/plots/energy_deposition/ADU_landau_fit/allchannels_allmodules/landau_fit_infos.dat");
colors = distinguishable_colors(2, 'w');

f = figure("Visible", "on");
hold on
plot([0:35], data.vpp, 'LineWidth', 1, "Marker", "o", "Color", [colors(1, 1), colors(1, 2), colors(1, 3)], "MarkerFaceColor", [colors(1, 1), colors(1, 2), colors(1, 3)]);
plot([0:35], data.sig, 'LineWidth', 1, "Marker", "o", "Color", [colors(2, 1), colors(2, 2), colors(2, 3)], "MarkerFaceColor", [colors(2, 1), colors(2, 2), colors(2, 3)]);
hold off

data_array = table2array(data);
vpp = data_array(:, 3);
sig = data_array(:, 4);

box on
grid on
xlabel("\textbf{Module}")
ylabel("\textbf{[ADU]}")
ylim([0 1000])
legend("Landau distribution MPV, $\mu = " + string(round(nanmean(vpp), 2)) + "$ ADU, $\sigma = " + string(round(nanstd(vpp), 2)) + "$ ADU", "Landau distribution MPV standard deviation, $\mu = " + string(round(nanmean(sig), 2)) + "$ ADU, $\sigma = " + string(round(nanstd(sig), 2)) + "$ ADU")
title("\textbf{Landau distribution fit results over all GFP modules}")

ax = gca;
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize; 
ax.Legend.FontSize = fontsize; 
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 900 700];

exportgraphics(gcf,"output/plots/energy_deposition/ADU_landau_fit/allchannels_allmodules/landau_fit_vpp_sigma_plot.pdf", 'ContentType', 'vector');


%% EDEP: landau eventi (all channels together for all rows and modules): energy deposition in MeV

clear; clc;

landau_fit_infos = nan(36, 5);
module_counter = 1;

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/EDEP/row" + string(row) + "_mod" + string(mod) + "_allch_EDEP.dat", "ReadVariableNames", false);
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);

        data_landau = nan(5000, 32);
        
        f = figure('Visible','off')
        hold on
        for ch = 1:size(data, 2) - 1
            chdata = data([1:end-1], ch);
            chdata_stringcell = string(chdata);
            chdata_mat = str2double(chdata_stringcell);
            chdata_mat_padded = padarray(chdata_mat, abs(length(data_landau) - length(chdata_mat)), nan, "post");
            data_landau(:, ch) = chdata_mat_padded;
        end
        hold off
        data_landau = reshape(data_landau', [], 1);
        data_landau = data_landau(~isnan(data_landau));

        if(length(data_landau) > 0)
            [vpp, sig, mv, bound] = histfitlandau(data_landau.*1000, 15, 0, 6000, 1);
            landau_fit_infos(module_counter, :) = [row, mod, round(vpp, 2), round(sig, 2), round(mv, 2)];
        else
            landau_fit_infos(module_counter, :) = [row, mod, nan, nan, nan];
        end

        module_counter = module_counter + 1;
        
        box on
        grid on
        xlim([0, 6000])
        %xticks([0:0.5:6])
        xlabel("\textbf{Incoming Energy [keV]}")
        ylabel("\textbf{Counts}")
        title("\textbf{Incoming energy spectrum for all channels of module " + string(mod) + " on row " + string(row) + "}")
        
        ax = gca;
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize; 
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1920 1080];
        
        exportgraphics(gcf,"output/plots/energy_deposition/EDEP_landau_fit/allchannels_allmodules/landau_EDEP_row" + string(row) + "_mod" + string(mod) + "_allch_EDEP.pdf",'ContentType','vector');
    end
end

landau_fit_infos_table = array2table(landau_fit_infos, "VariableNames", ["row", "module", "vpp", "sig", "mean"]);
writetable(landau_fit_infos_table, "output/plots/energy_deposition/EDEP_landau_fit/allchannels_allmodules/landau_fit_infos.dat", 'Delimiter', "\t");


%% Plot landau fit infos for all modules (EDEP)

clear; clc;

data = readtable("output/plots/energy_deposition/EDEP_landau_fit/allchannels_allmodules/landau_fit_infos.dat");
colors = distinguishable_colors(2, 'w');

f = figure("Visible", "off")
hold on
plot([0:35], data.vpp, 'LineWidth', 1, "Marker", "o", "Color", [colors(1, 1), colors(1, 2), colors(1, 3)], "MarkerFaceColor", [colors(1, 1), colors(1, 2), colors(1, 3)]);
plot([0:35], data.sig, 'LineWidth', 1, "Marker", "o", "Color", [colors(2, 1), colors(2, 2), colors(2, 3)], "MarkerFaceColor", [colors(2, 1), colors(2, 2), colors(2, 3)]);
hold off

box on
grid on
xlabel("\textbf{Module}")
ylabel("\textbf{[keV]}")
legend("Landau distribution MPV [keV]", "Landau distribution $\sigma$ [keV]")
title("\textbf{Landau distribution fit results over all GFP modules}")

ax = gca;
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize; 
ax.Legend.FontSize = fontsize; 
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 900 700];

exportgraphics(gcf,"output/plots/energy_deposition/EDEP_landau_fit/allchannels_allmodules/landau_fit_vpp_sigma_plot.pdf", 'ContentType', 'vector');


%% Istogrammi eventi (plot dei singoli canali per ogni modulo di ogni row) in ADU

clear; clc;

colors = distinguishable_colors(32, 'w');

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/ADU/row" + string(row) + "_mod" + string(mod) + "_allch_ADU.dat", "Delimiter", ',');
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);
        
        mkdir("output\plots\energy_deposition\ADU\row" + string(row) + "_mod" + string(mod) + "_single_channels");
        for ch = 0:size(data, 2)-1
            f = figure('Visible','off');

            chdata = data([1:end-2], ch+1);
            chdata = cell2mat(chdata);
            histogram(chdata, "BinWidth", 15, "FaceAlpha", 0.5, "DisplayStyle", "bar", 'FaceColor', [colors(ch+1, 1), colors(ch+1, 2), colors(ch+1, 3)])

            box on
            grid on
            xlim([0, 2000])
            xticks([0:100:2000])
            xlabel("\textbf{[ADU]}")
            ylabel("\textbf{Counts}")
            title("\textbf{Incoming energy spectrum for channel " + string(ch) + "}")
            
            ax = gca;
            fontsize = 12;
            ax.XAxis.FontSize = fontsize; 
            ax.YAxis.FontSize = fontsize; 
            ax.Title.FontSize = fontsize + 4;
            f.Position = [0 0 1920 1080];
            
            exportgraphics(gcf,"output\plots\energy_deposition\ADU\row" + string(row) + "_mod" + string(mod) + "_single_channels\energy_ADU_row" + string(row) + "_mod" + string(mod) + "_ch" + string(ch) + "_ADU.pdf",'ContentType','vector');
        end
    end
end


%% Istogrammi eventi (plot dei singoli canali per ogni modulo di ogni row): energy deposition in MeV

clear; clc;

colors = distinguishable_colors(32, 'w');

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/EDEP/row" + string(row) + "_mod" + string(mod) + "_allch_EDEP.dat", "Delimiter", ',');
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);
        
        mkdir("output\plots\energy_deposition\EDEP\row" + string(row) + "_mod" + string(mod) + "_single_channels");
        for ch = 0:size(data, 2)-1
            f = figure('Visible','off')

            chdata = data([1:end-2], ch+1);
            chdata = cell2mat(chdata);
            histogram(chdata*1000, "BinWidth", 15, "FaceAlpha", 0.5, "DisplayStyle", "bar", 'FaceColor', [colors(ch+1, 1), colors(ch+1, 2), colors(ch+1, 3)])

            box on
            grid on
            xlim([0, 6000])
            %xticks([0:0.5:6])
            xlabel("\textbf{Incoming Energy [keV]}")
            ylabel("\textbf{Counts}")
            title("\textbf{Incoming energy spectrum for channel " + string(ch) + "}")
            
            ax = gca;
            fontsize = 12;
            ax.XAxis.FontSize = fontsize; 
            ax.YAxis.FontSize = fontsize; 
            ax.Title.FontSize = fontsize + 4;
            f.Position = [0 0 1920 1080];
            
            exportgraphics(gcf,"output\plots\energy_deposition\EDEP\row" + string(row) + "_mod" + string(mod) + "_single_channels\energy_EDEP_row" + string(row) + "_mod" + string(mod) + "_ch" + string(ch) + "_EDEP.pdf",'ContentType','vector');
        end
    end
end


%% plot pedestal data for every module: histograms with normal distribution on top

clear; clc;

bin_w = 4;
scale = 23;
margin_sx = 3;
margin_dx = 3;
fontsize = 11;

for row = 0:5
    for mod = 0:5
        pedestal_raw_data = readtable("GFP_Data\pedestal\input\row" + string(row) + "_mod" + string(mod) + "_allch_pedestals.dat");
        pedestal_data = pedestal_raw_data.Var1;
        data_count = sum(~isnan(pedestal_data));

        if(data_count > 0)
            f = figure('Visible','off');
            hold on
            dist = fitdist(pedestal_data, "normal");
            plot_hist = histogram(pedestal_data, 'BinWidth', 20);
            pd = fitdist(pedestal_data,'Normal');
            diff_sx = plot_hist.BinEdges(margin_sx) - plot_hist.BinEdges(1);
            diff_dx = plot_hist.BinEdges(end) - plot_hist.BinEdges(end - margin_dx);
            x_values = [(plot_hist.BinEdges(1) - diff_sx):0.001:(plot_hist.BinEdges(end) + diff_dx)];
            pdf_hist = pdf(pd, x_values) * trapz(plot_hist.Values) * scale;
            plot(x_values, pdf_hist, 'LineWidth', 1, 'Color', 'blue');
    
            box on
            grid on
            set(plot_hist(1),'FaceAlpha',.25);
            set(plot_hist(1),'FaceColor', 'blue');
            ylim([0 16]) % ylim([0 max([max(pdf_hist) max(plot_hist.BinCounts)]) + 1]);
            xlim([0 500])
            yticks([0:1:16])
            title("\textbf{Module " + string(mod) + " on row " + string(row) + " pedestal distribution}")
            xlabel("\textbf{Pedestal [ADU]}");
            ylabel("\textbf{Counts}")
    
            str1 = "Channels: " + string(data_count);
            str2 = "$\mu=" + string(round(dist.mu, 2)) + "$ ADU";
            str3 = "$\sigma=" + string(round(dist.sigma, 2)) + "$  ADU";
            txtbx_content = {str1, str2, str3};
            annotation('textbox', [.72 .8 .1 .1], 'String', txtbx_content,'FitBoxToText', 'on', 'BackgroundColor', 'white', FontName='Computer Modern', FontSize=fontsize)
           
            ax = gca;
            ax.XAxis.FontSize = fontsize; 
            ax.YAxis.FontSize = fontsize; 
            ax.Title.FontSize = fontsize;
            f.Position = [0 0 800 600];

            exportgraphics(gcf,'output/plots/pedestal/histograms/pedestal_row' + string(row) + '_mod' + string(mod) + '_hist.pdf','ContentType','vector');
        end  
    end
end


%% plot pedestal data for every module: plots with pedestal extracted from FDT

clear; clc;
load GFP_Data\pedestal\computed\fdt_cal10_pedestal.mat;
module_counter = 1;
colors = distinguishable_colors(6, 'w');
fontsize = 11;

pedestal_diff = nan(32, 36);

for row = 0:5
    for mod = 0:5
        pedestal_raw_data = readtable("GFP_Data\pedestal\input\row" + string(row) + "_mod" + string(mod) + "_allch_pedestals.dat");
        pedestal_data = pedestal_raw_data.Var1;
        data_count = sum(~isnan(pedestal_data))
        
        if(data_count > 0 & sum(~isnan(fdt_cal10(:, module_counter))) > 0)
            f = figure('Visible','off');
            hold on
            plot_data = plot([0:31], pedestal_data, 'Marker','o', 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(2, 1), colors(2, 2), colors(2, 3)], 'MarkerEdgeColor', [colors(2, 1), colors(2, 2), colors(2, 3)])
            plot_fdt = plot([0:31], fdt_cal10(:, module_counter), 'Marker','o', 'Color', [colors(3, 1), colors(3, 2), colors(3, 3)], 'MarkerFaceColor', [colors(4, 1), colors(4, 2), colors(4, 3)], 'MarkerEdgeColor', [colors(4, 1), colors(4, 2), colors(4, 3)])
            diff = abs(pedestal_data - fdt_cal10(:, module_counter));
            plot_diff = plot([0:31], diff, 'Marker','o', 'Color', [colors(5, 1), colors(5, 2), colors(5, 3)], 'MarkerFaceColor', [colors(6, 1), colors(6, 2), colors(6, 3)], 'MarkerEdgeColor', [colors(6, 1), colors(6, 2), colors(6, 3)]);
            pedestal_diff(:, module_counter) = diff;
            hold off

            box on
            grid on
            xlim([0 31])
            ylim([0 500])
            xlabel("\textbf{Channel}")
            ylabel("\textbf{Pedestal [ADU]}")
            title("\textbf{Module " + string(mod) + " on row " + string(row) + " pedestal}")
            legend([plot_data, plot_fdt, plot_diff], "Pedestal obtained from ENC, $\mu = " + string(round(nanmean(pedestal_data), 2)) + "$ ADU", ...
                "Pedestal obtained from FDT, $\mu = " + string(round(nanmean(fdt_cal10(:, module_counter)), 2)) + "$ ADU", ...
                "Pedestal difference, $\mu = " + string(round(nanmean(diff), 2)) + "$ ADU", ...
                'Location', 'northeast')

            ax = gca;
            ax.XAxis.FontSize = fontsize; 
            ax.YAxis.FontSize = fontsize; 
            ax.Title.FontSize = fontsize + 2;
            ax.Legend.FontSize = fontsize;
            f.Position = [0 0 800 600];

            exportgraphics(gcf,'output/plots/pedestal/comparison/pedestal_row' + string(row) + '_mod' + string(mod) + '_plot.pdf','ContentType','vector');
        end

        module_counter = module_counter + 1;
    end
end

close all;
save GFP_Data\pedestal\computed\pedestal_diff.mat pedestal_diff
pedestal_diff_table = array2table(pedestal_diff);
writetable(pedestal_diff_table, "output/plots/pedestal/comparison/pedestal_delta_allmods_allchs.dat", 'Delimiter', "\t", "WriteRowNames", false);


%% Pedestal difference: analisi per singolo modulo

clear; clc;
load GFP_Data\pedestal\computed\pedestal_diff.mat
colors = distinguishable_colors(4, 'w');
fontsize = 11;

diff_mean_module = nan(36, 2);
for mod = 1:36
    data = pedestal_diff(:, mod);
    data_count = sum(~isnan(data));

    if(data_count > 0)
        dist = fitdist(data, "normal");
        diff_mean_module(mod, 1) = dist.mu;
        diff_mean_module(mod, 2) = dist.sigma;
    end
end

data_table = array2table(diff_mean_module, 'VariableNames', ["diff_mu", "diff_sigma"]);
writetable(data_table, "output/pedestal_diff_module.dat", "Delimiter", "\t");

f = figure('Visible','off');
hold on
plot_mu = plot(data_table.diff_mu, 'Marker','o', 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(2, 1), colors(2, 2), colors(2, 3)], 'MarkerEdgeColor', [colors(2, 1), colors(2, 2), colors(2, 3)])
plot_sigma = plot(data_table.diff_sigma, 'Marker','o', 'Color', [colors(3, 1), colors(3, 2), colors(3, 3)], 'MarkerFaceColor', [colors(4, 1), colors(4, 2), colors(4, 3)], 'MarkerEdgeColor', [colors(4, 1), colors(4, 2), colors(4, 3)])

box on
grid on
legend([plot_mu, plot_sigma], "Pedestal difference mean, $\mu = " + round(nanmean(data_table.diff_mu), 2) + "$ ADU, $\sigma = " + round(nanvar(data_table.diff_mu), 2) + "$ ADU", "Pedestal difference variance, $\mu = " + round(nanmean(data_table.diff_sigma), 2) + "$ ADU, $\sigma = " + round(nanvar(data_table.diff_sigma), 2) + "$ ADU", "Location", "northwest");
xlabel("Module")
ylabel("[ADU]")
title("\textbf{Pedestal difference: mean and variance trend over 36 modules}")

ax = gca;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize; 
ax.Title.FontSize = fontsize + 2;
ax.Legend.FontSize = fontsize;
f.Position = [0 0 800 600];

exportgraphics(gcf,'output/plots/pedestal/pedestal_difference_mu_sigma_module.pdf','ContentType','vector');


%% Pedestal difference: analisi per singolo canale

clear; clc;
load GFP_Data\pedestal\computed\pedestal_diff.mat
colors = distinguishable_colors(4, 'w');
fontsize = 11;

diff_mean_channel = nan(32, 2);
for ch = 0:31
    data = pedestal_diff(ch+1, :)';
    data_count = sum(~isnan(data));

    if(data_count > 0)
        dist = fitdist(data, "normal");
        diff_mean_channel(ch+1, 1) = dist.mu;
        diff_mean_channel(ch+1, 2) = dist.sigma;
    end
end

data_table = array2table(diff_mean_channel, 'VariableNames', ["diff_mu", "diff_sigma"]);
writetable(data_table, "output/pedestal_diff_channel.dat", "Delimiter", "\t");

f = figure('Visible','off');
hold on
plot_mu = plot([0:31], data_table.diff_mu, 'Marker','o', 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(2, 1), colors(2, 2), colors(2, 3)], 'MarkerEdgeColor', [colors(2, 1), colors(2, 2), colors(2, 3)])
plot_sigma = plot([0:31], data_table.diff_sigma, 'Marker','o', 'Color', [colors(3, 1), colors(3, 2), colors(3, 3)], 'MarkerFaceColor', [colors(4, 1), colors(4, 2), colors(4, 3)], 'MarkerEdgeColor', [colors(4, 1), colors(4, 2), colors(4, 3)])

writetable(array2table([data_table.diff_mu, data_table.diff_sigma], 'VariableNames', ["diff_mu", "diff_sigma"]), "output\plots\pedestal\GPF_pedestal_difference_mu_sigma.dat", "Delimiter", "\t")

box on
grid on
legend([plot_mu, plot_sigma], "Pedestal difference mean, $\mu = " + round(nanmean(data_table.diff_mu), 2) + "$ ADU, $\sigma = " + round(nanvar(data_table.diff_mu), 2) + "$ ADU", "Pedestal difference variance, $\mu = " + round(nanmean(data_table.diff_sigma), 2) + "$ ADU, $\sigma = " + round(nanvar(data_table.diff_sigma), 2) + "$ ADU", "Location", "northeast");
xlabel("Channel")
ylabel("[ADU]")
xlim([0 31])
title("\textbf{Pedestal difference: mean and variance trend over 32 channels}") 

ax = gca;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize; 
ax.Title.FontSize = fontsize + 2;
ax.Legend.FontSize = fontsize;
f.Position = [0 0 800 600];

exportgraphics(gcf,'output/plots/pedestal/pedestal_difference_mu_sigma_channel.pdf','ContentType','vector');
