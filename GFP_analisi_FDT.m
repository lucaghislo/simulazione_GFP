%% Init
clear; clc;
% This script changes all interpreters from tex to latex. 
list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
warning('off','all')
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end


%% FDT data retrival
% Fattore di conversion DAC_inj_code to keV
conv_factor = 0.841;
% Range canali di interesse
ch_start = 0;
ch_finish = 31;
ch_values = [ch_start:ch_finish]';

% Compute fdt data for each channel
fdt_path = "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\transfer_functions";
dac_values_raw = readtable(fdt_path + "/Row0Module0Ch0.txt");
dac_values = unique(dac_values_raw.Cal_V);

fdt_allmodules = nan(length(dac_values), 36);
module_counter = 0;
for row = [0:5]
    for module = [0:5]
        % FDT calcolata solo sui canali di interesse
        error_flag = false;
        fdt_data_allch = nan(length(dac_values), 32);
        ch_count = 0;
        for ch = ch_values'
            filename = fdt_path + "/Row" + string(row) + "Module" + string(module) + "Ch" + string(ch) + ".txt";
            if isfile(filename)
                fdt_data_raw = readtable(filename);
                fdt_data_allch(:, ch_count + 1) = fdt_data_raw.ADC;
            else
                disp("WARNING: FDT module " + string(module) + " on row " + string(row) + " for channel " + string(ch_count) + " not found!");
                error_flag = true;
                fdt_data_allch(:, ch_count + 1) = nan;
            end
            ch_count = ch_count + 1;
            if(~error_flag)
                disp("Computing FDT for module " + string(module) + " on row " + string(row) + " at channel " + string(ch));
            end
        end
        mean_fdt_ch = mean(fdt_data_allch, 2);
        fdt_allmodules(:, module_counter + 1) = mean_fdt_ch;
        module_counter = module_counter + 1;
        disp("INFO: completed module " + string(module) + " on row " + string(row));
    end
end


%% FDT data plot
clearvars -except fdt_allmodules dac_values ch_values conv_factor;
clc;

colors = distinguishable_colors(6, 'w');
module_count = 0;
for row = [0:5]
    f = figure("Visible", "off");
    hold on
    legend_text = strings(6, 1);
    for module = [0:5]
        plot(dac_values.*0.841, fdt_allmodules(:, module_count + 1).*0.841, "LineWidth", 1, 'Color', [colors(module+1, 1), colors(module+1, 2), colors(module+1, 3)]);
        if ~isnan(fdt_allmodules(:, module_count + 1))
            legend_text(module + 1) = string(module);
        end
        module_count = module_count + 1;
    end
    hold off
    
    box on
    grid on
    xlabel('\textbf{Incoming energy [MeV]}');
    ylabel('\textbf{Channel Output [ADU]}');
    ylim([0 1600])
    xlim([0, 53824]);
    xticks([0:10000:50000])
    xticklabels([0:10:50])
    yticks([0:200:1600])
    set(gcf, 'Color', 'w');
    title("\textbf{Mean transfer function for modules on row " + string(row) + "}");
    hleg = legend(legend_text, "Location", "southeast");
    htitle = get(hleg,'Title');
    set(htitle,'String','\textbf{Module on row}')

    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Legend.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\GFP_FDT_row" + string(row) + ".pdf");
    disp("SAVED: GFP_FDT_row" + string(row) + ".pdf")
end


%% FDT data plot (X limit: 2 MeV)
clearvars -except fdt_allmodules dac_values ch_values conv_factor;
clc;

colors = distinguishable_colors(6, 'w');
module_count = 0;
for row = [0:5]
    f = figure("Visible", "off");
    hold on
    legend_text = strings(6, 1);
    for module = [0:5]
        plot(dac_values.*0.841, fdt_allmodules(:, module_count + 1).*0.841, "LineWidth", 1, 'Color', [colors(module+1, 1), colors(module+1, 2), colors(module+1, 3)]);
        if ~isnan(fdt_allmodules(:, module_count + 1))
            legend_text(module + 1) = string(module);
        end
        module_count = module_count + 1;
    end
    hold off
    
    box on
    grid on
    xlabel('\textbf{Incoming energy [keV]}');
    ylabel('\textbf{Channel Output [ADU]}');
    ylim([0 1000])
    xlim([0, 2000]);
    set(gcf, 'Color', 'w');
    title("\textbf{Mean transfer function for modules on row " + string(row) + " (up to 2 MeV)}");
    hleg = legend(legend_text, "Location", "southeast");
    htitle = get(hleg,'Title');
    set(htitle,'String','\textbf{Module on row}')

    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Legend.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\GFP_FDT_row" + string(row) + "_2MeV.pdf");
    disp("SAVED: GFP_FDT_row" + string(row) + "_2MeV.pdf")
end


%% FDT gain analysis
clearvars -except fdt_allmodules dac_values ch_values conv_factor;
clc;

module_count = 0;
gain_data = nan(36, 4);
for row = [0:5]
    for module = [0:5]        
        x = dac_values.*conv_factor;
        y = fdt_allmodules(:, module_count + 1).*0.841;

        % Low energy gain analysis
        x_low = x(1:11);
        y_low = y(1:11);
        c_low = polyfit(x_low, y_low, 1);
        mdl_low = fitlm(x_low, y_low);
        disp("Low energy gain for module " + string(module_count) + ": y = " + string(c_low(2)) + " + " + string(c_low(1)) + "*x, R = " + string(corrcoef(y_low)));
        
        % High energy gain analysis
        x_high = x(47:end);
        y_high = y(47:end);
        c_high = polyfit(x_high, y_high, 1);
        mdl_high = fitlm(x_high, y_high);
        disp("High energy gain for module " + string(module_count) + ": y = " + string(c_high(2)) + " + " + string(c_high(1)) + "*x, R = " + string(corrcoef(y_high)));
        
        gain_data(module_count + 1, 1) = c_low(2);
        gain_data(module_count + 1, 2) = c_low(1);
        gain_data(module_count + 1, 3) = c_high(2);
        gain_data(module_count + 1, 4) = c_high(1);
        module_count = module_count + 1;
    end
    
    gain_data_table = array2table(gain_data, "VariableNames", ["intercept_low", "gain_low", "intercept_high", "gain_high"]);
    writetable(gain_data_table, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\GFP_gain_data.dat", 'Delimiter', "\t");
end


%% Plot low energy intercept
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(1, 'w');
f = figure("Visible", "off");
plot([0:35], gain_data(:, 1), "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);
box on
grid on
xlabel('\textbf{Module}');
ylabel('\textbf{Low energy intercept (pedestal) [ADU]}');
set(gcf, 'Color', 'w');
title("\textbf{Low energy intercept (pedestal) with respect to module}");

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\low_energy_intercept.pdf");


%% Plot low energy gain
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(2, 'w');
colors = colors(2, :);

f = figure("Visible", "off");
plot([0:35], gain_data(:, 2), "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);
box on
grid on
xlabel('\textbf{Module}');
ylabel('\textbf{Low energy gain [ADU/keV]}');
set(gcf, 'Color', 'w');
title("\textbf{Low energy gain with respect to module}");

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\low_energy_gain.pdf");


%% Plot high energy intercept
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(3, 'w');
colors = colors(3, :);

f = figure("Visible", "off");
plot([0:35], gain_data(:, 3), "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);
box on
grid on
xlabel('\textbf{Module}');
ylabel('\textbf{High energy intercept [ADU]}');
set(gcf, 'Color', 'w');
title("\textbf{High energy intercept with respect to module}");

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\high_energy_intercept.pdf");


%% Plot low energy gain
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(4, 'w');
colors = colors(4, :);

f = figure("Visible", "off");
plot([0:35], gain_data(:, 4).*1000, "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], 'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);
box on
grid on
xlabel('\textbf{Module}');
ylabel('\textbf{High energy gain [ADU/MeV]}');
set(gcf, 'Color', 'w');
title("\textbf{High energy gain with respect to module}");

ax = gca; 
fontsize = 12;
ax.XAxis.FontSize = fontsize; 
ax.YAxis.FontSize = fontsize;
ax.Title.FontSize = fontsize + 4;
f.Position = [0 0 1200 800];

exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\high_energy_gain.pdf");


%% Plot low energy intercept per row
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(1, 'w');
f = figure("Visible", "off");
row_counter = 0;
for row = [1:6:36]
    plot([0:5], gain_data(row:row+5, 1), "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], ...
        'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);

    box on
    grid on
    %ylim([0 300])
    xticks([0:5])
    xlabel('\textbf{Module}');
    ylabel('\textbf{Low energy intercept (pedestal) [ADU]}');
    set(gcf, 'Color', 'w');
    title("\textbf{Low energy intercept (pedestal) with respect to module: row " + string(row_counter) + "}");
    
    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\low_energy_intercept_row" + string(row_counter) + ".pdf");
    row_counter = row_counter + 1;
end

%% Plot low energy gain per row
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(2, 'w');
colors = colors(2, :);

f = figure("Visible", "off");
row_counter = 0;
for row = [1:6:36]
    plot([0:5], gain_data(row:row+5, 2), "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], ...
        'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);

    box on
    grid on
    %ylim([0.6 0.95])
    xticks([0:5])
    xlabel('\textbf{Module}');
    ylabel('\textbf{Low energy gain [ADU/keV]}');
    set(gcf, 'Color', 'w');
    title("\textbf{Low energy gain with respect to module: row " + string(row_counter) + "}");
    
    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\low_energy_gain_row" + string(row_counter) + ".pdf");
    row_counter = row_counter + 1;
end


%% Plot high energy intercept per row
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(3, 'w');
colors = colors(3, :);
f = figure("Visible", "off");
row_counter = 0;
for row = [1:6:36]
    plot([0:5], gain_data(row:row+5, 3), "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], ...
        'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);

    box on
    grid on
    %ylim([0 300])
    xticks([0:5])
    xlabel('\textbf{Module}');
    ylabel('\textbf{High energy intercept [ADU]}');
    set(gcf, 'Color', 'w');
    title("\textbf{High energy intercept with respect to module: row " + string(row_counter) + "}");
    
    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\high_energy_intercept_row" + string(row_counter) + ".pdf");
    row_counter = row_counter + 1;
end


%% Plot low energy gain per row
clearvars -except fdt_allmodules dac_values ch_values conv_factor gain_data;
clc;

colors = distinguishable_colors(4, 'w');
colors = colors(4, :);

f = figure("Visible", "off");
row_counter = 0;
for row = [1:6:36]
    plot([0:5], gain_data(row:row+5, 4).*1000, "LineWidth", 1, "Marker", "o", 'Color', [colors(1, 1), colors(1, 2), colors(1, 3)], ...
        'MarkerFaceColor', [colors(1, 1), colors(1, 2), colors(1, 3)]);

    box on
    grid on
    %ylim([0.6 0.95])
    xticks([0:5])
    xlabel('\textbf{Module}');
    ylabel('\textbf{High energy gain [ADU/MeV]}');
    set(gcf, 'Color', 'w');
    title("\textbf{High energy gain with respect to module: row " + string(row_counter) + "}");
    
    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_row_analysis\gain_analysis\high_energy_gain_row" + string(row_counter) + ".pdf");
    row_counter = row_counter + 1;
end
