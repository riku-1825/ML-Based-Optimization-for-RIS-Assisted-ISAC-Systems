clc;
clear;
close all;

%% ================= SYSTEM =================
M = 6;
N = 49;
K = 4;

P_dbm_range = 27:32;
P_W_range = 10.^((P_dbm_range-30)/10);

N_sim = 500;

%% ================= PARAMETERS =================
Prms.M = M;
Prms.N = N;
Prms.K = K;

% ---- MORE STABLE NOISE VALUES ----
Prms.sigmar2 = 1e-9;
Prms.sigmak2 = 1e-9;
Prms.sigmat2 = 1;

Prms.L = 1024;
Prms.Nmax = 30;
Prms.res_th = 1e-4;

% ---- REDUCED TARGET SINR ----
Prms.gammat = 1;

%% ===== CHANNEL PARAMETERS =====
drt = 3;
dg = 50;
drk = 8;

alpha_t  = 2.4;
alpha_rt = 2.2;
alpha_k  = 3.5;
alpha_rk = 2.3;
alpha_g  = 2.2;

kappa = 10^(3/10);

%% ================= STORAGE =================

% ---- ESTIMATE DIMENSIONS ----
input_dim = ...
    1 + ...                 % Power
    2*M + ...               % hdt
    2*N + ...               % hrt
    2*N*M + ...             % G
    2*K*M + ...             % Hu
    2*K*N;                  % Hru

output_dim = ...
    2*M*(K+M) + ...         % W
    2*N + ...               % phi
    1;                      % valid flag

X_data = zeros(length(P_W_range), N_sim, input_dim);
Y_data = zeros(length(P_W_range), N_sim, output_dim);

%% ================= FEATURE NAMES =================
feature_names = {};
feature_names{end+1} = 'P';

for i = 1:M
    feature_names{end+1} = sprintf('hd_t_real_%d',i);
end
for i = 1:M
    feature_names{end+1} = sprintf('hd_t_imag_%d',i);
end

for i = 1:N
    feature_names{end+1} = sprintf('hr_t_real_%d',i);
end
for i = 1:N
    feature_names{end+1} = sprintf('hr_t_imag_%d',i);
end

for j = 1:M
    for i = 1:N
        feature_names{end+1} = sprintf('G_real_%d_%d',i,j);
    end
end

for j = 1:M
    for i = 1:N
        feature_names{end+1} = sprintf('G_imag_%d_%d',i,j);
    end
end

for k = 1:K

    for i = 1:M
        feature_names{end+1} = sprintf('hd_k%d_real_%d',k,i);
    end

    for i = 1:M
        feature_names{end+1} = sprintf('hd_k%d_imag_%d',k,i);
    end
end

for k = 1:K

    for i = 1:N
        feature_names{end+1} = sprintf('hr_k%d_real_%d',k,i);
    end

    for i = 1:N
        feature_names{end+1} = sprintf('hr_k%d_imag_%d',k,i);
    end
end

%% ================= LABEL NAMES =================
label_names = {};

for j = 1:(K+M)

    for i = 1:M
        label_names{end+1} = sprintf('W_real_%d_%d',i,j);
    end
end

for j = 1:(K+M)

    for i = 1:M
        label_names{end+1} = sprintf('W_imag_%d_%d',i,j);
    end
end

for i = 1:N
    label_names{end+1} = sprintf('phi_real_%d',i);
end

for i = 1:N
    label_names{end+1} = sprintf('phi_imag_%d',i);
end

label_names{end+1} = 'valid_flag';

%% ================= COUNTERS =================
total_valid = 0;
total_invalid = 0;

%% ================= MAIN LOOP =================

for p_idx = 1:length(P_W_range)

    fprintf('\n=====================================================\n');
    fprintf('POWER LEVEL %d / %d\n', p_idx, length(P_W_range));
    fprintf('=====================================================\n');

    P = P_W_range(p_idx);
    Prms.P = P;

    tic;

    parfor sim = 1:N_sim

        %% =====================================================
        % CHANNEL GENERATION
        %% =====================================================

        theta2 = rand()*pi;
        thetar = rand()*pi;

        theta1 = atan2( ...
            (dg*sin(thetar)-drt*cos(theta2)), ...
            (dg*cos(thetar)+drt*sin(theta2)));

        if abs(sin(theta1)) < 1e-3
            theta1 = theta1 + 1e-2;
        end

        dt = abs((dg*sin(thetar)-drt*cos(theta2)) ...
            /(sin(theta1)+1e-8));

        %% ===== BS -> TARGET =====
        hdt = sqrt(10^(-3)*dt^(-alpha_t)) * ...
            exp(-1j*(0:M-1)'*pi*sin(theta1)) / sqrt(M);

        %% ===== RIS -> TARGET =====
        hrt = sqrt(10^(-3)*drt^(-alpha_rt)) * ...
            exp(-1j*(0:N-1)'*pi*sin(theta2));

        %% ===== BS -> RIS =====
        GLos = sqrt(kappa/(1+kappa)) ...
            * sqrt(10^(-3)*dg^(-alpha_g)) ...
            * exp(-1j*(0:N-1)'*pi*sin(thetar)) ...
            * exp(-1j*(0:M-1)*pi*sin(-thetar)) ...
            / sqrt(M);

        G = GLos + ...
            sqrt(1/(1+kappa)) ...
            * sqrt(10^(-3)*dg^(-alpha_g)) ...
            * (randn(N,M)+1i*randn(N,M))/sqrt(2*M);

        %% ===== USERS =====
        theta_ru = pi/2 * rand(K,1);

        Hu = zeros(K,M);
        Hru = zeros(K,N);

        for k = 1:K

            theta_rk = theta_ru(k);

            theta_k = atan2( ...
                (dg*sin(thetar)-drk*cos(theta_rk)), ...
                (dg*cos(thetar)+drk*sin(theta_rk)));

            if abs(sin(theta_k)) < 1e-3
                theta_k = theta_k + 1e-2;
            end

            dk = abs((dg*sin(thetar)-drk*cos(theta_rk)) ...
                /(sin(theta_k)+1e-8));

            %% USER DIRECT CHANNEL
            Hu(k,:) = ...
                sqrt(10^(-3)*dk^(-alpha_k)) * ...
                ( ...
                sqrt(kappa/(1+kappa)) ...
                * exp(-1j*(0:M-1)*pi*sin(theta_k))/sqrt(M) ...
                + ...
                sqrt(1/(1+kappa)) ...
                * (randn(1,M)+1i*randn(1,M))/sqrt(2*M) ...
                );

            %% USER RIS CHANNEL
            Hru(k,:) = ...
                sqrt(10^(-3)*drk^(-alpha_rk)) * ...
                ( ...
                sqrt(kappa/(1+kappa)) ...
                * exp(-1j*(0:N-1)*pi*sin(theta_rk)) ...
                + ...
                sqrt(1/(1+kappa)) ...
                * (randn(1,N)+1i*randn(1,N))/sqrt(2) ...
                );
        end

        %% =====================================================
        % NORMALIZATION FOR NUMERICAL STABILITY
        %% =====================================================

        hdt = hdt / (norm(hdt)+1e-8);
        hrt = hrt / (norm(hrt)+1e-8);
        G   = G   / (norm(G,'fro')+1e-8);
        Hu  = Hu  / (norm(Hu,'fro')+1e-8);
        Hru = Hru / (norm(Hru,'fro')+1e-8);

        Channel = struct( ...
            'hdt',hdt, ...
            'hrt',hrt, ...
            'G',G, ...
            'Hu',Hu, ...
            'Hru',Hru);

        %% =====================================================
        % BETTER INITIALIZATION
        %% =====================================================

        phi_init = exp(1j*2*pi*rand(N,1));

        W_init = randn(M,K+M)+1i*randn(M,K+M);

        W_init = W_init / (norm(W_init,'fro')+1e-8);

        W_init = sqrt(P) * W_init;

        %% =====================================================
        % SOLVER
        %% =====================================================

        valid_flag = 1;

        try

            [W_opt, phi_opt, ~, ~] = ...
                get_W_phi_SNR( ...
                Prms, ...
                Channel, ...
                phi_init, ...
                W_init);

        catch ME

            valid_flag = 0;

            fprintf('\n================================\n');
            fprintf('Solver Failed\n');
            fprintf('Power Index : %d\n', p_idx);
            fprintf('Simulation  : %d\n', sim);
            fprintf('Reason      : %s\n', ME.message);
            fprintf('================================\n');
        end

        %% =====================================================
        % OUTPUT VALIDATION
        %% =====================================================

        if valid_flag == 1

            if isempty(W_opt) || isempty(phi_opt)
                valid_flag = 0;
            end

            if any(isnan(W_opt(:))) || any(isinf(W_opt(:)))
                valid_flag = 0;
            end

            if any(isnan(phi_opt(:))) || any(isinf(phi_opt(:)))
                valid_flag = 0;
            end

            if norm(W_opt,'fro') < 1e-10
                valid_flag = 0;
            end

            if norm(phi_opt) < 1e-10
                valid_flag = 0;
            end
        end

        %% =====================================================
        % SKIP INVALID SAMPLES
        %% =====================================================

        if valid_flag == 0

            X_data(p_idx,sim,:) = zeros(1,input_dim);

            tempY = zeros(1,output_dim);
            tempY(end) = 0;

            Y_data(p_idx,sim,:) = tempY;

            continue;
        end

        %% =====================================================
        % PHASE NORMALIZATION
        %% =====================================================

        phi_opt = exp(1j*angle(phi_opt));

        %% =====================================================
        % POWER NORMALIZATION
        %% =====================================================

        W_opt = W_opt / (norm(W_opt,'fro')+1e-8);

        W_opt = sqrt(P) * W_opt;

        %% =====================================================
        % INPUT FEATURE VECTOR
        %% =====================================================

        X_sample = [
            P;
            real(hdt(:));
            imag(hdt(:));
            real(hrt(:));
            imag(hrt(:));
            real(G(:));
            imag(G(:));
            real(Hu(:));
            imag(Hu(:));
            real(Hru(:));
            imag(Hru(:))
            ];

        %% =====================================================
        % OUTPUT LABEL VECTOR
        %% =====================================================

        W_fixed = zeros(M,K+M);

        [wm,wn] = size(W_opt);

        W_fixed( ...
            1:min(wm,M), ...
            1:min(wn,K+M)) = ...
            W_opt( ...
            1:min(wm,M), ...
            1:min(wn,K+M));

        phi_fixed = zeros(N,1);

        phi_fixed(1:min(length(phi_opt),N)) = ...
            phi_opt(1:min(length(phi_opt),N));

        Y_sample = [
            real(W_fixed(:));
            imag(W_fixed(:));
            real(phi_fixed(:));
            imag(phi_fixed(:));
            1
            ];

        %% =====================================================
        % STORE
        %% =====================================================

        X_data(p_idx,sim,:) = X_sample.';
        Y_data(p_idx,sim,:) = Y_sample.';

    end

    toc;

end

%% =====================================================
% REMOVE INVALID SAMPLES
%% =====================================================

fprintf('\nRemoving Invalid Samples...\n');

X_temp = reshape(X_data, [], input_dim);
Y_temp = reshape(Y_data, [], output_dim);

mask = Y_temp(:,end) == 1;

X_final = X_temp(mask,:);
Y_final = Y_temp(mask,:);

%% =====================================================
% NORMALIZATION
%% =====================================================

fprintf('Applying Normalization...\n');

X_mean = mean(X_final,1);
X_std  = std(X_final,0,1);

X_std(X_std < 1e-8) = 1;

X_norm = (X_final - X_mean) ./ X_std;

Y_main = Y_final(:,1:end-1);

Y_mean = mean(Y_main,1);
Y_std  = std(Y_main,0,1);

Y_std(Y_std < 1e-8) = 1;

Y_norm_main = (Y_main - Y_mean) ./ Y_std;

Y_norm = [Y_norm_main, Y_final(:,end)];

%% =====================================================
% VALID RATIO
%% =====================================================

valid_ratio = mean(Y_norm(:,end));

fprintf('\n====================================\n');
fprintf('FINAL VALID RATIO = %.2f %%\n', ...
    valid_ratio*100);
fprintf('TOTAL VALID SAMPLES = %d\n', ...
    sum(mask));
fprintf('====================================\n');

%% =====================================================
% DATASET QUALITY CHECK
%% =====================================================

fprintf('\nChecking Dataset Quality...\n');

input_std = mean(std(X_norm));
output_std = mean(std(Y_norm_main));

fprintf('Average Input STD  : %.6f\n', input_std);
fprintf('Average Output STD : %.6f\n', output_std);

%% =====================================================
% SAVE
%% =====================================================

save( ...
    'RIS_ISAC_DATASET_CLEAN_NORMALIZED_02.mat', ...
    'X_norm', ...
    'Y_norm', ...
    'X_mean', ...
    'X_std', ...
    'Y_mean', ...
    'Y_std', ...
    'feature_names', ...
    'label_names', ...
    '-v7.3');

fprintf('\n====================================\n');
fprintf('FINAL CLEAN DATASET SAVED\n');
fprintf('====================================\n');