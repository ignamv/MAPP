%In general, a circuit can be represented by a differential algebraic equation
%(DAE). In MAPP, circuit DAEs are represented by a MATLAB
%structure with various fields (data members and function handles) which are
%specified using an API called DAEAPI. The DAEAPI gives you a structured way to
%specify the underlying circuit DAE which then can be used to do various
%numerical analysis on the circuit such as DC analysis, AC analysis and
%transient analysis. There are two ways to create such a DAE
%structure.
%       - use the function MNAEqnEngine() 
%           - it is more convenient to use but always creates the DAEs in MNA
%             equation format. To learn how to use MNAEqnEngine to build a
%             circuit DAE, type 'help MNAEqnEngineExample-ShichmanHodgesNMOS'. 
%
%       - manually code the DAE based on the DAEAPI definition
%           - but there is no restriction on the type of equation system. It
%             could be NA, MNA, ST or any convenient form the modeler wants. To
%             learn how to write circuit DAEs manually, type
%             'DAEAPIExample-ShichmanHodgesNMOS'.
%
%The following documents various fields exposed by DAEAPI and how to use to
%build a circuit DAE in MAPP. The DAE system with state x, inputs u(t) and
%outputs y(t), parameters p, and noise inputs n(t) is given by: 
%
% if the flag DAE.f_takes_inputs == 0:
%
% 	qdot(x, p) + f(x, p) + B*u(t) + m(x, n(t), p) = 0
%	y = C*x + D*u(t)
%
% if the flag DAE.f_takes_inputs == 1:
%
% 	qdot(x, p) + f(x, u(t), p) + m(x, n(t), p) = 0
%	y = C*x + D*u(t)
%
% [Note that B is not used if flag DAE.f_takes_inputs == 1].
% [Note also that B*u(t) is denoted by b(t) in various places below].
%
% B, C and D are matrices that multiply the inputs and state vector.  M(x)
% is a matrix function multiplying the noise input vector.
%
% The input u(t) needs to be specified differently for different analyses:
% 	- for QSS/DC: DAE.uQSS (set up by DAE.set_uQSS) is used.
%		- to specify an input in the DAE itself, set DAE.uQSSvec in DAE's
%		  constructor.
% 	- for transient: DAE.utransient (set up by DAE.set_utransient) is used.
%		- to specify an input in the DAE itself, set DAE.utfunc and DAE.utargs
%		  in DAE's constructor.
% 	- for SSS/AC: DAE.uLTISSS (set up by DAE.set_uLTISSS) is used.
%		- to specify an input in the DAE itself, set DAE.uffunc and DAE.ufargs
%		  in DAE's constructor.
% 	- for HB (one tone): DAE.uHB (set up by DAE.set_uHB) is used.
%		- to specify an input in the DAE itself, set DAE.uHBfunc and
%		  DAE.uHBargs in DAE's constructor.
%	- unless you incorporate the inputs as an additional argument to f() - ie,
%	  f_takes_inputs == 1 - you will also need to define B(DAE) correctly to
%	  couple the input to the DAE. 
%	- you need to define C(DAE) and D(DAE) to get the outputs correctly.
%
%%%%%%%%%%%%%%%%%%%%%% DAEAPIv6 FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%DAE.version (string). Use: versionstring = DAE.version;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%DAEAPI(uniqID, other arguments);
%	- the first argument uniqID should be a short unique ID string, containing
%	  no whitespace or special characters.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIZES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%DAE.nunks (function handle). Use: nunks = feval(DAE.nunks,DAE);
%	- returns the number of unknowns (size of the state vector x).
%DAE.neqns (function handle). Use: neqns = feval(DAE.neqns,DAE);
%	- returns the number of state equations (ie, size of q(x) and f(x)).
%DAE.ninputs (function handle). Use: ninps = feval(DAE.ninputs,DAE);
%	- returns the number of inputs (ie, size of u(t)).
%DAE.noutputs (function handle). Use: nouts = feval(DAE.noutputs,DAE);
%	- returns the number of outputs (ie, size of y(t)).
%DAE.nparms (function handle). Use: nparms = feval(DAE.nparms,DAE);
%	- returns the number of parameters (ie, size of DAE.parms).
%DAE.nNoiseSources (function handle). Use: m = feval(DAE.nNoiseSources,DAE);
%	- returns the number of noise inputs (ie, size of n(t)).
%
%%%%%%%%%%%% NAMES of DAE, UNKS, I/O, EQNS, PARMS, NOISE SOURCES %%%%%%%%%%%%%%
%
%DAE.uniqID (function handle). Use: name = feval(DAE.uniqID, DAE);
%	- returns the unique ID for the object, set up by the constructor's
%	  first argument.
%DAE.daename (function handle). Use: name = feval(DAE.daename, DAE);
%	- name is a string - just a name for the DAE.
%DAE.unknames (function handle). Use: unames = feval(DAE.unknames,DAE);
%	- unames is a cell array containing names of unknowns (strings)
%	- note: internally, the unknames are kept in a cell array DAE.unknameList
%DAE.renameUnks (function handle). 
%Use: DAE = feval(DAE.renameUnks, oldnames_cellarray, newnames_cellarray, DAE);
%	- renames unknowns specified by oldnames_cellarray (useful after composing DAEs)
%DAE.eqnnames (function handle). Use: eqnames = feval(DAE.eqnnames,DAE);
%	- eqnames is a cell array containing names of equations (strings) 
%	- note: internally, the eqnnames are kept in a cell array DAE.eqnnameList
%DAE.time_units (string). Use: DAE.time_units = 'hour'. Set by default to 'sec'.
%
%
%DAE.renameEqns (function handle). 
%Use: DAE = feval(DAE.renameEqns, oldnames_cellarray, newnames_cellarray, DAE);
%	- renames equations specified by oldnames_cellarray (useful after composing DAEs)
%DAE.inputnames (function handle). Use: inpnames = feval(DAE.inputnames,DAE);
%	- inpnames is a cell array containing names of the inputs (strings)
%DAE.outputnames (function handle). Use: opnames = feval(DAE.outputnames,DAE);
%	- opnames is a cell array containing names of the outputs (strings)
%DAE.parmnames (function handle). Use: pnames = feval(DAE.parmnames,DAE);
%	- pnames is a cell array containing DAE parameter names (strings)
%	- note: internally, the parmnames are kept in a cell array DAE.parmnameList
%DAE.renameParms (function handle). 
%Use: DAE = feval(DAE.renameParms, oldnames_cellarray, newnames_cellarray, DAE);
%	- renames parameters specified by oldnames_cellarray (useful after composing DAEs)
%DAE.NoiseSourceNames (function handle): 
%	- Use: nnames = feval(DAE.NoiseSourceNames, DAE);
%
%%%%%%%%%%%%%%%%%%%%% PARAMETER SUPPORT FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%
%
%DAE.parmdefaults (function handle). Use: parms = feval(DAE.parmdefaults,DAE);
%	parms is a cell array containing DAE parameter default values.
%
%DAE.getparms (function handle). Use:
%	parmvals = getparms(DAE)
%	  - returns current values of all defined parameters (stored in DAE.parms)
%	OR: parmval = getparms(parmname, DAE)
%	        ^                   ^         
%	      value               string
%	OR: parmvals = getparms(parmnames, DAE)
%	        ^                     ^ 
%	   cell array            cell array
%
%DAE.setparms (function handle). Use:
%	outDAE = setparms(parms, DAE)
%	                   ^     
%	             cell array with values of all defined parameters.
%		sets current values of parameters (DAE.parms) to argument parms. 
%		parms should be a cell array containing values of all DAE parameters.
%		OR as outDAE = setparms(parmname, newval, DAE)
%	                           ^         ^
%	                         string    value
%		sets current value of the named parameter parmname to newval. 
%	OR as outDAE = setparms(parmnames, newvals, DAE)
%	                           ^         ^
%	                           cell arrays
%		sets current values of the named parameters in parmnames to newvals. 
%	DAE.setparms(...) can be used to update parameters during runtime. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CORE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%Note on arguments for f(), q(), b*(), and other functions below:
%	x is a column vector of size nunks. E.g., x = rand(nunks,1);
%	u is a column vector of size ninputs.
%	t is scalar (time); freq is scalar (frequency).
%
%if DAE.f_takes_inputs == 0, then:
%	DAE.f (function handle). Use: outf = feval(DAE.f, x, DAE);
%		outf is a column vector of size neqns. Evaluates f(x).
%		x _must_ be a _column_ vector.
%else if DAE.f_takes_inputs == 1, then:
%	DAE.f (function handle). Use: outf = feval(DAE.f, x, u, DAE);
%		outf is a column vector of size neqns. Evaluates f(x,u).
%		u represents values of the inputs. x and u _must_ be _column_ vectors.
%
%DAE.q (function handle). Use: outq = feval(DAE.q, x, DAE);
%		outq is a column vector of size neqns. evaluates q(x).
%		x _must_ be a _column_ vector.
%
%%%%%%%%%%%%%%%%%%%%%% FIRST DERIVATIVES wrt x %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%if DAE.f_takes_inputs == 0, then:
%	DAE.df_dx (function handle). Use: Jf = feval(DAE.df_dx, x, DAE);
%		Jf is a sparse matrix with neqns rows and nunks cols.
%else if DAE.f_takes_inputs == 1, then:
%	DAE.df_dx (function handle). Use: Jf = feval(DAE.df_dx, x, u, DAE);
%		Jf is a sparse matrix with neqns rows and nunks cols.
%
%DAE.dq_dx (function handle). Use: Jq = feval(DAE.dq_dx, x, DAE);
%		Jq is a sparse matrix with neqns rows and nunks cols.
%
%DAE.df_du (function handle):
%	Derivative of f(x,u) with respect to u. Needed for linearization.
%	This should be defined only if DAE.f_takes_inputs == 1.
%	Use: dfdu = feval(DAE.df_du, x, u, DAE);
%
%%%%%%%%%%%%%%%%%%%% INPUT- and OUTPUT-related functions %%%%%%%%%%%%%%%%%%%%%
%
%DAE.uQSS (function handle). Use: outu = feval(DAE.uQSS, DAE);
%	outu is a real column vector of size ninputs. this function 
%	can be used for quiescent steady state (DC) analysis without
%	having to rely on utransient(t=0). 
%
%	- internally, this returns the stored vector DAE.uQSSvec.
%	  uQSSvec be set in the DAE's constructor; this is typically
%	  how a DC input will be hardcoded into the DAE's definition.
%	  It can also be updated later using DAE.set_uQSS (see below).
%	
%
%DAE.set_uQSS (function handle). Use: DAE = feval(DAE.set_uQSS, qssinputvec, DAE);
%	updates DAE.uQSSvec. See DAE.uQSS. 
%
%DAE.utransient (function handle). Use: outu = feval(DAE.utransient, t, DAE);
%	outu is a column vector of size ninputs; this can be used for
%	transient analysis. 
%	- internally, this calls the stored function handle 
%	  utfunc, with arguments (t, utargs). utargs is a structure
%	  that is also stored internally; it can contain any
%	  parameters or data needed by utfunc. utfunc and utargs
%         can both be set in the constructor of the DAE; this is typically
%	  how an input will be hardcoded into the DAE's definition. 
%	  utfunc and utargs can also be updated during runtime using 
%	  DAE.set_utransient (see below).
%	- note: utfunc(t, utargs) should be vectorized wrt the argument t.
%
%DAE.set_utransient (function handle). 
%Use: DAE = feval(DAE.set_utransient, utfunc, utargs, DAE);
%	updates utfunc and utargs. See DAE.utransient. 
%
%DAE.uLTISSS (function handle). Use: outu = feval(DAE.uLTISSS, f, DAE);
%	outu is a complex column vector of size ninputs - it represents
%	the complex amplitude of a sinusoidal input at frequency f. This fucntion 
%	can be used for LTI SSS (sinusoidal steady state, or AC) analysis.
%	- internally, this calls the stored function handle 
%	  Uffunc, with arguments (f, Ufargs). ufargs is a structure
%	  that is also stored internally; it can contain any
%	  parameters or data needed by Uffunc. Uffunc and Ufargs
%	  can both be set in the constructor of the DAE; this is typically
%	  how an AC input will be hardcoded into the DAE's definition. 
%	  Uffunc and Ufargs can also be updated during runtime using 
%	  DAE.set_uLTISSS (see below).
%
%	- note: Uffunc(f, Ufargs) should be vectorized wrt the argument f.
%
%DAE.set_uLTISSS (function handle). 
%Use: DAE = feval(DAE.set_uLTISSS, Uffunc, Ufargs, DAE);
%	updates Uffunc and Ufargs. See DAE.uLTISSS. 
%
%DAE.uHB (function handle). Use: outu = feval(DAE.uHB, f, DAE);
%	outu is a complex sparse matrix of size ninputs x N_HB - it represents
%	the complex amplitude of each harmonic at frequency f. This function 
%	is used for harmonic balance (HB) analysis.
%	- internally, this calls the stored function handle 
%	  uHBunc, with arguments (f, uHBargs). uHBargs is a structure
%	  that is also stored internally; it can contain any
%	  parameters or data needed by uHBfunc. uHBfunc and uHBargs
%	  can both be set in the constructor of the DAE; this is typically
%	  how a HB input will be hardcoded into a DAE's definition. 
%	  uHBfunc and uHBargs can also be updated during runtime using 
%	  DAE.set_uHB (see below).
%
%DAE.set_uHB (function handle). 
%Use: DAE = feval(DAE.set_uHB, uHBfunc, uHBargs, DAE);
%	updates uHBfunc and uHBargs. See DAE.uHB. 
%
%DAE.B (function handle). Use: bee = feval(DAE.B, DAE);
%	returns B. bee is a matrix of size neqns x ninputs.
%	Not used when DAE.f_takes_inputs == 1.
%
%DAE.C (function handle). Use: cee = feval(DAE.C, DAE);
%	returns C. cee is a matrix of size noutputs x nunks
%
%DAE.D (function handle). Use: dee = feval(DAE.D, DAE);
%	returns D. dee is a matrix of size noutputs x ninputs
%
%%%%%%%%%%%%%%%%%%%% NEWTON-RAPHSON ALGORITHM SUPPORT %%%%%%%%%%%%%%%%%%%%%%%%
%
%DAE.QSSinitGuess (function handle):
%	Use: xguess = feval(DAE.QSSinitGuess, u, DAE);
%	returns an initial guess for QSS (DC) NR, potentially based
%	on heuristics. u is a DC value of the inputs.
%
%DAE.NRlimiting (function handle):
%	Use: newdx = feval(DAE.NRlimiting, dx, xold, u, DAE);
%	limits an NR step dx, starting from xold, returning a
%	limited step newdx. u is a value of the inputs.
%
%%%%%%%%%%%%%%%%%%%%% NOISE SUPPORT FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%
%
%DAE.NoiseStationaryComponentPSDmatrix (function handle):
%	Use: Snn = feval(DAE.NoiseStationaryComponentPSDmatrix, f, DAE);
%	specifies the stationary, 1-sided PSD matrix function of n(t), as 
%	a function of frequency f.
%	NOTE: this function should return single-sided PSDs. Eg,
%	2*q*Id for shot noise; 4kT/R for thermal noise current.
%
%DAE.m (function handle):
%	Use: m = feval(DAE.m, x, n, DAE);
%	returns m(x, n).
%	Note: m(...) should be for 1-sided PSDs
%
%DAE.dm_dx (function handle):
%	Use: Jm = feval(DAE.dm_dx, x, n, DAE);
%	returns d/dx m(x, n).
%
%DAE.dm_dn (function handle):
%	Use: M = feval(DAE.dm_dn, x, n, DAE);
%	returns d/dn m(x, n)
%	Note: M should be for 1-sided PSDs
%
%%%%%%%%%%%%%%%%% INTERNAL HOOKS/FUNCTIONS EXPOSED BY DAE API %%%%%%%%%%%%%%%%
%
%DAE.internalfuncs (function handle). Returns a structure of named
%	function handles to internal functions exposed by
%	the DAE; may also contain other info, such as
%	usage strings. Use:
%	ifs = feval(DAE.internalfuncs, DAE)
%	stoichmat = feval(ifs.stoichmatfunc,DAE)
%	n = feval(DAE.nunks, DAE);
%	parms = feval(DAE.parmdefaults, DAE);
%	x = rand(n,1);
%	forwardrates = feval(ifs.forwardratefunc, x, parms, DAE);
%	dforwardrates = feval(ifs.dforwardratefunc, x, parms, DAE);
%
%%%%%%%%%%%%%%%%%%%% NOT PROPERLY IMPLEMENTED YET (placeholders) %%%%%%%%%%%%%
%
%In the following functions, argument PObj is a Parameters object, which
%	contains a list of (real-valued) parameters with respect to
%	which parameter sensitivity analysis is to be performed.
%
%DAE.df_dp (function handle): Use: Pf = feval(DAE.df_dp, x, PObj, DAE);
%	returns df(x,p)/dp, where p are the parameters in PObj.
%
%DAE.dq_dp (function handle): Use: Pq = feval(DAE.dq_dp, x, PObj, DAE);
%	returns dq(x,p)/dp, where p are the parameters in PObj.
%
%DAE.dm_dp (function handle):
%
%
% -----------------------------------------------------------------
% USEFUL UTILITY FUNCTIONS FOR DAEs (but not part of the API
% -----------------------------------------------------------------
% unkidx: finds the index in the x vector of an unknown, given its name
%	Example usage: i = unkidx('e1', DAE);
%	


%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Type "help MAPPlicense" at the MATLAB/Octave prompt to see the license      %
%% for this software.                                                          %
%% Copyright (C) 2008-2013 Jaijeet Roychowdhury <jr@berkeley.edu>. All rights  %
%% reserved.                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





