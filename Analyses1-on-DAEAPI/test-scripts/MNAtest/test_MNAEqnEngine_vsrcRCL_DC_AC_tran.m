%author: J. Roychowdhury, 2012/05/01-08
% Test script for running DC, AC, transient on a Vsrc-RCL circuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The Circuit: 
%	- vsrc-R-C-L
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%
%see DAEAPIv6_doc.m for a description of the functions here.
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Type "help MAPPlicense" at the MATLAB/Octave prompt to see the license      %
%% for this software.                                                          %
%% Copyright (C) 2008-2013 Jaijeet Roychowdhury <jr@berkeley.edu>. All rights  %
%% reserved.                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






	MNAEqnEngine_vsrcRCL; % sets up DAE (a DAEAPI script)
	stateoutputs = StateOutputs(DAE); % all MNA unknowns

	% set DC input - now in circuitdata
	%DAE = feval(DAE.set_uQSS, 'v1:::E', 1, DAE);

	% run DC
	qss = QSS(DAE);
	qss = feval(qss.solve, qss);
	feval(qss.print, qss);

	%%%%% the AC (LTISSS) analysis

	% set up AC analysis input as a function of frequency
	Ufargs.string = 'no args used'; % 

	constonefuncH = @(f, args) 1;
	DAE = feval(DAE.set_uLTISSS, 'v1:::E', constonefuncH, [], DAE);

	% set up the AC analysis @ DC operating point
	us = feval(DAE.uQSS, DAE); % get the current DC inputs (values of all indep. sources)
	ltisss = LTISSS(DAE, feval(qss.getsolution,qss), us);
	% set AC sweep parameters: 1Hz to 100kHz, decade plot with 30 freq. points/decade
	sweeptype = 'DEC'; fstart=1; fstop=1e5; nsteps=30;

	% run the AC analysis
	ltisss = feval(ltisss.solve, fstart, fstop, nsteps, sweeptype, ltisss);

	% plot frequency sweeps of state variable outputs (overlay on 1 plot)
	feval(ltisss.plot, ltisss, stateoutputs);
	drawnow;

	fprintf(2,'\n');

	% set sinusoidal transient input - now in circuitdata
	%{
	utargs.A = 1; utargs.f=1e3; utargs.phi=0;
	utfunc = @(t, args) args.A*sin(2*pi*args.f*t + args.phi);
	DAE = feval(DAE.set_utransient, 'v1:::E', utfunc, utargs, DAE);
	%}

	% run transient

	% set up LMS object
	TransObjBE = LMS(DAE); % default method is BE, 
	TRmethod = TransObjBE.TRmethod; % contains order, alphas, betas of LMS method
	LMStranparms = TransObjBE.tranparms; % has, eg, tranparms.NRparms
	TRmethods = LMSmethods(); % defines FE, BE, TRAP, GEAR2 and 
	TransObjTRAP = LMS(DAE, TRmethods.TRAP, LMStranparms);

	% run transient and plot
	xinit = zeros(feval(DAE.nunks,DAE),1);
	tstart = 0;
	tstep = 10e-6;
	tstop = 5e-3;
	TransObjTRAP = feval(TransObjTRAP.solve, TransObjTRAP, ...
	      xinit, tstart, tstep, tstop);
	[thefig, legends] = feval(TransObjTRAP.plot, TransObjTRAP);

	% set step transient input
	utargs.A = 1; utargs.delay = 0.5e-3;
	utfunc = @(t, args) args.A*(t>=args.delay);
	DAE = feval(DAE.set_utransient, 'v1:::E', utfunc, utargs, DAE);

	% set up LMS object
	TransObjTRAP = LMS(DAE, TRmethods.TRAP, LMStranparms);

	% run transient and plot
	TransObjTRAP = feval(TransObjTRAP.solve, TransObjTRAP, ...
	      xinit, tstart, tstep, tstop);
	[thefig, legends] = feval(TransObjTRAP.plot, TransObjTRAP);
