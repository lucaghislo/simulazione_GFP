% muonconverter function

% Converts and plots GAPS channel output data from ADU to keV.

% INPUT
%   data_in_path: muon data file in path (data in ADU)
%  plot_out_path: plot file out file
%          pt_in: measurement peaking time
%       fdt_data: transfer function data acquired at pt
%  pedestal_data: pedestal data acquired at pt
%       ch_start: first channel to analyze
%      ch_finish: last channel to analyze
%    landau_flag: (true/false) plot with or without landau fit
%         fig_on: (true/false) show or hide plot figure
%      bin_width: histogram bin width
%        max_kev: max value in keV for landau and/or plot  on x

% OUTPUT
% muon_allch_out: muon data output after conversion (in keV)

% USAGE EXAMPLES
% muonconverter(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data)
% channels from 0 to 31, no landau fitting, bin width = 20 and X scale maximum value set to 6000

% muonconverter(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish)
% same as above but with custom channel selection

% muonconverter(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish, landau_flag, fig_on, bin_width, max_kev)
% full custom parameters

function [muon_allch_out] = muonconverter_v2(data_in_path, plot_out_path, pt_in, fdt_data, pedestal_data, ch_start, ch_finish, landau_flag, fig_on, bin_width, max_kev)

    if ~exist('ch_start','var') & ~exist('ch_finish','var') & ~exist('landau_flag','var') & ~exist('fig_on','var') & ~exist('bin_width','var') & ~exist('max_kev','var')
        ch_start = 0;
        ch_finish = 31;
        landau_flag = false;
        fig_on = true;
        bin_width = 20;
        max_kev = 6000;
    end

    if ~exist('landau_flag','var') & ~exist('fig_on','var') & ~exist('bin_width','var') & ~exist('max_kev','var')
        landau_flag = false;
        fig_on = true;
        bin_width = 20;
        max_kev = 6000;
    end

    if ch_start > ch_finish
        error("Channel range error! First channel must be greater than last channel.")
    end
    
    if ch_start<0 || ch_finish>31
        error("Channel range error! Channels must be between 0 and 31.")
    end

    % pedestal da output script Matlab GAPS
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
    dac_values = unique(data_raw.DAC);
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
    
    min_DACinj = 0;
    max_DACinj = 64000;
    step_DACinj = 1;
    range = [min_DACinj:step_DACinj:max_DACinj]';
    ch_values = [0:31];
    
    pt = pt_in;
    spline_allchs_pt = nan(length(range), 32);
    ch_count = 0;
    for ch = [ch_start:ch_finish]
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

    %spline_allchs_pt_table = array2table(spline_allchs_pt);
    %writetable(spline_allchs_pt_table, "fdt_lookup_table\output\lookup_tables_no-ped\lookup_table_no-ped_allch_pt" + string(pt) + ".dat", "Delimiter", "\t");


    muon_data = readtable(data_in_path);
    %spline_allchs_pt = readtable("lookup_tables_no_pedestal\lookup_table_no-ped_allch_pt" + string(pt) + ".dat");
    %spline_allchs_pt = table2array(spline_allchs_pt);
    
    muon_allch = nan(9528, 32);
    
    for ch = [ch_start:ch_finish]
        muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch) - pedestal_data_allch(ch+1);
        events_kev = interp1(spline_allchs_pt(:, ch + 1), range, muon_data_ch_ADU, 'cubic') * 0.841;
        muon_allch(:, ch+1) = events_kev;
    end
    
    muon_allch = reshape(muon_allch', [], 1);
    
    if fig_on
        fig_on_flag = "on";
    else
        fig_on_flag = "off";
    end

    f = figure("Visible", fig_on_flag);
    
    if landau_flag
        histfitlandau(muon_allch(muon_allch>100), bin_width, 0, max_kev, 1); % bin_width = 15
    else
        histogram(muon_allch, "DisplayStyle", "stairs", 'BinWidth', bin_width, 'LineWidth', 1); % bin_width = 20
        set(gca, 'YScale', 'log')
    end

    muon_allch_out = muon_allch(~isnan(muon_allch));
    
    box on
    grid on
    xlim([0, max_kev])
    ylabel("\textbf{Counts}")
    xlabel("\textbf{Incoming energy [keV]}")
    set(gca,'FontSize', 12)
    f.Position = [10 30 1000  650];
    
    exportgraphics(gcf, plot_out_path, 'ContentType', 'vector');
end
