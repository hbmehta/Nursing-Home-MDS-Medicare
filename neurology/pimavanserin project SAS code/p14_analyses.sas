/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:43:11 PM
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

/*   START OF NODE: p14_analyses   */
%LET _CLIENTTASKLABEL='p14_analyses';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Analyses - 14
|	
|
|
|*********************************************************************/

data pima.covariate_v12;
	set pima.covariate_v11;

	if 0<=ADL<=4 then ADL_cat = "ADL: 0-4		";
	else if 5<=ADL<=8 then ADL_cat = "ADL: 5-8		";
	else if 9<=ADL<=12 then ADL_cat = "ADL: 9-12		";
	else if 13<=ADL<=16 then ADL_cat = "ADL: 13-16		";	    
	else if ADL = . then ADL_cat = "Missing		";
	
	if e0100ab=0 then hallucination = "Yes					";
	else if e0100ab=1 then hallucination = "No					";
	else if e0100ab=. then hallucination = "Missing					";

	if abs_g = "" then abs_g = "Missing		";
	if CFS = "" then CFS = "Missing		";
	if mood = "" then mood = "Missing		";
				    
	if acute_mi = . then acute_mi = 0;
	if history_mi = . then history_mi = 0;
	if chf = . then chf = 0;
	if pvd = . then pvd = 0;
	if cvd = . then cvd = 0;
	if copd = . then copd = 0;
	if paralysis = . then paralysis = 0;
	if diabetes = . then diabetes = 0;
	if diabetes_comp = . then diabetes_comp = 0;
	if renal_disease = . then renal_disease = 0;
	if any_malignancy = . then any_malignancy = 0;
	if solid_tumor = . then solid_tumor = 0;
	if mild_liver_disease = . then mild_liver_disease = 0;
	if liver_disease = . then liver_disease = 0;
	if ulcers = . then ulcers = 0;
	if rheum_disease = . then rheum_disease = 0;
	if aids = . then aids = 0;
/*	if e0100ab = . then e0100ab = 0;*/
	if Sch = . then Sch = 0;
	if BD = . then BD = 0;
	if Fall = . then Fall = 0;
	if Pneumonia = . then Pneumonia = 0;
	if UTI = . then UTI = 0;
	
	label Sch = "Schizophrenia"
	BD = "Bipolar disorder" 
	ci = "Cholinesterase inhibitor" 
	ad = "Antidepressant" 
	ap = "Antipsychotic (other than pimavanserin)" 
	ms = "Mood stabilizer (incl. lithium)"
	bdz = "Benzodiazepine"
	oa = "Opioid analgesic";

	CCI_score = 
	1*acute_mi
	+ 1*history_mi
	+ 1*chf
	+ 1*pvd
	+ 1*cvd
	+ 1*copd
	+ 2*paralysis
	+ 1*diabetes
	+ 2*diabetes_comp
	+ 2*renal_disease
	+ 2*any_malignancy
	+ 6*solid_tumor
	+ 1*mild_liver_disease
	+ 3*liver_disease
	+ 1*ulcers
	+ 1*rheum_disease
	+ 6*aids;

run;
proc freq data=pima.covariate_v12; tables CCI_score; run;

/* Create list of dummy variables */

/** Dummy varibles for multiple category variables *************************************************/ 
%let VarList = region race index_yr hallucination abs_g CFS mood ADL_cat; /* name of categorical variables */

data AddFakeY / view=AddFakeY;	set pima.covariate_v12;	_Y = 0;	run;

proc glmselect data=AddFakeY NOPRINT outdesign(addinputvars)=pima.covariate_v13(drop=_Y);
   class      &VarList;   /* list the categorical variables here */
   model _Y = &VarList /  noint selection=none;
run;

proc freq data=pima.covariate_v13;
	table status_2 ;
run;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/
%let covariate = sex_ident_cd age dualflag hallucination
				 region	race index_yr abs_g cfs mood
				 acute_mi history_mi chf pvd ADL_cat
				 cvd copd paralysis diabetes diabetes_comp
				 renal_disease any_malignancy solid_tumor mild_liver_disease
				 liver_disease ulcers rheum_disease aids
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa acb_score;

%let categorical = status_2 sex_ident_cd dualflag hallucination
				 region	race index_yr abs_g cfs mood ADL_cat
				 acute_mi history_mi chf pvd
				 cvd copd paralysis diabetes diabetes_comp
				 renal_disease any_malignancy solid_tumor mild_liver_disease
				 liver_disease ulcers rheum_disease aids
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa;
proc freq data=pima.covariate_v13;
	table (&covariate)*status_2 / missing norow nopercent ;
run;

/* Adjusted Hazard ratios */
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model surv_30*death30(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model surv_90*death90(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model surv_180*death180(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model surv_365*death365(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model hosp_surv_30*hosp_flag_30(0) = status_2 &covariate/ ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model hosp_surv_90*hosp_flag_90(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model hosp_surv_180*hosp_flag_180(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc phreg data=pima.covariate_v13;
	class &categorical/ param=ref ref=first;
	model hosp_surv_365*hosp_flag_365(0) = status_2 &covariate / ties=discrete eventcode=1 risklimits;
	strata rs;
run;
proc contents data=pima.covariate_v13;run;

/* IPTW adjusted ********************************************************/
%let covariate_iptw = sex_ident_cd age dualflag
				 'hallucination Missing	'n 'hallucination No					'n 'hallucination Yes					'n
				 'Region Midwes'n 'Region Others'n 'Region Northe'n 'Region South	'n 'Region West		'n
				 'Race Black	'n 'Race Other	'n 'Race White		'n 
				 'index_yr 2016'n 'index_yr 2017'n 'index_yr 2018'n 
				 'abs_g Missing'n 'abs_g moderat'n 'abs_g none			'n 'abs_g severe	'n
				 'cfs cognitively intact		'n 'cfs mildly imparied			'n
				 'cfs missing		'n 'cfs moderately imparied	'n 'cfs severely imparied			'n
				 'mood Mild Depression		'n 'mood Missing		'n 'mood Moder/Severe Depr'n
				 'mood No Depression				'n
				 'ADL_cat ADL: 0-4		'n 'ADL_cat ADL: 13-16'n  'ADL_cat Missing		'n 
				 'ADL_cat ADL: 5-8		'n 'ADL_cat ADL: 9-12	'n 
				 acute_mi history_mi chf pvd
				 cvd copd paralysis diabetes diabetes_comp
				 renal_disease any_malignancy solid_tumor mild_liver_disease
				 liver_disease ulcers rheum_disease aids
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa acb_score;

%let categorical_iptw = status_2 SEX_IDENT_CD dualflag
				 'hallucination Missing	'n 'hallucination No					'n 'hallucination Yes					'n
				 'Region Midwes'n 'Region Others'n 'Region Northe'n 'Region South	'n 'Region West		'n
				 'Race Black	'n 'Race Other	'n 'Race White		'n 
				 'index_yr 2016'n 'index_yr 2017'n 'index_yr 2018'n 
				 'abs_g Missing'n 'abs_g moderat'n 'abs_g none			'n 'abs_g severe	'n
				 'cfs cognitively intact		'n 'cfs mildly imparied			'n
				 'cfs missing		'n 'cfs moderately imparied	'n 'cfs severely imparied			'n
				 'mood Mild Depression		'n 'mood Missing		'n 'mood Moder/Severe Depr'n
				 'mood No Depression				'n
				 'ADL_cat ADL: 0-4		'n 'ADL_cat ADL: 13-16'n  'ADL_cat Missing		'n 
				 'ADL_cat ADL: 5-8		'n 'ADL_cat ADL: 9-12	'n 
				 acute_mi history_mi chf pvd
				 cvd copd paralysis diabetes diabetes_comp
				 renal_disease any_malignancy solid_tumor mild_liver_disease
				 liver_disease ulcers rheum_disease aids
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa;
/********************************************************************************
     Derive PS and get Std Diff before and after weighting
********************************************************************************/
				 
proc psmatch data=pima.covariate_v13 region=allobs;
		class &categorical_iptw;
		psmodel status_2(treated='1')= &covariate_iptw;
		assess lps var=(&covariate_iptw)
						/ varinfo nlargestwgt=6 plots=(barchart boxplot(display=(lps )) wgtcloud) weight=atewgt(stabilize=yes);
output out(obs=all)=pima.propensity_score atewgt(stabilize=yes)=_ATEWgt_;
run;
proc univariate data=pima.propensity_score; var _ps_; histogram; run; /*propensity score*/
proc univariate data=pima.propensity_score; var _ATEWgt_; run; /*stabilized weights*/
/*Trimming at 1st and 99th percentile*/
data pima.propensity_score_trimmed; 
	set pima.propensity_score; 
	if 0< _ATEWgt_ < 0.249554 then _ATEWgt_=0.249554; 
	else if _ATEWgt_ > 2.286700 then _ATEWgt_= 2.286700; 
	else if _ATEWgt_=. then delete; 
run;
proc phreg data=pima.propensity_score_trimmed;
	model surv_30*death30(0) = status_2 sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model surv_90*death90(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model surv_180*death180(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model surv_365*death365(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model hosp_surv_30*hosp_flag_30(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model hosp_surv_90*hosp_flag_90(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model hosp_surv_180*hosp_flag_180(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;
proc phreg data=pima.propensity_score_trimmed;
	model hosp_surv_365*hosp_flag_365(0) = status_2 Sch acb_score/ eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;

proc freq data=pima.covariate_v13;
	table (Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa)*status_2/missing norow nopercent;
run;
proc means data=pima.covariate_v13 mean stddev;
	class status_2;
	var age acb_score;
run;

/********************************************************************************
     Table 2 results - 1/11/2021
********************************************************************************/

proc sql;
/*select status_2, sum (surv_30) as tot_30_surv*/
/*select status_2, sum (surv_90) as tot_90_surv*/
/*select status_2, sum (surv_180) as tot_180_surv*/
select status_2, sum (surv_365) as tot_365_surv
from pima.propensity_score_trimmed
group by status_2;
quit;

proc sql;
/*select status_2, sum (hosp_surv_30) as tot_hosp_30_surv*/
select status_2, sum (hosp_surv_90) as tot_hosp_90_surv
from pima.propensity_score_trimmed
group by status_2;
quit;


/********************************************************************************
     IPTW analysis using continuous Charlson score - 1/11/2021
********************************************************************************/

/* IPTW adjusted using continuous CHarlson score********************************************************/
%let covariate_iptw_v01 = sex_ident_cd age dualflag
				 'hallucination Missing	'n 'hallucination No					'n 'hallucination Yes					'n
				 'Region Midwes'n 'Region Others'n 'Region Northe'n 'Region South	'n 'Region West		'n
				 'Race Black	'n 'Race Other	'n 'Race White		'n 
				 'index_yr 2016'n 'index_yr 2017'n 'index_yr 2018'n 
				 'abs_g Missing'n 'abs_g moderat'n 'abs_g none			'n 'abs_g severe	'n
				 'cfs cognitively intact		'n 'cfs mildly imparied			'n
				 'cfs missing		'n 'cfs moderately imparied	'n 'cfs severely imparied			'n
				 'mood Mild Depression		'n 'mood Missing		'n 'mood Moder/Severe Depr'n
				 'mood No Depression				'n
				 'ADL_cat ADL: 0-4		'n 'ADL_cat ADL: 13-16'n  'ADL_cat Missing		'n 
				 'ADL_cat ADL: 5-8		'n 'ADL_cat ADL: 9-12	'n 
				 cci_score
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa acb_score;

%let categorical_iptw_v01 = status_2 SEX_IDENT_CD dualflag
				 'hallucination Missing	'n 'hallucination No					'n 'hallucination Yes					'n
				 'Region Midwes'n 'Region Others'n 'Region Northe'n 'Region South	'n 'Region West		'n
				 'Race Black	'n 'Race Other	'n 'Race White		'n 
				 'index_yr 2016'n 'index_yr 2017'n 'index_yr 2018'n 
				 'abs_g Missing'n 'abs_g moderat'n 'abs_g none			'n 'abs_g severe	'n
				 'cfs cognitively intact		'n 'cfs mildly imparied			'n
				 'cfs missing		'n 'cfs moderately imparied	'n 'cfs severely imparied			'n
				 'mood Mild Depression		'n 'mood Missing		'n 'mood Moder/Severe Depr'n
				 'mood No Depression				'n
				 'ADL_cat ADL: 0-4		'n 'ADL_cat ADL: 13-16'n  'ADL_cat Missing		'n 
				 'ADL_cat ADL: 5-8		'n 'ADL_cat ADL: 9-12	'n 
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa;


/********************************************************************************
     Derive PS and get Std Diff before and after weighting - 1/11/2021 - 
	--	Data renamed as _v01			 	
********************************************************************************/
				 
proc psmatch data=pima.covariate_v13 region=allobs;
		class &categorical_iptw_v01;
		psmodel status_2(treated='1')= &covariate_iptw_v01;
		assess lps var=(&covariate_iptw_v01)
						/ varinfo nlargestwgt=6 plots=(barchart boxplot(display=(lps )) wgtcloud) weight=atewgt(stabilize=yes);
output out(obs=all)=pima.propensity_score_v01 atewgt(stabilize=yes)=_ATEWgt_;
run;
proc univariate data=pima.propensity_score_v01; var _ps_; histogram; run; /*propensity score*/
proc univariate data=pima.propensity_score_v01; var _ATEWgt_; run; /*stabilized weights*/
/*Trimming at 1st and 99th percentile*/
data pima.propensity_score_trimmed_v01; 
	set pima.propensity_score_v01; 
	if 0< _ATEWgt_ < 0.250568 then _ATEWgt_=0.250568; 
	else if _ATEWgt_ > 2.277396 then _ATEWgt_= 2.277396; 
	else if _ATEWgt_=. then delete; 
run;
proc phreg data=pima.propensity_score_trimmed_v01;
/*	model surv_30*death30(0) = status_2 sch acb_score/ eventcode=1 risklimits;*/
/*	model surv_90*death90(0) = status_2 sch acb_score/ eventcode=1 risklimits;*/
/*	model surv_180*death180(0) = status_2 sch acb_score/ eventcode=1 risklimits;*/
/*	model surv_365*death365(0) = status_2 sch acb_score/ eventcode=1 risklimits;*/
/*	model hosp_surv_30*hosp_flag_30(0) = status_2 Sch acb_score/ eventcode=1 risklimits;*/
/*	model hosp_surv_90*hosp_flag_90(0) = status_2 Sch acb_score/ eventcode=1 risklimits;*/
	weight _ATEWgt_ / normalize;
run;


%let covariate_v01 = sex_ident_cd age dualflag hallucination
				 region	race index_yr abs_g cfs mood
				 cci_score
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa acb_score;

%let categorical_v01 = status_2 sex_ident_cd dualflag hallucination
				 region	race index_yr abs_g cfs mood ADL_cat
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa;

**Multivariable adjusted HR;
proc phreg data=pima.covariate_v13;
	class &categorical_V01/ param=ref ref=first;
		model surv_30*death30(0) = status_2 &covariate_v01 / ties=discrete eventcode=1 risklimits;
/*		model surv_90*death90(0) = status_2 &covariate_v01 / ties=discrete eventcode=1 risklimits;*/
/*		model surv_180*death180(0) = status_2 &covariate_v01 / ties=discrete eventcode=1 risklimits;*/
/*		model surv_365*death365(0) = status_2 &covariate_v01 / ties=discrete eventcode=1 risklimits;*/
/*		model hosp_surv_30*hosp_flag_30(0) = status_2 &covariate_v01 / ties=discrete eventcode=1 risklimits;*/
/*		model hosp_surv_90*hosp_flag_90(0) = status_2 &covariate_v01 / ties=discrete eventcode=1 risklimits;*/
	strata rs;
run;

**Unadjusted HR;
proc phreg data=pima.covariate_v13;		model surv_30*death30(0)   = status_2  / ties=discrete eventcode=1 risklimits; strata rs; run;
proc phreg data=pima.covariate_v13;		model surv_90*death90(0)   = status_2  / ties=discrete eventcode=1 risklimits; strata rs; run;
proc phreg data=pima.covariate_v13;		model surv_180*death180(0) = status_2 / ties=discrete eventcode=1 risklimits; strata rs; run;
proc phreg data=pima.covariate_v13;		model surv_365*death365(0) = status_2 / ties=discrete eventcode=1 risklimits; strata rs; run;
proc phreg data=pima.covariate_v13;		model hosp_surv_30*hosp_flag_30(0) = status_2 / ties=discrete eventcode=1 risklimits; strata rs; run;
proc phreg data=pima.covariate_v13;		model hosp_surv_90*hosp_flag_90(0) = status_2 / ties=discrete eventcode=1 risklimits; strata rs; run;

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
