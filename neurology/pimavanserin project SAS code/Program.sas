/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:39:20 PM
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

/*   START OF NODE: Program   */
%LET _CLIENTTASKLABEL='Program';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Pimavanserin prelim numbers 
|
|
|
|*********************************************************************/

options compress = no;
libname pima "&mylibs/pima";
%let lib = in055546.;

Data pima.pima16;
set &lib.PDE16_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima17;
set &lib.PDE17_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima18;
set &lib.PDE18_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima;
set pima.pima16 (in = y16) pima.pima17 (in = y17) pima.pima18 (in = y18) ;
if y16 then year = 2016;
else if y17 then year = 2017;
else year = 2018; 
run;

proc freq data =  pima.pima;
tables year;
run;

proc sql;
select count (*) as claims, count (distinct bene_id) as pts, year
from pima.pima;
*group by year;
quit;

Data pima.mbsf_abcd_1618;
set &lib.mbsf_abcd16_r9984 &lib.mbsf_abcd17_r9984 &lib.mbsf_abcd18_r9984;
where bene_death_dt NE .;
keep bene_id bene_death_dt;
run;
proc sort data=pima.mbsf_abcd_1618; by bene_id bene_death_dt; run;
data pima.mbsf_abcd_1618; set pima.mbsf_abcd_1618; by bene_id; if first.bene_id; run;

proc sql;
select count (bene_id) as claims, count(distinct bene_id) 
from pima.mbsf_abcd_1618
where bene_death_dt NE .;
quit;


proc sql;
create table pima.pima_v2 as select * from
pima.pima as a left join pima.mbsf_abcd_1618 as b
on a.bene_id = b.bene_id;
quit;
proc sort data=pima.pima_v2; by bene_id srvc_dt; run;

data pima.pima_v3;
set pima.pima_v2;
by bene_id;
if first.bene_id;

if bene_death_dt = . then censor = 0; else censor = 1;

if bene_death_dt = . then bene_death_dt_v01 = "31Dec2018"D; else bene_death_dt_v01 = bene_death_dt;

survtime_mon = intck('month',srvc_dt,bene_death_dt_v01); 
survtime_days = (bene_death_dt_v01 - srvc_dt) ;

keep bene_id srvc_dt censor bene_death_dt bene_death_dt_v01 survtime_mon survtime_days;
format bene_death_dt_v01 mmddyy10.;
run;
ods graphics on;
proc lifetest data= pima.pima_v3 plots=survival( nocensor atrisk =0 to 1095 by 90) notable;
time survtime_days*censor(0);
run;

proc freq data=pima.pima_v3;
tables survtime_mon*censor;
run;

/**************************************************************************
	MEDPAR
**************************************************************************/

proc sql;
create table pima.medpar16 as 
select b.*
from pima.pima_v3 as a, &lib.MEDPAR16_R9984 as b
where a.bene_id = b.bene_id;
quit;

proc sql;
create table pima.medpar17 as 
select b.*
from pima.pima_v3 as a, &lib.MEDPAR17_R9984 as b
where a.bene_id = b.bene_id;
quit;

proc sql;
create table pima.medpar18 as 
select b.*
from pima.pima_v3 as a, &lib.MEDPAR18_R9984 as b
where a.bene_id = b.bene_id;
quit;

data pima.medpar16_18;
set pima.medpar: ;
run;
proc sort data=pima.medpar16_18; by bene_id; run;
/*NOTE: There were 10213 observations read from the data set PIMA.MEDPAR16.*/
/*NOTE: There were 12256 observations read from the data set PIMA.MEDPAR17.*/
/*NOTE: There were 11220 observations read from the data set PIMA.MEDPAR18.*/
/*NOTE: The data set PIMA.MEDPAR16_18 has 33689 observations and 398 variables.*/
proc datasets lib=pima nolist; delete medpar16 medpar17 medpar18; quit; run;

/**************************************************************************
	OUTPATIENT	
**************************************************************************/

proc sql;
create table pima.otpt16 as 
select b.*
from pima.pima_v3 as a, &lib.OTPTCLMSK16_R9984 as b
where a.bene_id = b.bene_id;
quit;

proc sql;
create table pima.otpt17 as 
select b.*
from pima.pima_v3 as a, &lib.OTPTCLMSK17_R9984 as b
where a.bene_id = b.bene_id;
quit;

proc sql;
create table pima.otpt18 as 
select b.*
from pima.pima_v3 as a, &lib.OTPTCLMSK18_R9984 as b
where a.bene_id = b.bene_id;
quit;

data pima.otpt16_18;
set pima.otpt: ;
run;
proc sort data=pima.otpt16_18; by bene_id; run;
/*NOTE: There were 59072 observations read from the data set PIMA.OTPT16.*/
/*NOTE: There were 60780 observations read from the data set PIMA.OTPT17.*/
/*NOTE: There were 51491 observations read from the data set PIMA.OTPT18.*/
/*NOTE: The data set PIMA.OTPT16_18 has 171343 observations and 160 variables.*/
proc datasets lib=pima nolist; delete otpt16 otpt17 otpt18; quit; run;

/**************************************************************************
	CARRIER	
**************************************************************************/

proc sql;
create table pima.car16 as 
select b.*
from pima.pima_v3 as a, &lib.BCARCLMSK16_R9984 as b
where a.bene_id = b.bene_id;
quit;

proc sql;
create table pima.car17 as 
select b.*
from pima.pima_v3 as a, &lib.BCARCLMSK17_R9984 as b
where a.bene_id = b.bene_id;
quit;

proc sql;
create table pima.car18 as 
select b.*
from pima.pima_v3 as a, &lib.BCARCLMSK18_R9984 as b
where a.bene_id = b.bene_id;
quit;

data pima.car16_18;
set pima.car: ;
run;
proc sort data=pima.car16_18; by bene_id; run;
/*NOTE: There were 365187 observations read from the data set PIMA.CAR16.*/
/*NOTE: There were 399264 observations read from the data set PIMA.CAR17.*/
/*NOTE: There were 362387 observations read from the data set PIMA.CAR18.*/
/*NOTE: The data set PIMA.CAR16_18 has 1126838 observations and 65 variables.*/
proc datasets lib=pima nolist; delete car16 car17 car18; quit; run;

/**************************************************************************
	
**************************************************************************/
data pima.medpar16_18_u (keep= bene_id _name_ icd10);
   set pima.medpar16_18;
   array v dgns_1_cd--dgns_25_cd;
   length _name_ $7.;
   do i = 1 to dim(v);
      _name_ = vname(v[i]);
      icd10 = v[i];
      output;
   end;
run;
data pima.medpar16_18_u (drop=_name_);
set pima.medpar16_18_u;
if icd10 = " " then delete;
run;
proc sort data=pima.medpar16_18_u nodupkey; by bene_id icd10; run;

data pima.otpt16_18_u (keep= bene_id _name_ icd10);
   set pima.otpt16_18;
   array v icd_dgns_cd1--icd_dgns_cd25;
   length _name_ $7.;
   do i = 1 to dim(v);
      _name_ = vname(v[i]);
      icd10 = v[i];
      output;
   end;
run;
data pima.otpt16_18_u (drop=_name_);
set pima.otpt16_18_u;
if icd10 = " " then delete;
run;
proc sort data=pima.otpt16_18_u nodupkey; by bene_id icd10; run;

data pima.car16_18_u (keep= bene_id _name_ icd10);
   set pima.car16_18;
   array v icd_dgns_cd1-icd_dgns_cd12;
   length _name_ $7.;
   do i = 1 to dim(v);
      _name_ = vname(v[i]);
      icd10 = v[i];
      output;
   end;
run;
data pima.car16_18_u (drop=_name_);
set pima.car16_18_u;
if icd10 = " " then delete;
run;
proc sort data=pima.car16_18_u nodupkey; by bene_id icd10; run;


Data pima.alldx;
set pima.medpar16_18_u pima.otpt16_18_u pima.car16_18_u;
run;
proc sort data=pima.alldx nodupkey; by bene_id icd10; run;	*971,102;

data pima.alldx1;
set pima.alldx;
icd10_v3 = substr (icd10,1,3);
if icd10_v3 in ("G20") then G20 = 1;
if icd10_v3 in ("F06") then F06 = 1;
if icd10_v3 in ("G23") then G23 = 1;
if icd10_v3 in ("G24") then G24 = 1;
if icd10_v3 in ("F03") then F03 = 1;
if icd10_v3 in ("G30") then G30 = 1;
if icd10_v3 in ("G21") then G21 = 1;
if icd10 in ("G3183") then G3183 = 1;
run;

proc sql;	*9473;
create table pima.alldx2 as 
select bene_id, max (g20) as g20a, max (f06) as f06a, max (g23) as g23a, max (g24) as g24a, max (g21) as g21a,
		max (f03) as f03a, max (g30) as g30a, max (g3183) as g3183a
from pima.alldx1
group by bene_id;
quit;


/*G20 (Parkinson disease) */
/*F06 (psychotic disorder due to physiological condition; */
/*specifically F06.0 or F06.2) */
/**/
/*G20 (Parkinson disease) */
/*G31.83 (Dementia with Lewy bodies / Parkinson disease dementia).*/
/*G23*/
/*G24 */
/**/
/*F03 / F03.9 Unspecified dementia (F03.90, F03.91)*/
/*G30 Alzheimer's disease (G30.0, G30.1, G30.8, G30.9)*/
/*G31.84 Mild cognitive impairment*/

/**************************************************************************
	Merge data and make final cohort for diagnosis
**************************************************************************/

proc sql; select count (bene_id) as all_pts, count (distinct bene_id) as unique_pts from pima.pima_v3; quit;
proc sql; select count (bene_id) as all_pts, count (distinct bene_id) as unique_pts from pima.alldx2; quit;

proc sql;
create table pima.pima_v4 as 
select *
from pima.pima_v3 as a, pima.alldx2 as b
where a.bene_id = b.bene_id;
quit;

proc freq data=pima.pima_v4;
/*tables g20a--g3183a / missing;*/
/*tables g20a*g3183a / missing;*/
/*tables g20a*f06a / missing;*/
tables g21a / missing;
run;


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
