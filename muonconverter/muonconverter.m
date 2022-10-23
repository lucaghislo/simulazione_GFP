% muonconverter function

% Converts and plots GAPS channel output data from ADU to keV.

% INPUT
%   data_in_path: muon data file in path (data in ADU)
%             pt: measurement peaking time
%       ch_start: first channel to analyze
%      ch_finish: last channel to analyze
%  plot_out_path: plot file out file
%    landau_flag: (true/false) plot with or without landau fit
%         fig_on: (true/false) show or hide plot figure
%      bin_width: histogram bin width
%        max_kev: max value in keV for landau and/or plot  on x

% OUTPUT
% muon_allch_out: muon data output after conversion (in keV)

function [muon_allch_out] = muonconverter(data_in_path, pt, ch_start, ch_finish, plot_out_path, landau_flag, fig_on, bin_width, max_kev)

    if ch_start>ch_finish
        error("Channel range error! Starting channel must be greater than finishin channel.")
    end
    
    if ch_start<0 || ch_finish>31
        error("Channel range error! Channels must be between 0 and 31.")
    end

    range = table2array(readtable("range.dat"));
    muon_data = readtable(data_in_path);
    spline_allchs_pt = readtable("lookup_tables\lookup_table_allch_pt" + string(pt) + ".dat");
    spline_allchs_pt = table2array(spline_allchs_pt);
    
    muon_allch = nan(9528, 32);
    
    for ch = [ch_start:ch_finish]
        muon_data_ch_ADU = muon_data.Energy_ADC_(muon_data.Channel == ch);
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
