clear all;
close all;

addpath('~/MATLAB/utilities/');

fs = 12;

file = 'quasar_data.txt';

fid = fopen(file);

table = textscan(fid,'%f %f %f %f','CommentStyle','#');

xs = table{1};
xerrs = table{2};
ys = table{3};
yerrs = table{4};

N = length(xs);


%%

n_mc = 2e5;
n_chains = 4;

%implicity encodes sigma, tau > 0 flat priors

logposterior = @(pp) logL_regress_gx1(ys,yerrs,xs,xerrs,pp) ; 

% parameters are
% 1: alpha
% 2: beta
% 3: sigma
% 4: mu
% 5: tau

mc = zeros(n_mc,5,n_chains);

% jumping scales
jumps = [3; 1; 0.3; 0.3; 0.5] / 20;

acc = 0;

for c=1:n_chains
    disp(['Running chain ' num2str(c) ' of ' num2str(n_chains)])
    theta = [3; 1.1; 0.5; -1; 0.75] + 30*jumps.*rand(5,1);
    
    logpost_curr = logposterior(theta);
    
    disp('Begin MCMC: ')
    disp(' ')
    tic
    
    for i=1:n_mc
        
        if(mod(i,n_mc/20)==0)
            disp(['mcmc step i = ' num2str(i,'%.0f') ' : acc = ' num2str(acc/i,'%.2f') ' : logpost = ' num2str(logpost_curr)]);
        end
        
        theta_prop = theta + jumps.* randn(5,1);
        
        logpost_prop = logposterior(theta_prop);
        
        logr = logpost_prop-logpost_curr;
        
        if log(rand) < logr
            theta = theta_prop;
            acc = acc+1;
            logpost_curr = logpost_prop;
        else
            % theta stays the same;
            % logpost_curr stays the same;
        end
        
        mc(i,:,c) = theta;
        
    end
    
    acc = acc/n_mc;
    runtime = toc;
    
    disp(' ')
    disp(['End MCMC: Accept rate = ' num2str(acc,'%.2f')])
    disp(['Runtime = ' num2str(runtime,'%.2f')])
    disp(' ')
end
% examine chains

%save('last_MCMC.mat')

%% load saved chain

%load('ex2_1_good_MCMC.mat');


%% compute G-R ratio

gr = mcmc_calcrhat(mc)

max_gr = max(gr)

%%
% trace plots of MCMC
figure(6)
plot(mc(1000:1600,2,1));
ylabel('\beta')

%%

% examine autocorrelation function to gauge thinning factor
figure(7)
autocorr(mc(:,2,1),500)
acf = autocorr(mc(:,2,1),500);
tau = 1+2*sum(acf)

%%
% thin by factor tau and remove 20% initial burn-in
thin = ceil(tau);
burn = n_mc/5;

mc = mc(burn:thin:end,:,:);

% concatenate chains
mc = mcmc_combine(mc,0);

%%

figure(8)
histogram(mc(:,2),'Normalization','pdf')
xlabel('\beta');
ylabel('Posterior pdf P(\beta | D)')

post_means = mean(mc)'
post_stds = std(mc)'
title(['post alpha = ' num2str(post_means(1),'%.3f') ' \pm ' num2str(post_stds(1),'%.3f') ' : ' ...
    'post beta = ' num2str(post_means(2),'%.3f') ' \pm ' num2str(post_stds(2),'%.3f')],'FontSize',fs)

set(gca,'FontSize',fs)
%% 1D KDE

%p1 = 2;

[fi,xi] = ksdensity(mc(:,2));
hold on
plot(xi,fi,'-k','LineWidth',3)
hold off
set(gca,'FontSize',fs)

%% 2D KDE

% 2D scatter plots of parameters vs other parameters
% 1 = alpha, 2 = beta, 3 = sigma, 4 = mu, 5 = tau

p1 = 2; %beta
p2 = 1; %alpha

figure(9)
plot(mc(:,p1), mc(:,p2),'.');

title('2D Marginal Posterior')
xlabel('\beta')
ylabel('\alpha')
set(gca,'FontSize',fs)
hold off
