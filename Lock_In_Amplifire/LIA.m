clc;
clear;
close all;

%% Parameters
fs = 10e6;                 % Sampling frequency (10 MHz)
t = 0:1/fs:5e-3;          % Longer time → better averaging
f_ref = 100e3;            % 100 kHz

%% Laser Modulation (Square Wave)
laser_amp = 1;
laser = laser_amp * square(2*pi*f_ref*t);

%% Photodiode + Amplifier Model
gain = 5;
phase_shift = pi/6;       % 30 degrees

signal = gain * square(2*pi*f_ref*t + phase_shift);

%% Add Noise
noise = 0.5 * randn(size(t));
signal_noisy = signal + noise;

%% Reference Signals (Lock-in)
ref_cos = cos(2*pi*f_ref*t);
ref_sin = sin(2*pi*f_ref*t);

%% Mixing
X_mix = signal_noisy .* ref_cos;
Y_mix = signal_noisy .* ref_sin;

%% FIR Low-pass Filter (Better than moving avg)
fc = 2e3;                 % 2 kHz cutoff
N = 128;                  % filter order

b = fir1(N, fc/(fs/2));   % FIR design

X = filter(b,1,X_mix);
Y = filter(b,1,Y_mix);

%% Remove filter transient (IMPORTANT)
X = X(N:end);
Y = Y(N:end);

%% Strong Averaging (Lock-in integration)
X_dc = mean(X(end-20000:end));
Y_dc = mean(Y(end-20000:end));

%% Amplitude and Phase
Amplitude = sqrt(X_dc^2 + Y_dc^2);
Phase = atan2(Y_dc, X_dc);

%% Square-wave correction (VERY IMPORTANT)
Amplitude_corrected = Amplitude * (pi/4);

%% Display
fprintf('Estimated Amplitude: %f\n', Amplitude_corrected);
fprintf('Estimated Phase (deg): %f\n', rad2deg(Phase));

%% Plot
figure;

subplot(3,1,1);
plot(t, signal_noisy);
title('Noisy Photodiode Signal');

subplot(3,1,2);
plot(X);
hold on;
plot(Y);
legend('X','Y');
title('After Lock-in (Filtered)');

subplot(3,1,3);
plot(t, laser);
title('Laser Square Wave');
