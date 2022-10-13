%% This script changes all interpreters from tex to latex. 
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end


%% Convert FDT data (original)
clear; clc;

fdt_data = readtable("GFP_Data/transfer_functions/FDT_data_row0_mod0.dat");
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

% export fdt (channels on columns)
labels = ["Energy_IN", string(ch_number)];
data_out = array2table([count_inj, fdt_channels], 'VariableNames', labels);
writetable(data_out, 'output/fdt_data.dat', 'Delimiter', '\t')

% plot fdt
f = figure('Visible','off')
hold on
for ch = 1:1:32
    plot(count_inj, fdt_channels(:, ch))
end
hold off

box on
grid on
xlabel('Incoming energy [MeV]');
ylabel('Channel Output [ADU]');
xlim([0, 53824]);
xticks([0:10000:50000])
xticklabels([0:10:50])
yticks([0:200:2000])
set(gcf, 'Color', 'w');
title("\textbf{Transfer Function Module 0 Row 0}")

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf,'output/plots/transfer_functions/fdt_row0_mod0_allch.pdf','ContentType','vector');


%% Istogrammi eventi (all channels together for all rows and modules)
clear; clc;

for row = 0
    for mod = 0
        data = readtable("GFP_Data/events/ADU/row" + string(row) + "_mod" + string(mod) + "_allch_ADU.dat", "Delimiter", ',');
        data = rows2vars(data);
        data = data(:, (2:33));
        data = table2array(data);
        
        f = figure('Visible','off')
        hold on
        for ch = 1:31
            chdata = data([1:end-2], ch);
            chdata = cell2mat(chdata);
            histogram(chdata, "BinWidth", 15, "FaceAlpha", 0.5, "DisplayStyle", "bar")
        end
        hold off
        
        box on
        grid on
        xlim([0, 2000])
        xticks([0:100:2000])
        xlabel("\textbf{[ADU]}")
        ylabel("\textbf{Counts}")
        title("\textbf{Incoming energy spectrum}")
        
        ax = gca;
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize; 
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1920 1080];
        
        exportgraphics(gcf,"output/plots/energy_deposition/ADU/energy_ADU_row" + string(row) + "_mod" + string(mod) + "_allch_ADU.pdf",'ContentType','vector');
    end
end


