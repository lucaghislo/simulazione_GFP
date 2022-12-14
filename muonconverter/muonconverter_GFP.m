% muonconverter function

% Converts and plots GAPS channel output data from ADU to keV.

% INPUT
%             row: riga del GFP su cui effettuare conversione
%          module: numero del modulo sulla riga su cui fare conversione 
%    data_in_path: muon data file in path (data in ADU)
% folder_out_path: folder path of results
%           pt_in: measurement peaking time
%        fdt_data: transfer function data folder acquired at pt
%   pedestal_data: pedestal data acquired at pt
%        ch_start: first channel to analyze
%       ch_finish: last channel to analyze
%       bin_width: histogram bin width
%         max_kev: max value in keV for landau and/or plot  on x

% OUTPUT
%  muon_allch_out: muon data output after conversion (in keV)

function [muon_allch_out, landau_MPV] = muonconverter_GFP(row, module, data_in_path, folder_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish, bin_width, max_kev)
    
    % This script changes all interpreters from tex to latex. 
    list_factory = fieldnames(get(groot,'factory'));
    index_interpreter = find(contains(list_factory,'Interpreter'));
    warning('off','all')
    for i = 1:length(index_interpreter)
        default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
        set(groot, default_name,'latex');
    end

    disp("MODULE " + string(module) + " ON ROW " +  string(row) + ": CHANNELS " + string(ch_start) + " - " + string(ch_finish));
    
    % Fattore di conversion DAC_inj_code to keV
    conv_factor = 0.841;
    % Range canali di interesse
    ch_values = [ch_start:ch_finish]; 
    
    % Pedestal da output script Matlab GAPS
    pedestal_raw = readtable(pedestal_data);
    pedestal_data_allch = pedestal_raw.Var1;

    % Compute fdt data for each channel
    dac_values_raw = readtable(fdt_data + "/Row0Module0Ch0.txt");
    dac_values = unique(dac_values_raw.Cal_V);
    fdt_data_allch = nan(length(dac_values), 32);
    fdt_CAL10_allch = nan(32, 1);
    
    % FDT calcolata solo sui canali di interesse
    ch_count = 0;
    for ch = ch_values
        filename = fdt_data + "/Row" + string(row) + "Module" + string(module) + "Ch" + string(ch) + ".txt";
        if isfile(filename)
            fdt_data_raw = readtable(filename);
            fdt_data_allch(:, ch_count + 1) = fdt_data_raw.ADC;
            fdt_CAL10_allch(ch+1, 1) = fdt_data_raw.ADC(fdt_data_raw.Cal_V == 10);
            ch_count = ch_count + 1;
        else
            ch_values = ch_values(ch_values~=ch);
            fdt_data_allch(:, ch_count + 1) = nan;
        end  
    end

    if ch_count > 0
        % Definizione range calcolo spline
        % Spline calcolata solo sui canali richiesti da utente (efficiency...)
        tic
        min_DACinj = 0; % DAC_inj_code
        max_DACinj = 64000; % DAC_inj_code
        step_DACinj = 1; % DAC_inj_code
        range = [min_DACinj:step_DACinj:max_DACinj]';
        
        pt = pt_in; % Peaking time selezionato da utente
        spline_allchs_pt = nan(length(range), (ch_finish - ch_start) + 1);
        ch_count = 0;
        
        % Calcolo spline per definizione lookup table sui canali di interesse
        % per la conversione
        fdt_data_allch_noped = fdt_data_allch;
        disp("Calcolo spline");
        for ch = ch_values
            fdt_data_ch = fdt_data_allch(:, ch_count + 1);
            fdt_data_ch = fdt_data_ch - pedestal_data_allch(ch_count+1);
            fdt_data_allch_noped(:, ch_count + 1) = fdt_data_ch;
            spline_allchs_pt(:, ch_count + 1) = interp1(dac_values, fdt_data_ch, range, 'spline');
            disp("Canale: " + string(ch));
        
            [val, idx] = unique(spline_allchs_pt(:, ch_count + 1));
        
            for i = 1:length(spline_allchs_pt(:, ch_count + 1))
                if isempty(find(idx==i))
                    spline_allchs_pt(i, ch_count + 1) = spline_allchs_pt(i, ch_count + 1) + step_DACinj/2;
                end
            end
        
            ch_count = ch_count + 1;
        end
        elapsed = toc;
        disp("Elapsed time: " + string(elapsed));
        
        % Elaborazione dati acquisiti su modulo tramite GAPS_DAQ
        % Acquisizione dati raw in ADU da DAQ
        tic
        muon_allch_ADU = nan(100000, 3);
        out_row_ch_counter = 1;
        disp("Acquisizione dati DAQ");
        for ch_sel = ch_values
            filename_ADU = data_in_path + "row" + string(row) + "_mod" + string(module) + "_ch" + string(ch_sel) + "_ADU.dat";
            s = dir(filename_ADU);
            if s.bytes == 0
                ch_values = ch_values(ch_values~=ch);
            else
                muon_data = readtable(filename_ADU, "TreatAsMissing", "NaN", "ReadVariableNames",false, "TrimNonNumeric",true);
                muon_data = table2array(muon_data);
                disp("Canale: " + string(ch_sel) + " with " + string(length(muon_data)) + " events");
        
                row_counter = out_row_ch_counter;
                for i = [1:length(muon_data)]
                    muon_allch_ADU(row_counter, 1) = ch_sel;
                    muon_allch_ADU(row_counter, 2) = muon_data(i) - pedestal_data_allch(ch_sel+1);
                    muon_allch_ADU(row_counter, 3) = muon_data(i);
                    row_counter = row_counter + 1;
                end
    
                out_row_ch_counter = out_row_ch_counter + i;
            end
        end
        elapsed = toc;
        disp("Elapsed time: " + string(elapsed));
    
        % Conversione ADU -> keV tramite interpolazione spline
        tic
        muon_allch = muon_allch_ADU;
        ch_count = 1;
        out_row_ch_counter = 1;
        disp("Conversione dati in keV");
        for ch = ch_values
            muon_data_ch_ADU = muon_allch_ADU(muon_allch_ADU(:, 1) == ch, 2);
            events_kev = interp1(spline_allchs_pt(:, ch_count + 1), range, muon_data_ch_ADU, 'cubic') * conv_factor;
            disp("Canale: " + string(ch));
    
            row_counter = out_row_ch_counter;
            for i = [1:length(events_kev)]
                muon_allch(row_counter, 1) = ch_sel;
                muon_allch(row_counter, 2) = events_kev(i);
                row_counter = row_counter + 1;
            end
    
            out_row_ch_counter = out_row_ch_counter + i;
        end
        
        muon_allch = muon_allch(:, 2);
        muon_allch_out = muon_allch;
        muon_allch_ADU = muon_allch_ADU(:, 3);
        elapsed = toc;
        disp("Elapsed time: " + string(elapsed));
        
        % Salvataggio di diversi plot nel folder specificato da utente
        if ~exist(folder_out_path, 'dir')
            mkdir(folder_out_path);
        end
    
        % Istogramma degli eventi in input [ADU]
        f = figure("Visible", "off");
        histogram(muon_allch_ADU, "DisplayStyle", "stairs", 'BinWidth', bin_width, 'LineWidth', 1);
        box on
        grid on
        set(gca, 'YScale', 'log')
        xlim([0, 2047])\
        ylabel("\textbf{Counts}")
        xlabel("\textbf{Incoming energy [ADU]}")
        title("\textbf{Incoming energy spectrum before conversion}")
        set(gca,'FontSize', 12)
        f.Position = [10 30 1000  650];
        exportgraphics(gcf,folder_out_path + "/energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_ADU.pdf",'ContentType','vector');
        disp("SAVED: energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_ADU.pdf");

        % Istogramma senza interpolazione Landau (scala logaritmica)
        dati_EDEP_raw = readtable("C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\events\EDEP\row" + string(row) + "_mod" + string(module) + "_allch_EDEP.dat", "ReadRowNames", false, "ReadVariableNames", false);
        dati_EDEP_raw = table2cell(dati_EDEP_raw)';
        %dati_EDEP_raw = cat(2, dati_EDEP_raw{:});
        dati_EDEP_raw = horzcat(dati_EDEP_raw{:});
        dati_EDEP = str2num(dati_EDEP_raw)'; %#ok<ST2NM> 
        
        f = figure("Visible", "off");
        hold on
        histogram(dati_EDEP.*1000, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1); % bin_width = 20
        histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1); % bin_width = 20
        hold off

        set(gca, 'YScale', 'log')
        box on
        grid on
        xlim([0, max_kev])
        ylabel("\textbf{Counts}")
        xlabel("\textbf{Incoming energy [keV]}")
        title("\textbf{Energy deposition for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$}");
        set(gca,'FontSize', 12)
        legend("Energy deposition Nadir", "Energy deposition Luca", "Location", "best")

        f.Position = [10 30 1000  650];
        exportgraphics(gcf, folder_out_path + "/energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_keV.pdf", 'ContentType', 'vector');
        disp("SAVED: energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_keV.pdf")

        % Istogramma con interpolazione Landau (senza piedistallo, scala
        % lineare)
        f = figure("Visible", "off");
    
        % TODO determinare dinamicamente taglio piedistallo
        [vpp, sig, mv, bound] = histfitlandau(muon_allch(muon_allch > 200), bin_width, 0, max_kev, 1); % bin_width = 15 ok
        box on
        grid on
        xlim([0, max_kev])
        ylabel("\textbf{Counts}")
        xlabel("\textbf{Incoming energy [keV]}")
        title("\textbf{Energy deposition for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$}");
        set(gca,'FontSize', 12)
        f.Position = [10 30 1000  650];
        exportgraphics(gcf, folder_out_path + "/energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_keV_landau.pdf", 'ContentType', 'vector');
        disp("SAVED: energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_keV_landau.pdf")

        % Plot funzione di trasferimento prima della sottrazione del
        % piedistallo
        ch_count = 0;
        f = figure("Visible", "off");
        hold on
        for ch = ch_values
            plot(dac_values.*0.841, fdt_data_allch(:, ch_count + 1).*0.841);
            ch_count = ch_count + 1;
        end
        hold off
        
        box on
        grid on
        xlabel('\textbf{Incoming energy [MeV]}');
        ylabel('\textbf{Channel Output [ADU]}');
        ylim([0 2000])
        xlim([0, 53824]);
        xticks([0:10000:50000])
        xticklabels([0:10:50])
        yticks([0:200:2000])
        set(gcf, 'Color', 'w');
        title("\textbf{Transfer function for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$}")
        
        ax = gca; 
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize;
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1200 800];
        
        exportgraphics(gcf, folder_out_path + "/transfer_function_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +".pdf",'ContentType','vector');
        disp("SAVED: transfer_function_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +".pdf")

        landau_MPV = vpp;
    
        % Plot funzione di trasferimento successivamente alla sottrazione del
        % piedistallo
        ch_count = 0;
        f = figure("Visible", "off");
        hold on
        for ch = ch_values
            plot(dac_values.*0.841, fdt_data_allch_noped(:, ch_count + 1).*0.841);
            ch_count = ch_count + 1;
        end
        hold off
        
        box on
        grid on
        xlabel('\textbf{Incoming energy [MeV]}');
        ylabel('\textbf{Channel Output [ADU]}');
        ylim([0 2000])
        xlim([0, 53824]);
        xticks([0:10000:50000])
        xticklabels([0:10:50])
        yticks([0:200:2000])
        set(gcf, 'Color', 'w');
        title("\textbf{Transfer function for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$ with pedestal subtracted}")
        
        ax = gca; 
        fontsize = 12;
        ax.XAxis.FontSize = fontsize; 
        ax.YAxis.FontSize = fontsize;
        ax.Title.FontSize = fontsize + 4;
        f.Position = [0 0 1200 800];
        
        exportgraphics(gcf, folder_out_path + "/transfer_function_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_no-pedestal.pdf",'ContentType','vector');
        disp("SAVED: transfer_function_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_no-pedestal.pdf")
        pedestal_diff = abs(fdt_CAL10_allch - pedestal_data_allch);

        % Plot confronto piedistallo misurato iniettando 10 DAC_inj vs
        % misurato senza iniezione
        colors = distinguishable_colors(3, 'w');
        f = figure("Visible", "off");
        hold on
        p1 = plot([0:31], fdt_CAL10_allch, "LineWidth", 1, "Marker", "o", "Color", [colors(1, 1), colors(1, 2), colors(1, 3)], "MarkerFaceColor", [colors(1, 1), colors(1, 2), colors(1, 3)]);
        p2 = plot([0:31], pedestal_data_allch, "LineWidth", 1, "Marker", "o", "Color", [colors(2, 1), colors(2, 2), colors(2, 3)], "MarkerFaceColor", [colors(2, 1), colors(2, 2), colors(2, 3)]);
        p3 = plot([0:31], pedestal_diff, "LineWidth", 1, "LineStyle", "--", "Color", [colors(3, 1), colors(3, 2), colors(3, 3)]);
        hold off

        box on
        grid on
        xlim([0 31]);
        xlabel("\textbf{Channel}")
        ylabel("\textbf{[ADU]}")
        %legend("Pedestal evaluated from FDT @ 10 DAC\_inj\_code", "Pedestal evalueted from ENC", "Pedestal difference", "Location", "best");
        legend([p1, p2, p3], "Pedestal evaluated from FDT @ 10 DAC\_inj\_code, $\mu = " + string(round(nanmean(fdt_CAL10_allch))) + "$ ADU", ...
                "Pedestal obtained from ENC, $\mu = " + string(round(nanmean(pedestal_data_allch))) + "$ ADU", ...
                "Pedestal difference, $\mu = " + string(round(nanmean(pedestal_diff))) + "$ ADU", ...
                'Location', 'best') %#ok<*NANMEAN> 
        title("\textbf{Pedestal measured when injecting 10 DAC\_inj\_code vs without injection}")

        set(gca,'FontSize', 12)
        f.Position = [10 30 1000  650];
        exportgraphics(gcf,folder_out_path + "/pedestal_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +".pdf",'ContentType','vector');
        disp("SAVED: pedestal_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +".pdf");

    else
        muon_allch_out = nan;
        landau_MPV = nan;
        disp("No FDT found!");
    end
end
