clc
clear
close all
%%load head model from MCX
load('fullhead_atlas.mat');
%% prepare cfg for MCX simulation
clear cfg
%%secify number of photons 
cfg.nphoton=5e6;
%%specify excitation wavelength
lambda_exc = 785;
% tissue labels:0-ambient air,1-scalp,2-skull,3-csf,4-gray matter,5-white matter,6-air cavities
cfg.vol=USC_atlas;
cfg.prop=[0,0,1,1;
    mua_lambda(lambda_exc,.75,.1,.1,.05,0,.1,.01) mus_lambda(lambda_exc,46.1,.421) 0.89 1.37;
    mua_lambda(lambda_exc,.9,.2,.1,.05,0.01,.1,.0) mus_lambda(lambda_exc,22.9,.716) 0.89 1.37;
    0,0,0.89,1.37;
    mua_lambda(lambda_exc,.9,.5,.1,0,0,.5,.05) mus_lambda(lambda_exc,24.2,1.611) 0.89 1.37;
    mua_lambda(lambda_exc,.92,.6,.1,0,0,.4,.05) mus_lambda(lambda_exc,22,1.4) 0.84 1.37;
    0,0,1,1];

% light source
cfg.srcpos=[size(cfg.vol,1)/2,size(cfg.vol,2)/2,size(cfg.vol,3)]; %inward-pointing source
cfg.srcdir=[0,0,-1]; 
cfg.srctype = 'pencil';

% time windows
cfg.tstart=0;
cfg.tend=5e-9;
cfg.tstep=5e-9;

%%detector position and size
cfg.detpos = [cfg.srcpos 100]; %%make detector a 100 mm diameter incident on launch position

% other simulation parameters
cfg.isspecular=0;
cfg.isreflect=1;
cfg.autopilot=1;
cfg.gpuid=1;

%% run MCX simulation for excitation
[flux_exc]=mcxlab(cfg);

%% show representative image of excitation flux
close all
imagesc(rot90(squeeze(log10(flux_exc.data(:,100,:)))))

%% begin setup for emmission launches
cfg.srctype='weighed';
cfg.srcpos=[1 1 1];
cfg.srcparam1=[size(cfg.vol,1) size(cfg.vol,2) size(cfg.vol,3)];

%%calculate how much of the fluence is in each label
Scalp = cfg.vol == 1;
Skull = cfg.vol == 2;
Csf = cfg.vol == 3;
Gray = cfg.vol == 4;
White = cfg.vol == 5;
Air = cfg.vol == 6;
%%also get total flux through the system in terms of labels 
Total = sum(flux_exc.data(:));

nphotonsScalp = Scalp.*flux_exc.data;
nphotonsScalp = round(double(cfg.nphoton*sum(nphotonsScalp(:))/Total));

nphotonsSkull = Skull.*flux_exc.data;
nphotonsSkull = round(double(cfg.nphoton*sum(nphotonsSkull(:))/Total));

nphotonsCsf = Csf.*flux_exc.data;
nphotonsCsf = round(double(cfg.nphoton*sum(nphotonsCsf(:))/Total));

nphotonsGray = Gray.*flux_exc.data;
nphotonsGray = round(double(cfg.nphoton*sum(nphotonsGray(:))/Total));

nphotonsWhite = White.*flux_exc.data;
nphotonsWhite = round(double(cfg.nphoton*sum(nphotonsWhite(:))/Total));

nphotonsAir = Air.*flux_exc.data;
nphotonsAir = round(double(cfg.nphoton*sum(nphotonsAir(:))/Total));

%%time-gate for emission launches 
cfg.tstart=0;
cfg.tend=1e-10; 
cfg.tstep=1e-10;

%%set srcpattern to results from flux_exc
cfg.srcpattern = double(flux_exc.data);

%%get raman shift/emmison wavelength 
RamanShift = linspace(800,2000,200);
em_wave = (-(RamanShift/1e7 - 1/785)).^-1;

%%Raman peaks are assumed to be the same width, different intensities,
%%replace this with experimental data
peak = gausswin(4);
% tissue labels:0-ambient air,1-scalp,2-skull,3-csf,4-gray matter,5-white matter,6-air cavities
RamanSpectraBrainComponents = [zeros(size(em_wave,2),6) ];
%%scalp has peaks at 1080 and 1448
RamanSpectraBrainComponents(46:49,1) = peak;
RamanSpectraBrainComponents(107:110,1) = 2*peak;
%%skull is bone, has peaks at 958 and 1070
RamanSpectraBrainComponents(25:28,2) = 4*peak;
RamanSpectraBrainComponents(44:47,2) = 1.5*peak;
%%csf has peaks at 1557 and 1709
RamanSpectraBrainComponents(149:152,3) = 1.2*peak;
RamanSpectraBrainComponents(125:128,3) = 1.7*peak;
%%gray matter has peaks at 1002, 1064, 1439, 1659
RamanSpectraBrainComponents(141:144,4) = 3.5*peak;
RamanSpectraBrainComponents(105:108,4) = 4.5*peak;
RamanSpectraBrainComponents(43:46,4) = 2*peak;
RamanSpectraBrainComponents(34:37,4) = .2*peak;
%%white matter has same peaks different intensities
RamanSpectraBrainComponents(141:144,5) = 3.3*peak;
RamanSpectraBrainComponents(105:108,5) = 4.8*peak;
RamanSpectraBrainComponents(43:46,5) = 2.5*peak;
RamanSpectraBrainComponents(34:37,5) = .8*peak;
%%air pockets has peaks at ~1600 because of O2
RamanSpectraBrainComponents(134:137,6) = .1*peak;
%%add some noise to these measurements 
RamanSpectraBrainComponents = RamanSpectraBrainComponents.*rand(size(RamanSpectraBrainComponents));

%%we have the Raman spectra for the varied components of the brain
figure
plot(RamanShift,RamanSpectraBrainComponents)
xlabel('Raman Shift (cm^{-1})')
ylabel('Peak intensities')
legend('Scalp','Skull','CSF','Gray','White','Air Cavities')

parfor_progress(length(RamanShift));
for ind = 1:length(em_wave)
    cfglocal = cfg;
    
    lambda_em = em_wave(ind);
    % tissue labels:0-ambient air,1-scalp,2-skull,3-csf,4-gray matter,5-white matter,6-air cavities
    cfglocal.prop=[0,0,1,1;
        mua_lambda(lambda_em,.75,.1,.1,.05,0,.1,.01) mus_lambda(lambda_exc,46.1,.421) 0.89 1.37;
        mua_lambda(lambda_em,.9,.2,.1,.05,0.01,.1,.0) mus_lambda(lambda_em,22.9,.716) 0.89 1.37;
        0.001,0.001,0.89,1.37;
        mua_lambda(lambda_em,.9,.5,.1,0,0,.5,.05) mus_lambda(lambda_em,24.2,1.611) 0.89 1.37;
        mua_lambda(lambda_em,.92,.6,.1,0,0,.4,.05) mus_lambda(lambda_em,22,1.4) 0.84 1.37;
        0,0,1,1];
    
    %%launch emmission bounded to launch in just the scalp, with
    %%appropriate number of photons as determined from the excitation
    %%matrix
    if(nphotonsScalp>0)
        cfglocal.nphoton = nphotonsScalp;
        cfglocal.srcpattern = cfg.srcpattern.*Scalp;
        [~,det]=mcxlab(cfglocal);
        %%calculate reflectance from the detected photons 
        weight = length(det.data)./cfg.nphoton;
        RScalp(ind) = sum(mean((weight*exp(-cfglocal.prop(2:end,1).*det.data(3:end,:))),2));
        %%multiply reflectance by raman feature for the scalp
        RamanScalp(ind) = interp1(RamanShift,RamanSpectraBrainComponents(:,1),RamanShift(ind))*RScalp(ind);
    end
    if(nphotonsSkull)
        cfglocal.nphoton = nphotonsSkull;
        cfglocal.srcpattern = cfg.srcpattern.*Skull;
        [~,det]=mcxlab(cfglocal);
        %%calculate reflectance from the detected photons 
        weight = length(det.data)./cfg.nphoton;
        RSkull(ind) = sum(mean((weight*exp(-cfglocal.prop(2:end,1).*det.data(3:end,:))),2));
        RamanSkull(ind) = interp1(RamanShift,RamanSpectraBrainComponents(:,2),RamanShift(ind))*RSkull(ind);
    end
    if(nphotonsCsf)
        cfglocal.nphoton = nphotonsCsf;
        cfglocal.srcpattern = cfg.srcpattern.*Csf;
        [~,det]=mcxlab(cfglocal);
        %%calculate reflectance from the detected photons 
        weight = length(det.data)./cfg.nphoton;
        RCsf(ind) = sum(mean((weight*exp(-cfglocal.prop(2:end,1).*det.data(3:end,:))),2));
        RamanCsf(ind) = interp1(RamanShift,RamanSpectraBrainComponents(:,3),RamanShift(ind))*RCsf(ind);
        end
    if(nphotonsGray)
        cfglocal.nphoton = nphotonsGray;
        cfglocal.srcpattern = cfg.srcpattern.*Gray;
        [~,det]=mcxlab(cfglocal);
        %%calculate reflectance from the detected photons 
        weight = length(det.data)./cfg.nphoton;
        Rgrey(ind) = sum(mean((weight*exp(-cfglocal.prop(2:end,1).*det.data(3:end,:))),2));
        RamanGrey(ind) = interp1(RamanShift,RamanSpectraBrainComponents(:,4),RamanShift(ind))*Rgrey(ind);
    end
    if(nphotonsWhite>0)
        cfglocal.nphoton = nphotonsWhite;
        cfglocal.srcpattern = cfg.srcpattern.*White;
        [~,det]=mcxlab(cfglocal);
        %%calculate reflectance from the detected photons 
        weight = length(det.data)./cfg.nphoton;
        Rwhite(ind) = sum(mean((weight*exp(-cfglocal.prop(2:end,1).*det.data(3:end,:))),2));
        RamanWhite(ind) = interp1(RamanShift,RamanSpectraBrainComponents(:,5),RamanShift(ind))*Rwhite(ind);
    end
    if(nphotonsAir>0)
        cfglocal.nphoton = nphotonsAir;
        cfglocal.srcpattern = cfg.srcpattern.*Air;
        [~,det_Air]=mcxlab(cfglocal);
        %%calculate reflectance from the detected photons 
        weight = length(det.data)./cfg.nphoton;
        Rair(ind) = sum(mean((weight*exp(-cfglocal.prop(2:end,1).*det.data(3:end,:))),2));
        RamanAir(ind) = interp1(RamanShift,RamanSpectraBrainComponents(:,6),RamanShift(ind))*Rair(ind);
    end
    parfor_progress;
end

figure
plot(RamanShift,RamanScalp)
hold on
plot(RamanShift,RamanSkull)
plot(RamanShift,RamanGrey)
plot(RamanShift,RamanGrey)
plot(RamanShift,RamanWhite)
plot(RamanShift,RamanAir)
xlabel('Raman Shift')
ylabel('Intensity (a.u.)')