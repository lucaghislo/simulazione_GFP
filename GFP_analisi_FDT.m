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
clearvars -except fdt_allmodules dac_values ch_values;
clc;

colors = distinguishable_colors(6, 'w');
module_count = 0;
for row = [0:5]
    f = figure("Visible", "off");
    hold on
    for module = [0:5]
        plot(dac_values.*0.841, fdt_allmodules(:, module_count + 1).*0.841, "LineWidth", 1, 'Color', [colors(module+1, 1), colors(module+1, 2), colors(module+1, 3)]);
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
    hleg = legend("0", "1", "2", "3", "4", "5", "Location", "southeast");
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
clearvars -except fdt_allmodules dac_values ch_values;
clc;

colors = distinguishable_colors(6, 'w');
module_count = 0;
for row = [0:5]
    f = figure("Visible", "off");
    hold on
    for module = [0:5]
        plot(dac_values.*0.841, fdt_allmodules(:, module_count + 1).*0.841, "LineWidth", 1, 'Color', [colors(module+1, 1), colors(module+1, 2), colors(module+1, 3)]);
        module_count = module_count + 1;
    end
    hold off
    
    box on
    grid on
    xlabel('\textbf{Incoming energy [keV]}');
    ylabel('\textbf{Channel Output [ADU]}');
    ylim([0 1000])
    xlim([0, 2000]);
    %xticks([0:10000:50000])
    %xticklabels([0:10:50])
    %yticks([0:200:1600])
    set(gcf, 'Color', 'w');
    title("\textbf{Mean transfer function for modules on row " + string(row) + "}");
    hleg = legend("0", "1", "2", "3", "4", "5", "Location", "southeast");
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
clearvars -except fdt_allmodules dac_values ch_values;
clc;

colors = distinguishable_colors(6, 'w');
module_count = 0;
for row = [0:5]
    f = figure("Visible", "off");
    hold on
    for module = [0:5]
        plot(dac_values.*0.841, fdt_allmodules(:, module_count + 1).*0.841, "LineWidth", 1, 'Color', [colors(module+1, 1), colors(module+1, 2), colors(module+1, 3)]);
        
        x = dac_values.*0.841;
        y = fdt_allmodules(:, module_count + 1).*0.841;

        % Low energy gain analysis
%         x_low = ;
%         y_low = ;
%         c_low = polyfit(x, y, 1);
%         mdl_low = fitlm(x, y)
        
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
    hleg = legend("0", "1", "2", "3", "4", "5", "Location", "southeast");
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

