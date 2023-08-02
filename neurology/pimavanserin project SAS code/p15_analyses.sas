/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:43:17 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HTMLBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HTMLBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: p15_analyses   */
%LET _CLIENTTASKLABEL='p15_analyses';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Analyses - 15
|	
|
|
|*********************************************************************/

/**************** Greedy matching ****************************************/
proc psmatch data=pima.covariate_v13 region=allobs;
	class &categorical_iptw;
	psmodel status_2(treated='1')= &covariate_iptw;
	match distance=lps method=greedy(k=1) caliper=0.3;
	assess lps var=(&covariate_iptw)
		/ stddev=pooled(allobs=no) stdbinvar=no plots(nodetails)=all weight=none;
	output out(obs=match)=pima.ps_match matchid=_matchID;
run;

proc univariate data=pima.ps_match;
	var _ps_;
run; /*propensity score*/

proc phreg data=pima.ps_match;
	model surv_30*death30(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

proc phreg data=pima.ps_match;
	model surv_90*death90(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

proc phreg data=pima.ps_match;
	model surv_180*death180(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

proc phreg data=pima.ps_match;
	model surv_365*death365(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

proc phreg data=pima.ps_match;
	model hosp_surv_30*hosp_flag_30(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

proc phreg data=pima.ps_match;
	model hosp_surv_90*hosp_flag_90(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

proc phreg data=pima.ps_match;
	model hosp_surv_180*hosp_flag_180(0) = status_2 / eventcode=1 ties=discrete risklimits;
	strata _matchid;
run;

/***************** KM curve for 1-yr death *******************/
ods graphics on;
proc lifetest data=pima.propensity_score plots=survival(failure nocensor test atrisk=0 to 400 by 60 outside)   notable;
	*Kaplan-Meier survival curve for all-cause death;
	time surv_365*death365(0);
	strata status_2 / order= internal;
run;
proc lifetest data=pima.propensity_score plots=survival(failure nocensor atrisk (atrisktick)= 0 60 120 180 240 300 365 outside) notable;
	*Kaplan-Meier survival curve for all-cause death;
	time surv_365*death365(0);
	strata status_2 / order= internal;
run;

proc lifetest data=pima.propensity_score 
						plots=survival(nocensor) notable;
	*Kaplan-Meier survival curve for all-cause death;
	time surv_365*death365(0);
	strata status_2;
run;

/**************** KM curve for discontinuation ***************/
data pima.discontinuation;
	set pima.propensity_score;
	if status_2 = 1;

	discontinuation_dt_v2 = min(discontinuation_dt, bene_death_dt, study_end_dt);
		if status=2 and pima_2=1 then
		discontinuation_dt_v2 = min(discontinuation_dt, bene_death_dt, study_end_dt, pima_dt);

	format discontinuation_dt_v2 mmddyy10.;

	/* create hospitalization flag variable */
	censor_flag = 0;
	if discontinuation_dt_v2 ne . and discontinuation_dt_v2=discontinuation_dt then censor_flag = 1;
	discon_flag = 0;
	if discontinuation_dt ne . then discon_flag=1;

	Index_dt_to_discon_dt_days = discontinuation_dt_v2-index_dt;
run;


proc lifetest data=pima.discontinuation plots=survival(nocensor);
	*Kaplan-Meier survival curve for discontinuation;
	time Index_dt_to_discon_dt_days*censor_flag(0);
run;


/***************** KM curve for 1-yr death *******************/

data pima.propensity_score_v1;
set pima.propensity_score ;
if status_2 = 1 then status_2_v1 = "Yes";
if status_2 = 0 then status_2_v1 = "No ";
label status_2_v1 = "Pimavanserin use";
run;

ods graphics on;

%ProvideSurvivalMacros
%macro StmtsTop;
referenceline y=0.2; referenceline y=0.4; referenceline y=0.6; referenceline y=0.8; 
%mend; 
%let GraphOpts = DataContrastColors=(red blue) DataColors=(red blue);
%let yOptions = label="Survival"  labelattrs=(size=10pt weight=bold) tickvalueattrs=(size=8pt) linearopts=(viewmin=0 viewmax=1 tickvaluelist=(0 .2 .4 .6 .8 1.0));
%let StepOpts = lineattrs=(thickness=2.5);
%let xOptions = label="Days" labelattrs=(size=10pt weight=bold) tickvalueattrs=(size=8pt) linearopts=(viewmax=365 tickvaluelist=(0 60 120 180 240 300 365) /*XTICKVALS*/ tickvaluefitpolicy=XTICKVALFITPOL);
%let InsetOpts = autoalign=(BottomRight) border=true BackgroundColor=GraphWalls:Color Opaque=true; 
%let LegendOpts = title=GROUPNAME location=inside across=1 autoalign=(TopRight);
%CompileSurvivalTemplates

**K-M plot;
proc lifetest data=pima.propensity_score_v1 plots=survival(nocensor atrisk (atrisktick maxlen=13 outside) = 0 60 120 180 240 300 365)  notable;
	time surv_365*death365(0);
	strata status_2_v1 ;
run;

**CIF plot -- FINAL;
proc lifetest data=pima.propensity_score_v1 plots=survival(all failure nocensor atrisk (atrisktick)= 0 60 120 180 240 300 365)  notable;
	time surv_365*death365(0);
	strata status_2_v1 ;
run;

proc lifetest data=pima.propensity_score_v1 plots=cif (test)  timelist=0 60 120 180 240 300 365 atrisk notable;
	time surv_365*death365(0) / eventcode=1;
	strata status_2_v1 ;
run;



/*%kmplot9 (*/
/*data = pima.propensity_score_v1,*/
/*time = surv_365,*/
/*censor = death365*/
/*)*/
/*WARNING: Unsupported device 'PSEPSF' for TAGSETS.SASREPORT13(EGSR) destination. Using default device 'PNG'.*/
/*ERROR: Insufficient authorization to use /sas/config_m5/compute/Lev2/sasCCW/pima.propensity_score_v1.surv_365.death365._MVAR_.PS.*/
/*ERROR: Unable to open graphics device I/O.*/
/*4                                                          The SAS System                              12:03 Friday, January 8, 2021*/
/**/
/*ERROR: Unable to initialize graphics device.*/
/*ERROR: Driver SASGDPSL will not load.*/


/*********************************************************************
	PS matching using continuous CCI score
*********************************************************************/

**Using Charlson as continuous;
proc psmatch data=pima.covariate_v13 region=allobs;
	class &categorical_iptw_v01;
	psmodel status_2(treated='1')= &covariate_iptw_v01;
	match distance=lps method=greedy(k=2) caliper=0.3;
	assess lps var=(&covariate_iptw_v01)
		/ stddev=pooled(allobs=no) stdbinvar=no plots(nodetails)=all weight=none;
	output out(obs=match)=pima.ps_match_v01 matchid=_matchID;
run;

proc univariate data=pima.ps_match_v01;
	var _ps_;
run; /*propensity score*/

proc phreg data=pima.ps_match_v01;	model surv_30*death30(0) = status_2 / eventcode=1 ties=discrete risklimits;	strata _matchid; run;
proc phreg data=pima.ps_match_v01;	model surv_90*death90(0) = status_2 / eventcode=1 ties=discrete risklimits;	strata _matchid; run;
proc phreg data=pima.ps_match_v01; 	model surv_180*death180(0) = status_2 / eventcode=1 ties=discrete risklimits;	strata _matchid; run;
proc phreg data=pima.ps_match_v01;	model surv_365*death365(0) = status_2 / eventcode=1 ties=discrete risklimits;	strata _matchid; run;
proc phreg data=pima.ps_match_v01; 	model hosp_surv_30*hosp_flag_30(0) = status_2 / eventcode=1 ties=discrete risklimits;	strata _matchid; run;
proc phreg data=pima.ps_match_v01; 	model hosp_surv_90*hosp_flag_90(0) = status_2 / eventcode=1 ties=discrete risklimits;	strata _matchid; run;


options nosource;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
