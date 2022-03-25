function PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
    subplot(3, 1, 1)
    plot(wave_data)
    line([wave_start*FrameInc, wave_start*FrameInc], [-1, 1], 'Color', 'red')
    line([wave_end*FrameInc, wave_end*FrameInc], [-1, 1], 'Color', 'red')
    ylabel 'Sound'
%     axis([1, length(wave_data), 0, max(wave_data)])
    subplot(3, 1, 2)
    plot(energy)
    line([wave_start, wave_start], [0, max(energy)], 'Color', 'red')
    line([wave_end, wave_end], [0, max(energy)], 'Color', 'red')
    ylabel 'Energy'
%     axis([1, length(wave_data), 0, max(wave_data)])
    subplot(3, 1, 3)
    plot(ZeroCrossRate)
    line([wave_start, wave_start], [min(ZeroCrossRate), max(ZeroCrossRate)], 'Color', 'red')
    line([wave_end, wave_end], [min(ZeroCrossRate), max(ZeroCrossRate)], 'Color', 'red')
    ylabel 'ZeroCrossRate'
end