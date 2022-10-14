%% This script changes all interpreters from tex to latex. 
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end


%% Convert FDT data (un file per ogni canale di ogni modulo)
clear; clc;

for row = 0:5
    for mod = 0:5

        f = figure("Visible", "on");
        hold on
        for ch = 0:31
            if isfile("GFP_Data\transfer_functions\Row"+ string(row) +"Module" + string(mod) + "Ch" + string(ch) + ".txt")
                fdt_ch_data = readtable("GFP_Data\transfer_functions\Row"+ string(row) +"Module" + string(mod) + "Ch" + string(ch) + ".txt")
                plot(fdt_ch_data.Cal_V, fdt_ch_data.ADC);
            end
        end
        hold off
        
        if isfile("GFP_Data\transfer_functions\Row"+ string(row) +"Module" + string(mod) + "Ch" + string(ch) + ".txt")
            box on
            grid on
            xlabel('Incoming energy [MeV]');
            ylabel('Channel Output [ADU]');
            xlim([0, 53824]);
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


%% Istogrammi eventi (all channels together for all rows and modules) in ADU
clear; clc;

for row = 0:5
    for mod = 0:5
        data = readtable("GFP_Data/events/ADU/row" + string(row) + "_mod" + string(mod) + "_allch_ADU.dat", "ReadVariableNames", false);
        data = rows2vars(data);
        data = data(:, (2:size(data, 2)));
        data = table2array(data);
        
        f = figure('Visible','off')
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
        
        f = figure('Visible','off')
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
        
        exportgraphics(gcf,"output/plots/energy_deposition/EDEP/allchannels_allmodules/energy_EDEP_row" + string(row) + "_mod" + string(mod) + "_allch_ADU.pdf",'ContentType','vector');
    end
end


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
            f = figure('Visible','off')

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
            histogram(chdata, "BinWidth", 0.02, "FaceAlpha", 0.5, "DisplayStyle", "bar", 'FaceColor', [colors(ch+1, 1), colors(ch+1, 2), colors(ch+1, 3)])

            box on
            grid on
            xlim([0, 6])
            xticks([0:0.5:6])
            xlabel("\textbf{Incoming Energy [MeV]}")
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


%% plot pedestal data for every module