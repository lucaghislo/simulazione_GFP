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

function [muon_allch_out] = muonconverter_GFP(row, module, data_in_path, folder_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish, bin_width, max_kev)
    
    % Fattore di conversion DAC_inj_code to keV
    conv_factor = 0.841;
    
    % Pedestal da output script Matlab GAPS
    pedestal_raw = readtable(pedestal_data);
    pedestal_data_allch = pedestal_raw.Var1;

    
    % Compute fdt data for each channel
    dac_values_raw = readtable(fdt_data + "/Row0Module0Ch0.txt");
    dac_values = unique(dac_values_raw.Cal_V);
    fdt_data_allch = nan(length(dac_values), 32);
    ch_values = [ch_start:ch_finish]; % Range canali di interesse
    
    % FDT calcolata solo sui canali di interesse
    ch_count = 0;
    for ch = ch_values
        fdt_data_raw = readtable(fdt_data + "/Row" + string(row) + "Module" + string(module) + "Ch" + string(ch) + ".txt");
        fdt_data_allch(:, ch_count + 1) = fdt_data_raw.ADC;
        ch_count = ch_count + 1;
    end
    
    % Definizione range calcolo spline
    % Spline calcolata solo sui canali richiesti da utente (efficiency...)
    min_DACinj = 0; % DAC_inj_code
    max_DACinj = 64000; % DAC_inj_code
    step_DACinj = 1; % DAC_inj_code
    range = [min_DACinj:step_DACinj:max_DACinj]';
    
    pt = pt_in; % Peaking time selezionato da utente
    spline_allchs_pt = nan(length(range), (ch_finish - ch_start) + 1);
    ch_count = 0;
    
    % Calcolo spline per definizione lookup table sui canali di interesse
    % per la conversione
    for ch = ch_values
        fdt_data_ch = fdt_data_allch(:, ch_count + 1);
        fdt_data_ch = fdt_data_ch - pedestal_data_allch(ch_count+1);
    
        spline_allchs_pt(:, ch_count + 1) = interp1(dac_values, fdt_data_ch, range, 'spline');
    
        [val, idx] = unique(spline_allchs_pt(:, ch_count + 1));
    
        for i = 1:length(spline_allchs_pt(:, ch_count + 1))
            if isempty(find(idx==i))
                spline_allchs_pt(i, ch_count + 1) = spline_allchs_pt(i, ch_count + 1) + step_DACinj/2;
            end
        end
    
        ch_count = ch_count + 1;
    end
    
    % Elaborazione dati acquisiti su modulo tramite GAPS_DAQ
    % Acquisizione dati raw in ADU da DAQ
    muon_data = readtable(data_in_path, "TreatAsMissing", "NaN", "ReadVariableNames",false, "TrimNonNumeric",true);
    muon_data = table2array(muon_data);
    
    for i = 1:size(muon_data, 1)
        for j = 1:size(muon_data, 2)
            if isempty(muon_data{i,j})
                muon_data{i,j} = nan;
            end
        end
    end

    muon_data = cell2mat(muon_data);
    muon_data = muon_data';

    % Variabili in uscita
    muon_allch = nan(9528, (ch_finish - ch_start) + 1); % change to be dynamic
    muon_allch_ADU = nan(9528, (ch_finish - ch_start) + 1); % change to be dynamic
    ch_count = 0;
    
    % TODO 
    % Acquisire dati modulo per canale anche quando il numero di canali per
    % modulo è inferiore al numero richiesto dal range (max 32)
    for ch = ch_values
        muon_data_single = cell2mat(muon_data(:, ch + 1));
        muon_data_ch_ADU = muon_data_single - pedestal_data_allch(ch_count + 1);
        events_kev = interp1(spline_allchs_pt(:, ch_count + 1), range, muon_data_ch_ADU, 'cubic') * conv_factor;
        muon_allch(:, ch_count + 1) = events_kev;
        muon_allch_ADU(:, ch_count + 1) = muon_data.Energy_ADC_(muon_data.Channel == ch);
        ch_count = ch_count + 1;
    end
    
    muon_allch = reshape(muon_allch', [], 1);
    muon_allch_out = muon_allch(~isnan(muon_allch));
    
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
    xlim([0, 2047])
    ylabel("\textbf{Counts}")
    xlabel("\textbf{Incoming energy [ADU]}")
    title("\textbf{Incoming energy spectrum before conversion}")
    set(gca,'FontSize', 12)
    f.Position = [10 30 1000  650];
    exportgraphics(gcf,folder_out_path + "/energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_ADU.pdf",'ContentType','vector');
    
    % Istogramma senza interpolazione Landau (con piedistallo, scala logaritmica)
    f = figure("Visible", "off");
    histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', 20, 'LineWidth', 1); % bin_width = 20
    set(gca, 'YScale', 'log')
    box on
    grid on
    xlim([0, max_kev])
    ylabel("\textbf{Counts}")
    xlabel("\textbf{Incoming energy [keV]}")
    title("\textbf{Energy deposition for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$}");
    set(gca,'FontSize', 12)
    f.Position = [10 30 1000  650];
    exportgraphics(gcf, folder_out_path + "/energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_keV.pdf", 'ContentType', 'vector');
    
    % Istogramma con interpolazione Landau (senza piedistallo, scala
    % lineare)
    f = figure("Visible", "off");

    % TODO determinare dinamicamente taglio piedistallo
    histfitlandau(muon_allch(muon_allch > 200), bin_width, 0, max_kev, 1); % bin_width = 15 ok
    box on
    grid on
    xlim([0, max_kev])
    ylabel("\textbf{Counts}")
    xlabel("\textbf{Incoming energy [keV]}")
    title("\textbf{Energy deposition for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$}");
    set(gca,'FontSize', 12)
    f.Position = [10 30 1000  650];
    exportgraphics(gcf, folder_out_path + "/energy_spectrum_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_keV_landau.pdf", 'ContentType', 'vector');

    % Plot funzione di trasferimento prima della sottrazione del
    % piedistallo
    ch_count = 0;
    f = figure("Visible", "off");
    hold on
    for ch = [ch_start:ch_finish]
        plot(dac_values.*0.841, fdt_data_allch(:, ch_count + 1).*0.841);
        ch_count = ch_count + 1;
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
    title("\textbf{Transfer function for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$} with pedestal subtracted")
    
    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, folder_out_path + "/transfer_function_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +".pdf",'ContentType','vector');

    % Plot funzione di trasferimento successivamente alla sottrazione del
    % piedistallo
    ch_count = 0;
    f = figure("Visible", "off");
    hold on
    for ch = [ch_start:ch_finish]
        plot(dac_values.*0.841, fdt_data_allch(:, ch_count + 1).*0.841);
        ch_count = ch_count + 1;
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
    title("\textbf{Transfer function for channels " + string(ch_start) + " - " + string(ch_finish) + " at \boldmath$\tau_{" + string(pt) + "}$}")
    
    ax = gca; 
    fontsize = 12;
    ax.XAxis.FontSize = fontsize; 
    ax.YAxis.FontSize = fontsize;
    ax.Title.FontSize = fontsize + 4;
    f.Position = [0 0 1200 800];
    
    exportgraphics(gcf, folder_out_path + "/transfer_function_pt" + string(pt) + "_ch" + string(ch_start) + "-" + string(ch_finish) +"_no-pedestal.pdf",'ContentType','vector');
end
