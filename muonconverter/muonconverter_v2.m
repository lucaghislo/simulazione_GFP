% muonconverter function

% Converts and plots GAPS channel output data from ADU to keV.

% INPUT
%    data_in_path: muon data file in path (data in ADU)
% folder_out_path: folder path of results
%           pt_in: measurement peaking time
%       f dt_data: transfer function data acquired at pt
%   pedestal_data: pedestal data acquired at pt
%        ch_start: first channel to analyze
%       ch_finish: last channel to analyze
%       bin_width: histogram bin width
%         max_kev: max value in keV for landau and/or plot  on x

% OUTPUT
%  muon_allch_out: muon data output after conversion (in keV)

% USAGE EXAMPLES
% 1) muonconverter(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data)
% channels from 0 to 31, no landau fitting, bin width = 20 and X scale maximum value set to 6000

% 2) muonconverter(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish)
% same as above but with custom channel selection

% 3) muonconverter(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish, bin_width, max_kev)
% full custom parameters

function [muon_allch_out] = muonconverter_v2(data_in_path, folder_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish, bin_width, max_kev)

    % Check for existing parameters (1)
    if ~exist('ch_start','var') & ~exist('ch_finish','var') & ~exist('bin_width','var') & ~exist('max_kev','var')
        ch_start = 0;
        ch_finish = 31;
        bin_width = 20;
        max_kev = 6000;
    end
    
    % Check for existing parameters (2)
    if ~exist('landau_flag','var') & ~exist('fig_on','var') & ~exist('bin_width','var') & ~exist('max_kev','var')
        bin_width = 20;
        max_kev = 6000;
    end
    
    % Check for input channel range correctness
    if ch_start > ch_finish
        error("Channel range error! First channel must be greater than last channel.")
    end
    
    if ch_start<0 || ch_finish>31
        error("Channel range error! Channels must be between 0 and 31.")
    end
    
    % Fattore di conversion DAC_inj_code to keV
    conv_factor = 0.841;
    
    % Pedestal da output script Matlab GAPS
    pedestal_raw = readtable(pedestal_data);
    
    % Compute pedestal data for each channel
    pedestal_data_allch = nan((ch_finish-ch_start)+1, 1);
    ch_count = 1;
    for ch = [ch_start:ch_finish]
        pedestal_data_allch(ch_count) = mean(pedestal_raw.Value(pedestal_raw.CH_ == ch & (pedestal_raw.Type == 0 | pedestal_raw.Type == 10)));
        ch_count = ch_count + 1;
    end
    
    % Compute fdt data for each channel
    data_raw = readtable(fdt_data);
    dac_values = unique(data_raw.DAC); % dac_values ottenuti in base agli step impostati in fase di acqusizione FDT
    dac_values = dac_values(~isnan(dac_values))';
    fdt_allch_tau = nan(length(dac_values), 32);
    
    ch_count = 1;
    for channel = [ch_start:ch_finish]
        fdt_allenergies = nan(length(dac_values), 1);
        dac_counter = 0;
    
        for dac = dac_values
            data_dac_ch = data_raw.Value(data_raw.DAC == dac & data_raw.CH_ == channel);
            fdt_allenergies(dac_counter+1, 1) = mean(data_dac_ch);
            dac_counter = dac_counter + 1;
        end
    
        fdt_allch_tau(:, ch_count) = fdt_allenergies;
        ch_count = ch_count + 1;
    end
    
    % Definizione range calcolo spline
    min_DACinj = 0; % ADU_inj_code
    max_DACinj = 64000; % ADU_inj_code
    step_DACinj = 1; % ADU_inj_code
    range = [min_DACinj:step_DACinj:max_DACinj]';
    ch_values = [ch_start:ch_finish]; % Spline calcolata solo sui canali richiesti da utente (efficiency...)
    
    pt = pt_in; % Peaking time selezionato da utente
    spline_allchs_pt = nan(length(range), (ch_finish - ch_start) + 1);
    ch_count = 0;
    
    % Calcolo spline per definizione lookup table sui canali di interesse
    % per la conversione
    for ch = ch_values
        fdt_data_ch = fdt_allch_tau(:, ch_count + 1);
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
    muon_data = readtable(data_in_path);
    muon_allch = nan(9528, 32); % change to be dynamic
    ch_count = 0;
    
    for ch = ch_values
        muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch) - pedestal_data_allch(ch_count + 1);
        events_kev = interp1(spline_allchs_pt(:, ch_count + 1), range, muon_data_ch_ADU, 'cubic') * conv_factor;
        muon_allch(:, ch_count + 1) = events_kev;
        ch_count = ch_count + 1;
    end
    
    muon_allch = reshape(muon_allch', [], 1);
    muon_allch_out = muon_allch(~isnan(muon_allch));
    
    % TODO salvataggio di diversi plot nel folder specificato da utente
    if ~exist(folder_out_path, 'dir')
        mkdir(folder_out_path);
    end
    
    % Istogramma senza interpolazione Landau (con piedistallo, scala logaritmica)
    f = figure("Visible", "off");
    histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', bin_width, 'LineWidth', 1); % bin_width = 20
    set(gca, 'YScale', 'log')
    box on
    grid on
    xlim([0, max_kev])
    ylabel("\textbf{Counts}")
    xlabel("\textbf{Incoming energy [keV]}")
    set(gca,'FontSize', 12)
    f.Position = [10 30 1000  650];
    exportgraphics(gcf, folder_out_path + "/energy_spectrum_pt" + string(pt) + "_keV.pdf", 'ContentType', 'vector');
    
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
    set(gca,'FontSize', 12)
    f.Position = [10 30 1000  650];
    exportgraphics(gcf, folder_out_path + "/energy_spectrum_pt" + string(pt) + "_keV_landau.pdf", 'ContentType', 'vector');

end
